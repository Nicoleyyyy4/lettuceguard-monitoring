import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LettuceGuardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int alertBadgeCount;

  const LettuceGuardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.alertBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      indicatorColor: LettuceGuardColors.primaryGreen.withOpacity(0.18),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: LettuceGuardColors.primaryGreen),
          label: 'Dashboard',
        ),

        const NavigationDestination(
          icon: Icon(Icons.show_chart_outlined),
          selectedIcon: Icon(Icons.show_chart, color: LettuceGuardColors.primaryGreen),
          label: 'History',
        ),

        NavigationDestination(
          icon: alertBadgeCount > 0
              ? Badge(
                  label: Text(alertBadgeCount.toString()),
                  backgroundColor: LettuceGuardColors.statusError,
                  child: const Icon(Icons.notifications_outlined),
                )
              : const Icon(Icons.notifications_outlined),
          selectedIcon: alertBadgeCount > 0
              ? Badge(
                  label: Text(alertBadgeCount.toString()),
                  backgroundColor: LettuceGuardColors.statusError,
                  child: const Icon(Icons.notifications, color: LettuceGuardColors.primaryGreen),
                )
              : const Icon(Icons.notifications, color: LettuceGuardColors.primaryGreen),
          label: 'Alerts',
        ),

        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings, color: LettuceGuardColors.primaryGreen),
          label: 'Settings',
        ),
      ],
    );
  }
}
