import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'pages/entry_gate.dart';
import 'pages/auth/login.dart';
import 'pages/auth/signin.dart';
import 'pages/home/home.dart';
import 'pages/settings/settings.dart';
import 'pages/device_management/device_management.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'routes/routes.dart';
import 'pages/notfications.dart';
import 'pages/device_management/device_management_args.dart';
import 'pages/location_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: '.env');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aerosaur',
      debugShowCheckedModeBanner: false,
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
        AppRoutes.home: (_) => const LocationGate(child: HomePage()),
        AppRoutes.settings: (_) => const SettingsPage(),
        AppRoutes.notifications: (_) => const NotficationsPage(),
      },

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.deviceManagement:
            final args = settings.arguments as DeviceManagementArgs;

            return MaterialPageRoute(
              builder: (_) => DeviceManagementPage(
                uid: args.uid,
                devices: args.devices,
                onDevicesChanged: args.onDevicesChanged,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
