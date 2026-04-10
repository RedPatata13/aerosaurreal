import 'package:aerosaur/pages/device_management/qr_scanner_screen.dart';
import 'package:aerosaur/pages/internet_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'pages/entry_gate.dart';
import 'pages/login/login.dart';
import 'pages/signin/signin.dart';
import 'pages/home/home.dart';
import 'pages/settings/settings.dart';
import 'pages/device_management/device_management.dart';
import 'pages/subscription/subscription.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'routes/routes.dart';
import 'pages/notifications/notfications.dart';
import 'pages/device_management/device_management_args.dart';
import 'pages/location_gate.dart';
import 'package:provider/provider.dart';
import 'services/api/api_client.dart';
import 'services/api/notifications_api.dart';
import 'services/notifications/push_notification_service.dart';
import 'state/notifications_store.dart';
import 'state/user_store.dart';
import 'package:aerosaur/services/repositories/user_repository.dart';

Widget _withLocationGate(Widget child) => LocationGate(child: child);

Route<T> _buildHorizontalSlideRoute<T>({
  required RouteSettings settings,
  required Widget child,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;

      final offsetTween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(offsetTween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
  );
}

Route<T> _buildVerticalSlideRoute<T>({
  required RouteSettings settings,
  required Widget child,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;

      final offsetTween = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: curve));

      final fadeTween = Tween<double>(
        begin: 0.96,
        end: 1,
      ).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(offsetTween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: '.env');

  final apiBaseUrl = dotenv.env['API_BASE_URL'];
  if (apiBaseUrl == null || apiBaseUrl.trim().isEmpty) {
    throw Exception('Missing API_BASE_URL in .env');
  }

  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final notificationsApi = NotificationsApi(apiClient);
  final pushNotificationService = PushNotificationService(notificationsApi);
  await pushNotificationService.initialize();

  runApp(
    MyApp(
      apiClient: apiClient,
      notificationsApi: notificationsApi,
      pushNotificationService: pushNotificationService,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.apiClient,
    required this.notificationsApi,
    required this.pushNotificationService,
  });

  final ApiClient apiClient;
  final NotificationsApi notificationsApi;
  final PushNotificationService pushNotificationService;

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: widget.apiClient),
        Provider<NotificationsApi>.value(value: widget.notificationsApi),
        Provider<PushNotificationService>.value(
          value: widget.pushNotificationService,
        ),
        Provider<UserRepository>(
          create: (context) => UserRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<UserStore>(
          create: (context) => UserStore(context.read<UserRepository>()),
        ),
        ChangeNotifierProvider<NotificationsStore>(
          create: (context) => NotificationsStore(
            context.read<NotificationsApi>(),
            context.read<PushNotificationService>(),
          )..refreshUnreadState(silent: true),
        ),
      ],
      child: MaterialApp(
        title: 'Aerosaur',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => InternetGate(
          child: child ?? const SizedBox.shrink(),
        ),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        themeAnimationDuration: const Duration(milliseconds: 500),
        themeAnimationCurve: Curves.easeOutCubic,
        initialRoute: AppRoutes.entryGate,
        routes: {
          AppRoutes.entryGate: (_) => const EntryGate(),
          AppRoutes.signup: (_) => const SignUpPage(),
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.home: (_) => _withLocationGate(const HomePage()),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.premium:
              return _buildVerticalSlideRoute(
                settings: settings,
                child: _withLocationGate(const SubscriptionPage()),
              );
            case AppRoutes.settings:
              return _buildHorizontalSlideRoute(
                settings: settings,
                child: _withLocationGate(const SettingsPage()),
              );
            case AppRoutes.notifications:
              return _buildHorizontalSlideRoute(
                settings: settings,
                child: _withLocationGate(const NotificationsPage()),
              );
            case AppRoutes.deviceManagement:
              final args = settings.arguments as DeviceManagementArgs;

              return _buildHorizontalSlideRoute(
                settings: settings,
                child: _withLocationGate(
                  DeviceManagementPage(
                    uid: args.uid,
                    devices: args.devices,
                    onDevicesChanged: args.onDevicesChanged,
                  ),
                ),
              );
            case AppRoutes.qrScanner:
              final deviceName = settings.arguments as String?;

              return _buildHorizontalSlideRoute(
                settings: settings,
                child: _withLocationGate(
                  QrScannerScreen(deviceName: deviceName),
                ),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
