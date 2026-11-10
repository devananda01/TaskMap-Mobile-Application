import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskmap/models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../models/subscription_plan_model.dart';
import '../../providers/nets_provider.dart';
import '../../models/nets_state.dart';

import '../../theme/app_colors.dart';
import '../../widgets/white_card.dart';

const List<_Benefit> _benefits = [
  _Benefit(
    icon: Icons.auto_awesome,
    title: 'Unlimited AI Study Plans',
    subtitle: 'Generate as many personalized plans as you need, every day.',
  ),
  _Benefit(
    icon: Icons.insights_rounded,
    title: 'Advanced Analytics',
    subtitle: 'Deep dive into your study habits and productivity trends.',
  ),

  _Benefit(
    icon: Icons.calendar_month_rounded,
    title: 'Future Premium Features',
    subtitle: "Early access to new features before they're released.",
  ),
];

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class UpgradeScreen extends ConsumerStatefulWidget {
  static const String routeName = "/upgrade";

  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  // ── State ────────────────────────────────────────────────────────────────
  String selectedPlanId = '3m';

  SubscriptionPlan get _selectedPlan => subscriptionPlans.firstWhere(
    (p) => p.id == selectedPlanId,
  ); // ── Methods ──────────────────────────────────────────────────────────────
  void goBack() => Navigator.pop(context);

  void selectPlan(String id) => setState(() => selectedPlanId = id);

  Future<void> onContinueToNets() async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // avoid abandoning an in-flight NETS session
      enableDrag: false,
      builder: (_) => _NetsPaymentSheet(plan: _selectedPlan),
    );

    if (success != true || !mounted) return;

    AppSnackbar.success(context, 'Payment successful — welcome to Premium!');
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: goBack,
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'TaskMap',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Keeps the layout readable on tablets/large screens.
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: user.isPremium
                    ? _buildPremiumState(user)
                    : _buildPaymentFlow(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAYMENT FLOW (not yet premium)
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildPaymentFlow() {
    return Column(
      key: const ValueKey('payment'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(),
        const SizedBox(height: 24),
        _sectionLabel('WHY GO PREMIUM'),
        const SizedBox(height: 10),
        _buildBenefitsCard(),
        const SizedBox(height: 24),
        _sectionLabel('CHOOSE YOUR PLAN'),
        const SizedBox(height: 10),
        _buildPlanSelector(),
        const SizedBox(height: 24),
        _sectionLabel('PAYMENT SUMMARY'),
        const SizedBox(height: 10),
        _buildPaymentSummary(),
        const SizedBox(height: 24),
        _buildContinueButton(),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Secure payment powered by NETS',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ── (1) Hero ─────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.darkBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.card(context).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TaskMap Premium',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock unlimited AI study planning and premium productivity tools to help you stay organized and achieve more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── (2) Benefits checklist ──────────────────────────────────────────────
  Widget _buildBenefitsCard() {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _benefits.length; i++) ...[
            _benefitRow(_benefits[i]),
            if (i != _benefits.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _benefitRow(_Benefit b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFE9EEFC),
            shape: BoxShape.circle,
          ),
          child: Icon(b.icon, color: AppColors.primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                b.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.green,
          size: 18,
        ),
      ],
    );
  }

  // ── (3) Plan selector ────────────────────────────────────────────────────
  Widget _buildPlanSelector() {
    return Row(
      children: [
        for (int i = 0; i < subscriptionPlans.length; i++) ...[
          Expanded(child: _planCard(subscriptionPlans[i])),
          if (i != subscriptionPlans.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _planCard(SubscriptionPlan plan) {
    final isSelected = plan.id == selectedPlanId;

    return GestureDetector(
      onTap: () => selectPlan(plan.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF1FE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : const Color(0xFFE5E9F2),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (plan.badge != null)
              Positioned(
                top: -22,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.badge!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(height: 8),
                Text(
                  plan.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primaryBlue : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${plan.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${plan.monthlyPrice.toStringAsFixed(2)}/mo',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── (4) Payment summary ─────────────────────────────────────────────────
  Widget _buildPaymentSummary() {
    final plan = _selectedPlan;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TaskMap Premium — ${plan.label}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${plan.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE5E9F2), height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${plan.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E9F2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E9F2)),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment method',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        'NETS QR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── (5) Continue button ─────────────────────────────────────────────────
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onContinueToNets,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.6),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Pay with NETS',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PREMIUM MEMBER STATE (after payment succeeds)
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildPremiumState(UserModel user) {
    // Fallback only covers accounts that were made premium before
    // `premiumSince` existed — every new activation sets it.
    final activatedAt = user.premiumSince ?? user.createdAt;

    final expiresAt =
        user.premiumExpiry ?? activatedAt.add(const Duration(days: 30));

    final totalDays = expiresAt
        .difference(activatedAt)
        .inDays
        .clamp(1, 1 << 30);

    final elapsedDays = DateTime.now()
        .difference(activatedAt)
        .inDays
        .clamp(0, totalDays);

    final progress = elapsedDays / totalDays;

    return Column(
      key: const ValueKey('premium'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F6EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.green,
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "You're a Premium Member!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enjoy unlimited AI planning and all premium perks.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _sectionLabel('CURRENT SUBSCRIPTION'),
        const SizedBox(height: 10),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TaskMap Premium',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Activated',
                value: _formatDate(activatedAt),
              ),
              const SizedBox(height: 10),
              _infoRow(
                icon: Icons.event_available_rounded,
                label: 'Expires',
                value: _formatDate(expiresAt),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(totalDays - elapsedDays).clamp(0, totalDays)} days remaining',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('YOUR PREMIUM BENEFITS'),
        const SizedBox(height: 10),
        _buildBenefitsCard(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── NETS payment bottom sheet ───────────────────────────────────────────
// Shown when the user taps "Continue to NETS". Drives the real payment via
// netsProvider: generates a live QR on open, counts down, and reacts as
// soon as NetsController reports success (via webhook or the timer's
// fallback check) — no more manual "I've Completed Payment" button.
class _NetsPaymentSheet extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const _NetsPaymentSheet({required this.plan});

  @override
  ConsumerState<_NetsPaymentSheet> createState() => _NetsPaymentSheetState();
}

class _NetsPaymentSheetState extends ConsumerState<_NetsPaymentSheet> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(netsProvider.notifier).generateQR(widget.plan);
    });
  }

  @override
  void dispose() {
    ref.read(netsProvider.notifier).cleanup();
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Close the sheet the moment activation finishes, returning `true` so
    // the screen above can show its success snackbar.
    ref.listen(netsProvider, (previous, next) {
      if (next.status == "complete") {
        Navigator.pop(context, true);
      }
    });

    final netsState = ref.watch(netsProvider);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan to Pay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.plan.label} · \$${widget.plan.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildBody(netsState),
            const SizedBox(height: 20),
            _buildFooter(netsState),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NetsState netsState) {
    switch (netsState.status) {
      case "loading":
        return const SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryBlue),
                SizedBox(height: 12),
                Text(
                  'Generating your QR code…',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case "success":
        return const SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 56,
                ),
                SizedBox(height: 12),
                Text(
                  'Payment confirmed — activating Premium…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case "complete":
        // Sheet is closing via ref.listen above — show a brief success
        // frame in case there's any delay in the pop animation.
        return const SizedBox(
          height: 200,
          child: Center(
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.green,
              size: 56,
            ),
          ),
        );

      case "fail":
      case "expired":
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  netsState.message ??
                      (netsState.status == "expired"
                          ? 'QR code expired.'
                          : 'Payment was not completed.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case "idle":
      default:
        return Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E9F2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: netsState.qrCode != null
                  ? Image.memory(netsState.qrCode!, fit: BoxFit.contain)
                  : const Icon(
                      Icons.qr_code_2_rounded,
                      size: 110,
                      color: Colors.black87,
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              _formatCountdown(netsState.timeLeft),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              netsState.message ??
                  'Open your banking app and scan to\ncomplete the payment.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildFooter(NetsState netsState) {
    final isRetryable =
        netsState.status == "fail" || netsState.status == "expired";
    final isBusy =
        netsState.status == "loading" || netsState.status == "success";

    return Column(
      children: [
        if (isRetryable)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  ref.read(netsProvider.notifier).generateQR(widget.plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isBusy ? null : () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isBusy ? Colors.grey.shade300 : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
