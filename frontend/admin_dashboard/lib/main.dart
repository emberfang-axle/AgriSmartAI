import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgriSmartAdminApp());
}

class AgriSmartAdminApp extends StatelessWidget {
  const AgriSmartAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
      ],
      child: MaterialApp(
        title: 'AgriSmartAI Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _Loader(),
      ),
    );
  }
}

// Shows a branded splash while AppProvider initializes
class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (!provider.initialized) {
      return const Scaffold(
        backgroundColor: kDeepGreen,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grass_rounded, size: 72, color: kWarmGold),
              SizedBox(height: 16),
              Text(
                'AgriSmartAI',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 6),
              Text('Admin Dashboard',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 40),
              CircularProgressIndicator(color: kWarmGold, strokeWidth: 2.5),
            ],
          ),
        ),
      );
    }
    return const MainLayout();
  }
}
