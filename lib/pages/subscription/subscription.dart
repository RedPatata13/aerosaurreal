import 'package:aerosaur_2nd_sem/routes/routes.dart';
import 'package:aerosaur_2nd_sem/services/repositories/premium_repository.dart';
import 'package:aerosaur_2nd_sem/state/user_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api/api_client.dart';
import '../../utils/snackbar_utils.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  static const _planPrice = 'PHP 149.99';
  static const _planSubtitle = 'Billed every 3 months';

  static const _features = [
    (
      icon: Icons.sensors_rounded,
      title: 'Real-Time Monitoring',
      description:
          'Track live air quality levels as they change in your environment.',
    ),
    (
      icon: Icons.blur_on_rounded,
      title: 'Detailed Particle Tracking',
      description: 'Monitor PM2.5, PM10, and VOC levels with precise readings.',
    ),
    (
      icon: Icons.show_chart_rounded,
      title: 'Air Quality Trends',
      description: 'View historical data and understand patterns over time.',
    ),
    (
      icon: Icons.query_stats_rounded,
      title: 'Usage Analytics',
      description: 'Analyze purifier performance and daily usage insights.',
    ),
  ];

  bool _loading = true;
  bool _startingCheckout = false;
  Map<String, dynamic>? _premiumStatus;
  String _selectedPaymentMethod = 'paymaya';

  PremiumRepository get _premiumRepo =>
      PremiumRepository(context.read<ApiClient>());

  bool get _isPremium => _premiumStatus?['isPremium'] == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPremiumStatus();
    });
  }

  Future<void> _loadPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    setState(() => _loading = true);

    try {
      if (!context.read<UserStore>().hasProfile) {
        await context.read<UserStore>().loadOrCreate();
      }

      final status = await _premiumRepo.getPremiumStatus(user.uid);
      if (!mounted) return;

      setState(() {
        _premiumStatus = status;
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.show(
        context,
        'Failed to load premium status: $e',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startCheckout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    setState(() => _startingCheckout = true);

    try {
      final checkoutUrl = await _createCheckoutUrl(user);

      final launched = await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        SnackbarUtils.show(
          context,
          'Unable to open the checkout page. Please try again.',
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.show(context, 'Failed to start checkout: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _startingCheckout = false);
      }
    }
  }

  Future<String> _createCheckoutUrl(User user) async {
    if (_selectedPaymentMethod == 'paypal') {
      final paypalPlanId = dotenv.env['PAYPAL_PLAN_ID']?.trim() ?? '';
      if (paypalPlanId.isEmpty) {
        throw Exception('PAYPAL_PLAN_ID is missing in .env');
      }

      final result = await _premiumRepo.createPaypalSubscription(
        userId: user.uid,
        planId: paypalPlanId,
      );

      final approvalUrl = (result['approvalUrl'] ?? '').toString();
      if (approvalUrl.isEmpty) {
        throw Exception('Approval URL was not returned by the backend.');
      }

      return approvalUrl;
    }

    final result = await _premiumRepo.createPaymayaCheckout(
      userId: user.uid,
      buyer: _buildBuyerPayload(user),
    );

    final checkoutUrl = (result['checkoutUrl'] ?? '').toString();
    if (checkoutUrl.isEmpty) {
      throw Exception('Checkout URL was not returned by the backend.');
    }

    return checkoutUrl;
  }

  Map<String, dynamic> _buildBuyerPayload(User user) {
    final displayName = user.displayName?.trim();
    final email = user.email?.trim();
    final username = context.read<UserStore>().username.trim();

    final fallbackName = displayName?.isNotEmpty == true
        ? displayName!
        : (username.isNotEmpty ? username : 'Aerosaur User');
    final nameParts = fallbackName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Aerosaur';
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : 'User';

    return {
      'firstName': firstName,
      'lastName': lastName,
      'contact': {'email': email ?? 'unknown@aerosaur.app'},
    };
  }

  void _openApp() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadPremiumStatus,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _openApp,
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        if (_isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Premium Active',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Image.asset(
                        'images/logo.png',
                        height: 70,
                        width: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isPremium ? 'Premium Enabled' : 'Get Premium',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isPremium
                          ? 'Your subscription is active. Continue to the app whenever you are ready.'
                          : 'Unlock Full Access',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._features.map(
                      (feature) => _FeatureTile(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Every 3 Months',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _planSubtitle,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 14,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _planPrice,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _PaymentOptionTile(
                            title: 'PayMaya',
                            icon: Icons.account_balance_wallet_outlined,
                            selected: _selectedPaymentMethod == 'paymaya',
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = 'paymaya';
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _PaymentOptionTile(
                            title: 'PayPal',
                            icon: Icons.payment_outlined,
                            selected: _selectedPaymentMethod == 'paypal',
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = 'paypal';
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _startingCheckout
                                  ? null
                                  : (_isPremium ? _openApp : _startCheckout),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _startingCheckout
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isPremium
                                              ? 'Continue'
                                              : _selectedPaymentMethod ==
                                                    'paypal'
                                              ? 'Subscribe with PayPal'
                                              : 'Subscribe with PayMaya',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: colorScheme.onPrimary,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right_rounded),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isPremium
                          ? _buildPremiumMeta()
                          : 'Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _buildPremiumMeta() {
    final plan = (_premiumStatus?['premiumPlan'] ?? 'PREMIUM_QUARTERLY')
        .toString();
    final expiresAt = (_premiumStatus?['expiresAt'] ?? '').toString();
    final provider = (_premiumStatus?['provider'] ?? '').toString();

    if (expiresAt.isEmpty) {
      return provider.isEmpty
          ? 'Current plan: $plan'
          : 'Current plan: $plan • Paid with ${provider.toUpperCase()}';
    }

    return provider.isEmpty
        ? 'Current plan: $plan • Expires on ${_formatDate(expiresAt)}'
        : 'Current plan: $plan • Paid with ${provider.toUpperCase()} • Expires on ${_formatDate(expiresAt)}';
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final month = _monthName(date.month);
      return '$month ${date.day}, ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : theme.dividerColor,
            width: selected ? 1.4 : 1,
          ),
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 22, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
