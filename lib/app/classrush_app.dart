import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';

class ClassRushApp extends StatelessWidget {
  const ClassRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CLASSRUSH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _AuthenticationGate(),
    );
  }
}

/// Firebase Auth restores the saved session when the app starts.
/// A signed-in user goes straight to the dashboard; the auth screen is
/// shown only when there is no signed-in user.
class _AuthenticationGate extends StatelessWidget {
  const _AuthenticationGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null) {
          return const DashboardScreen();
        }

        return const AuthScreen();
      },
    );
  }
}
