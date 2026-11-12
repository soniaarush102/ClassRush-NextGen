import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
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
      home: const DashboardScreen(),
    );
  }
}
