class SubscriptionPlan {
  final String id;
  final String label;
  final int months;
  final double price;
  final String? badge;

  const SubscriptionPlan({
    required this.id,
    required this.label,
    required this.months,
    required this.price,
    this.badge,
  });

  double get monthlyPrice => price / months;
}
const List<SubscriptionPlan> subscriptionPlans = [
  SubscriptionPlan(
    id: '1m',
    label: 'Monthly',
    months: 1,
    price: 4.99,
  ),

  SubscriptionPlan(
    id: '3m',
    label: 'Quarterly',
    months: 3,
    price: 11.99,
    badge: 'Best Value',
  ),

  SubscriptionPlan(
    id: '12m',
    label: 'Annual',
    months: 12,
    price: 39.99,
    badge: 'Save More',
  ),
];