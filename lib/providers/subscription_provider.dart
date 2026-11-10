import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription_plan_model.dart';
import '../services/subscription_service.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

class SubscriptionNotifier extends Notifier<bool> {
  late final SubscriptionService _subscriptionService;

  @override
  bool build() {
    _subscriptionService = ref.read(subscriptionServiceProvider);
    return false;
  }

  Future<bool> purchasePlan({required SubscriptionPlan plan}) async {
    state = true;

    final success = await _subscriptionService.purchasePlan(plan: plan);

    state = false;

    return success;
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, bool>(
  SubscriptionNotifier.new,
);
