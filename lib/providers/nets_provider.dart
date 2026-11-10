import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:taskmap/providers/user_provider.dart';

import '../models/nets_state.dart';
import '../models/subscription_plan_model.dart';
import '../services/nets_service.dart';
import '../services/subscription_service.dart';
import 'subscription_provider.dart';

final netsServiceProvider = Provider<NETSService>((ref) {
  return NETSService();
});

final netsProvider = StateNotifierProvider<NetsController, NetsState>((ref) {
  final service = ref.read(netsServiceProvider);
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return NetsController(ref, service, subscriptionService);
});

class NetsController extends StateNotifier<NetsState> {
  final Ref ref;
  final NETSService service;
  final SubscriptionService subscriptionService;

  Timer? _timer;
  StreamSubscription<String>? _webhookSub;

  // The plan currently being paid for. Needed by checkPayment() to know
  // what to activate once NETS confirms the payment — it's set here rather
  // than passed around, since it comes from the same generateQR() call
  // that kicks off the whole flow.
  SubscriptionPlan? _plan;

  NetsController(this.ref, this.service, this.subscriptionService)
    : super(NetsState());

  // 1. Generate QR for the selected plan
  Future<void> generateQR(SubscriptionPlan plan) async {
    _plan = plan;
    state = NetsState(status: "loading");

    final decoded = await service.requestQR(plan.price);

    if (!mounted) return;

    if (decoded.isEmpty ||
        decoded['qrCode'] == null ||
        decoded['txnRef'] == null) {
      state = state.copyWith(
        status: "fail",
        message: "Couldn't generate a QR code. Please try again.",
      );
      return;
    }

    final qr = base64Decode(decoded['qrCode']);
    final txnRef = decoded['txnRef'] as String;

    state = NetsState(
      qrCode: qr,
      status: "idle",
      timeLeft: 300,
      txnRef: txnRef,
    );

    _startTimer(txnRef);
    _listenForWebhook(txnRef);
  }

  // 2. Countdown timer — falls back to a final payment check on expiry
  void _startTimer(String txnRef) {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Once we've moved past "waiting to scan" (success/fail/expired),
      // there's nothing left to count down.
      if (state.status != "idle") {
        timer.cancel();
        return;
      }
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        timer.cancel();
        checkPayment(txnRef);
      }
    });
  }

  // 3. SSE listener — reacts as soon as the QR is scanned instead of
  // waiting for the countdown to run out
  void _listenForWebhook(String txnRef) {
    _webhookSub?.cancel();

    _webhookSub = service
        .webhookStream(txnRef)
        .listen(
          (data) {
            if (!mounted || state.status != "idle") return;

            if (data.contains("QR code scanned")) {
              state = state.copyWith(
                message: "QR code scanned — confirming payment...",
              );
              checkPayment(txnRef);
            }
          },
          onError: (_) {
            // Swallow — the countdown timer's expiry check is the fallback if
            // the SSE connection drops.
          },
        );
  }

  // 4. Final payment check — also used as the timer/webhook fallback
  Future<void> checkPayment(String txnRef) async {
    _timer?.cancel();
    _webhookSub?.cancel();

    final decoded = await service.checkPayment(txnRef);

    if (!mounted) return;

    final code = decoded['response_code'] ?? "99";
    final message = decoded['message'] as String?;

    if (code == '00') {
      final plan = _plan;
      if (plan == null) {
        state = state.copyWith(
          status: "fail",
          message: "Missing plan details.",
        );
        return;
      }

      state = state.copyWith(status: "success", message: message);

      await subscriptionService.activatePremiumFor(plan);
      await ref.read(userProvider.notifier).refreshUser();

      if (!mounted) return;
      state = state.copyWith(status: "complete");
    } else {
      state = state.copyWith(
        status: "fail",
        message: message ?? "Payment was not completed.",
      );
    }
  }

  void cleanup() {
    _timer?.cancel();
    _webhookSub?.cancel();
    _plan = null;
    //  state = NetsState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _webhookSub?.cancel();
    super.dispose();
  }
}
