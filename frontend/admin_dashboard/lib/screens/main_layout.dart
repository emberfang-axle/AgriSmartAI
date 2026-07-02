import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/sidebar.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'farmers_screen.dart';
import 'notifications_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Order matches sidebar nav items: Dashboard, Farmers, Analytics, Notifications
  static const _titles = ['Dashboard', 'Farmers', 'Analytics', 'Notifications'];

  final _screens = const [
    DashboardScreen(),
    FarmersScreen(),
    AnalyticsScreen(),
    NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          // Permanent sidebar layout for desktop/tablet
          return Scaffold(
            backgroundColor: kBackground,
            body: Row(
              children: [
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (i) => setState(() => _selectedIndex = i),
                ),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          );
        }

        // Drawer-based navigation for narrow widths
        return Scaffold(
          backgroundColor: kBackground,
          appBar: AppBar(
            title: Text(_titles[_selectedIndex]),
            backgroundColor: kDeepGreen,
            foregroundColor: Colors.white,
            actions: [
              if (provider.unreadCount > 0)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded),
                      onPressed: () => setState(() => _selectedIndex = 3),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: kWarmGold, shape: BoxShape.circle),
                        child: Text('${provider.unreadCount}',
                            style: const TextStyle(fontSize: 9,
                                fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          drawer: Drawer(
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (i) {
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
              },
            ),
          ),
          body: _screens[_selectedIndex],
        );
      },
    );
  }
}
