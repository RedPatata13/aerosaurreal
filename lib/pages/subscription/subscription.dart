import 'package:aerosaur/routes/routes.dart';
import 'package:aerosaur/services/repositories/premium_repository.dart';
import 'package:aerosaur/state/user_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/app_dialogs.dart';
import '../../services/api/api_client.dart';
import '../../utils/snackbar_utils.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with WidgetsBindingObserver {
  static const _planPrice = '₱ 149.99';
  static const _planSubtitle = 'Billed every 3 months';
  static const _contentMaxWidth = 520.0;
  static const _premiumPollAttempts = 8;
  static const _premiumPollDelay = Duration(seconds: 2);

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
  bool _cancellingSubscription = false;
  bool _syncingCheckoutReturn = false;
  bool _awaitingCheckoutReturn = false;
  Map<String, dynamic>? _premiumStatus;
  String? _pendingCheckoutId;
  String? _pendingPaymentProvider;
  String _selectedPaymentMethod = 'paymaya';

  PremiumRepository get _premiumRepo =>
      PremiumRepository(context.read<ApiClient>());

  bool get _isPremium => _premiumStatus?['isPremium'] == true;
  String get _subscriptionStatus =>
      (_premiumStatus?['status'] ?? '').toString().toUpperCase();
  bool get _isCancelledButActive =>
      _isPremium && _subscriptionStatus == 'CANCELLED';
  bool get _canCancelSubscription =>
      _isPremium &&
      !_isCancelledButActive &&
      ((_premiumStatus?['provider']?.toString() == 'paypal') ||
          (_premiumStatus?['provider']?.toString() == 'paymaya'));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPremiumStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_awaitingCheckoutReturn ||
            (!_isPremium && _selectedPaymentMethod == 'paypal'))) {
      _handleCheckoutReturn();
    }
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
        'Unable to refresh premium status right now. Please try again in a moment.',
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
      final checkout = await _createCheckoutSession(user);
      final checkoutUrl = (checkout['url'] ?? '').toString();

      if (checkoutUrl.isEmpty) {
        throw Exception('Checkout URL was not returned by the backend.');
      }

      final launched = await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.externalApplication,
      );

      if (launched && mounted) {
        setState(() {
          _awaitingCheckoutReturn = true;
          _pendingPaymentProvider = checkout['provider']?.toString();
          _pendingCheckoutId = checkout['checkoutId']?.toString();
        });
      } else if (mounted) {
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

  Future<Map<String, dynamic>> _createCheckoutSession(User user) async {
    if (_selectedPaymentMethod == 'paypal') {
      final paypalPlanId = dotenv.env['PAYPAL_PLAN_ID']?.trim() ?? '';
      if (paypalPlanId.isEmpty) {
        throw Exception('PAYPAL_PLAN_ID is missing in .env');
      }

      final result = await _premiumRepo.createPaypalSubscription(
        userId: user.uid,
        planId: paypalPlanId,
      );

      return {
        'provider': 'paypal',
        'checkoutId': result['subscriptionId'],
        'url': result['approvalUrl'],
      };
    }

    final result = await _premiumRepo.createPaymayaCheckout(
      userId: user.uid,
      buyer: _buildBuyerPayload(user),
    );

    return {
      'provider': 'paymaya',
      'checkoutId': result['checkoutId'],
      'url': result['checkoutUrl'],
    };
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
    final normalizedEmail = (email?.isNotEmpty == true)
        ? email!
        : 'unknown@aerosaur.app';

    return {
      'firstName': firstName,
      'lastName': lastName,
      'contact': {'email': normalizedEmail},
    };
  }

  Future<void> _handleCheckoutReturn() async {
    if (_syncingCheckoutReturn) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wasPremium = _isPremium;

    setState(() {
      _syncingCheckoutReturn = true;
      _awaitingCheckoutReturn = false;
    });

    try {
      if (_pendingPaymentProvider == 'paymaya' &&
          _pendingCheckoutId != null &&
          _pendingCheckoutId!.isNotEmpty) {
        await Future<void>.delayed(_premiumPollDelay);
        await _premiumRepo.getPaymayaPaymentStatus(
          paymentId: _pendingCheckoutId!,
          userId: user.uid,
        );
      } else {
        await Future<void>.delayed(_premiumPollDelay);
      }

      final refreshed = await _pollPremiumStatus(user.uid);
      if (!mounted) return;

      setState(() {
        _premiumStatus = refreshed;
      });

      if (!wasPremium && refreshed['isPremium'] == true) {
        await _showSubscriptionSuccessDialog();
      }
    } catch (_) {
      if (!mounted) return;
      SnackbarUtils.show(
        context,
        'Payment was processed, but premium status is still updating. Pull to refresh in a moment.',
        Colors.orange,
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncingCheckoutReturn = false;
          _pendingCheckoutId = null;
          _pendingPaymentProvider = null;
        });
      }
    }
  }

  Future<void> _showSubscriptionSuccessDialog() async {
    return showAppMessageDialog(
      context,
      title: 'Subscription successful.\nPremium is now active.',
      message: 'Your account now has access to premium features.',
      actionLabel: 'Continue',
    );
  }

  Future<Map<String, dynamic>> _pollPremiumStatus(String userId) async {
    Map<String, dynamic>? latestStatus;

    for (var attempt = 0; attempt < _premiumPollAttempts; attempt++) {
      latestStatus = await _premiumRepo.getPremiumStatus(userId);
      if (latestStatus['isPremium'] == true) {
        return latestStatus;
      }

      if (attempt < _premiumPollAttempts - 1) {
        await Future<void>.delayed(_premiumPollDelay);
      }
    }

    return latestStatus ?? <String, dynamic>{'isPremium': false};
  }

  Future<void> _cancelSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _cancellingSubscription) return;

    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Cancel auto-renew for this\nsubscription?',
      message:
          'Your current payment is not refundable, and premium access will continue until the end of the paid period.',
      confirmColor: const Color(0xFFA31618),
    );

    if (!confirmed || !mounted) return;

    setState(() => _cancellingSubscription = true);

    try {
      final provider = (_premiumStatus?['provider'] ?? '').toString();
      if (provider == 'paymaya') {
        await _premiumRepo.cancelPaymayaPremium(user.uid);
      } else {
        await _premiumRepo.cancelSubscription(user.uid);
      }
      await _loadPremiumStatus();
      if (!mounted) return;

      SnackbarUtils.show(
        context,
        'Auto-renew cancelled. Premium access stays active until the current paid period ends.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.show(
        context,
        'Failed to cancel subscription: $e',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _cancellingSubscription = false);
      }
    }
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _contentMaxWidth,
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        _isCancelledButActive
                                            ? 'Auto-Renew Off'
                                            : 'Premium Active',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
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
                              _isCancelledButActive
                                  ? 'Premium Cancelled'
                                  : _isPremium
                                  ? 'Premium Enabled'
                                  : 'Get Premium',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isCancelledButActive
                                  ? 'Auto-renew is off. Your premium access stays active until the current paid period ends.'
                                  : _isPremium
                                  ? 'Your subscription is active. Continue to the app whenever you are ready.'
                                  : 'Unlock Full Access',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                height: 1.4,
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
                            _isPremium
                                ? _SubscriptionManagementCard(
                                    canCancel: _canCancelSubscription,
                                    cancelling: _cancellingSubscription,
                                    isCancelled: _isCancelledButActive,
                                    planName: _formatPlanName(
                                      (_premiumStatus?['premiumPlan'] ?? '')
                                          .toString(),
                                    ),
                                    provider:
                                        (_premiumStatus?['provider'] ?? '')
                                            .toString(),
                                    expiresAt:
                                        (_premiumStatus?['expiresAt'] ?? '')
                                            .toString(),
                                    onCancel: _cancelSubscription,
                                  )
                                : Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      20,
                                      18,
                                      20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: theme.dividerColor,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final useCompactLayout =
                                                constraints.maxWidth < 220;

                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Every 3 Months',
                                                        style: theme
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontSize: 19,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: colorScheme
                                                                  .onSurface,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _planSubtitle,
                                                        softWrap: true,
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface
                                                                  .withValues(
                                                                    alpha: 0.6,
                                                                  ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: useCompactLayout
                                                      ? 12
                                                      : 20,
                                                ),
                                                Flexible(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.topRight,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Text(
                                                        _planPrice,
                                                        maxLines: 1,
                                                        style: theme
                                                            .textTheme
                                                            .headlineSmall
                                                            ?.copyWith(
                                                              fontSize: 28,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              color: colorScheme
                                                                  .onSurface,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        _PaymentOptionTile(
                                          title: 'PayMaya',
                                          icon: Icons
                                              .account_balance_wallet_outlined,
                                          selected:
                                              _selectedPaymentMethod ==
                                              'paymaya',
                                          onTap: () {
                                            setState(() {
                                              _selectedPaymentMethod =
                                                  'paymaya';
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        _PaymentOptionTile(
                                          title: 'PayPal',
                                          icon: Icons.payment_outlined,
                                          selected:
                                              _selectedPaymentMethod ==
                                              'paypal',
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
                                                : _startCheckout,
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: _startingCheckout
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          _selectedPaymentMethod ==
                                                                  'paypal'
                                                              ? 'Subscribe with PayPal'
                                                              : 'Subscribe with PayMaya',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: theme
                                                              .textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: colorScheme
                                                                    .onPrimary,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons
                                                            .chevron_right_rounded,
                                                      ),
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
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _buildPremiumMeta() {
    final plan = _formatPlanName(
      (_premiumStatus?['premiumPlan'] ?? 'PREMIUM_QUARTERLY').toString(),
    );
    final expiresAt = (_premiumStatus?['expiresAt'] ?? '').toString();
    final provider = (_premiumStatus?['provider'] ?? '').toString();

    if (expiresAt.isEmpty) {
      return provider.isEmpty
          ? 'Current plan: $plan'
          : 'Current plan: $plan | Paid with ${provider.toUpperCase()}';
    }

    return provider.isEmpty
        ? 'Current plan: $plan | Expires on ${_formatDate(expiresAt)}'
        : 'Current plan: $plan | Paid with ${provider.toUpperCase()} | Expires on ${_formatDate(expiresAt)}';
  }

  String _formatPlanName(String planId) {
    if (planId.isEmpty) return 'Premium Plan';

    switch (planId) {
      case 'PREMIUM_QUARTERLY':
        return 'Premium Quarterly';
      default:
        if (planId.startsWith('P-')) {
          return 'Premium Plan';
        }

        return planId.replaceAll('_', ' ');
    }
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                softWrap: true,
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

class _SubscriptionManagementCard extends StatelessWidget {
  const _SubscriptionManagementCard({
    required this.canCancel,
    required this.cancelling,
    required this.isCancelled,
    required this.planName,
    required this.provider,
    required this.expiresAt,
    required this.onCancel,
  });

  final bool canCancel;
  final bool cancelling;
  final bool isCancelled;
  final String planName;
  final String provider;
  final String expiresAt;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final providerLabel = provider.isEmpty ? 'subscription' : provider;

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Subscription',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current plan: $planName',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (expiresAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Renews on $expiresAt',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            isCancelled
                ? 'Auto-renew has already been cancelled for this $providerLabel subscription. Your premium access remains active until the end of the current paid period.'
                : canCancel
                ? 'You can cancel your $providerLabel subscription here. The backend will update your premium status after the cancellation is confirmed.'
                : 'Cancellation is currently only available for PayPal subscriptions in the app. Your access will remain until your current premium period ends.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canCancel && !cancelling ? onCancel : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canCancel
                    ? const Color(0xFFA31618)
                    : isCancelled
                    ? Colors.green
                    : theme.disabledColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: cancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isCancelled
                          ? 'Auto-Renew Cancelled'
                          : canCancel
                          ? 'Cancel Subscription'
                          : 'Cancellation Unavailable',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  softWrap: true,
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

