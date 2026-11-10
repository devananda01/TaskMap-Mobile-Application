import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_plan_model.dart';
import '../providers/nets_provider.dart';
import '../widgets/nets_fail_widget.dart';
import '../widgets/nets_success_widget.dart';

class NETSWidget extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const NETSWidget({super.key, required this.plan});

  @override
  ConsumerState<NETSWidget> createState() => _NETSWidgetState();
}

class _NETSWidgetState extends ConsumerState<NETSWidget> {
  @override
  void initState() {
    super.initState();

    // Calls generateQR when the widget is first built to display the QR code
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(netsProvider.notifier).generateQR(widget.plan);
    });
  }

  @override
  void dispose() {
    // Stop the countdown timer / webhook listener if the user navigates
    // away mid-payment instead of using the Cancel button.
    ref.read(netsProvider.notifier).cleanup();
    super.dispose();
  }

  // Format seconds into mm:ss
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(netsProvider);

    // "success" = payment confirmed, premium activation in progress.
    // "complete" = activation finished. Both should show the same
    // success screen — without this, the UI goes blank right at the
    // moment activation finishes.
    final isSuccess = state.status == "success" || state.status == "complete";

    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (state.status == "idle" && state.qrCode != null)
            Text(
              "Premium Subscription: \$${widget.plan.price.toStringAsFixed(2)}\nScan the QR code below with TWallet",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

          // Show QR code when available
          if (state.status == "idle" && state.qrCode != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Image.memory(
                state.qrCode!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),

          if (state.status == "idle" && state.qrCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Image.asset(
                'images/nets_qr_info.png',
                width: MediaQuery.of(context).size.width * 0.7,
              ),
            ),

          // Show status messages
          if (state.status == "loading") const CircularProgressIndicator(),

          // Show success message (covers both "success" and "complete")
          if (isSuccess) const NETSSuccessWidget(),

          // Show failure message
          if (state.status == "fail") const NETSFailWidget(),

          // Show time left when QR is active
          if (state.status == "idle" && state.qrCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "Time left: ${formatTime(state.timeLeft)}",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

          // Cancel button — only while still waiting for the QR to be
          // scanned. Once success/fail is showing, those widgets own
          // navigation themselves.
          if (state.status == "idle" && state.qrCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(netsProvider.notifier).cleanup();
                  Navigator.of(context).pushReplacementNamed("/");
                },
                child: const Text("Cancel Payment"),
              ),
            ),
        ],
      ),
    );
  }
}
