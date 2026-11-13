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

/// Keep one auth-state subscription for the lifetime of the app.
/// Firebase restores the saved Android session; signed-in users bypass login.
class _AuthenticationGate extends StatefulWidget {
  const _AuthenticationGate();

  @override
  State<_AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<_AuthenticationGate> {
  late final Stream<User?> _authChanges;

  @override
  void initState() {
    super.initState();
    _authChanges = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
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
