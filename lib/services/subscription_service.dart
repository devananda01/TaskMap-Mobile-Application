import '../models/subscription_plan_model.dart';
import 'user_service.dart';

class SubscriptionService {
  final UserService _userService = UserService();

  /// Legacy in-app "fake payment" flow, kept for now in case anything else
  /// still calls it. New purchases go through the real NETS flow in
  /// NetsController, which calls [activatePremiumFor] directly once NETS
  /// confirms the payment.
  Future<bool> purchasePlan({required SubscriptionPlan plan}) async {
    final paymentSuccessful = await _processPayment(plan);

    if (!paymentSuccessful) {
      return false;
    }

    await activatePremiumFor(plan);

    return true;
  }

  /// Marks the user as premium for [plan]'s duration. Call this only after
  /// a payment has already been confirmed successful (e.g. by NETS).
  Future<void> activatePremiumFor(SubscriptionPlan plan) async {
    final expiry = DateTime.now().add(Duration(days: plan.months * 30));
    await _userService.upgradeToPro(expiry: expiry);
  }

  Future<bool> _processPayment(SubscriptionPlan plan) async {
    // Temporary implementation used only by the legacy purchasePlan() path.
    await Future.delayed(const Duration(seconds: 1));

    return true;
  }
}
