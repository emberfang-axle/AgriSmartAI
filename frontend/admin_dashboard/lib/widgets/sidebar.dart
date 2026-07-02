import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_provider.dart';

const List<_NavItem> _navItems = [
  _NavItem(icon: Icons.dashboard_rounded,      label: 'Dashboard'),
  _NavItem(icon: Icons.people_rounded,         label: 'Farmers'),
  _NavItem(icon: Icons.analytics_rounded,      label: 'Analytics'),
  _NavItem(icon: Icons.notifications_rounded,  label: 'Notifications'),
];

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: kDeepGreen,
      child: Column(
        children: [
          // Logo header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: kWarmGold, shape: BoxShape.circle),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 14),
                const Text('AgriSmartAI',
                    style: TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Admin Dashboard',
                    style: TextStyle(color: kSidebarText, fontSize: 12)),
              ],
            ),
          ),

          const Divider(color: Colors.white12, thickness: 1, height: 1),
          const SizedBox(height: 12),

          // Navigation items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final selected = selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onItemSelected(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? kWarmGold.withOpacity(0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: kWarmGold.withOpacity(0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon,
                                color: selected ? kWarmGold : kSidebarText,
                                size: 22),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: selected ? Colors.white : kSidebarText,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            // Notification badge on Notifications tab
                            if (i == 3)
                              Consumer<AppProvider>(
                                builder: (_, p, __) => p.unreadCount > 0
                                    ? Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: kWarmGold,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          p.unreadCount > 99
                                              ? '99+'
                                              : p.unreadCount.toString(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'New Bataan, Davao de Oro\nPhilippines',
              style: TextStyle(color: kSidebarText, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
