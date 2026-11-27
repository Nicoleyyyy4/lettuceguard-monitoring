import 'package:flutter/material.dart';
import '../utils/colors.dart';

enum NavigationLayoutMode { bottomBar, rail, sidebar }

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class LettuceGuardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int alertBadgeCount;
  final NavigationLayoutMode mode;
  final Widget? sidebarHeader;
  final Widget? sidebarFooter;

  const LettuceGuardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.alertBadgeCount = 0,
    this.mode = NavigationLayoutMode.bottomBar,
    this.sidebarHeader,
    this.sidebarFooter,
  });

  static const List<_NavItem> _items = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    _NavItem(
      label: 'History',
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart_rounded,
    ),
    _NavItem(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      NavigationLayoutMode.sidebar => _buildSidebar(context),
      NavigationLayoutMode.rail => _buildRail(context),
      NavigationLayoutMode.bottomBar => _buildBottomBar(context),
    };
  }

  Widget _buildBottomBar(BuildContext context) {
    final primary = LettuceGuardColors.primary(context);
    final border = LettuceGuardColors.border(context);

    return Container(
      decoration: BoxDecoration(
        color: LettuceGuardColors.surface(context),
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: primary.withValues(
          alpha: LettuceGuardColors.isDark(context) ? 0.22 : 0.14,
        ),
        destinations: List.generate(_items.length, (i) {
          final item = _items[i];
          final isAlerts = i == 2 && alertBadgeCount > 0;
          return NavigationDestination(
            icon: isAlerts
                ? Badge(
                    label: Text(alertBadgeCount.toString()),
                    backgroundColor: LettuceGuardColors.statusError,
                    child: Icon(item.icon),
                  )
                : Icon(item.icon),
            selectedIcon: isAlerts
                ? Badge(
                    label: Text(alertBadgeCount.toString()),
                    backgroundColor: LettuceGuardColors.statusError,
                    child: Icon(item.selectedIcon, color: primary),
                  )
                : Icon(item.selectedIcon, color: primary),
            label: item.label,
          );
        }),
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    final primary = LettuceGuardColors.primary(context);
    final isDark = LettuceGuardColors.isDark(context);

    return Container(
      width: 84,
      decoration: BoxDecoration(
        color: LettuceGuardColors.sidebar(context),
        border: Border(
          right: BorderSide(color: LettuceGuardColors.border(context)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LettuceGuardColors.heroGradient(context),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: LettuceGuardColors.primaryGreen.withValues(
                      alpha: 0.28,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final item = _items[i];
                  final selected = i == currentIndex;
                  final showBadge = i == 2 && alertBadgeCount > 0;

                  return Tooltip(
                    message: item.label,
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: isDark ? 0.20 : 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            showBadge
                                ? Badge(
                                    label: Text(alertBadgeCount.toString()),
                                    backgroundColor:
                                        LettuceGuardColors.statusError,
                                    child: Icon(
                                      selected ? item.selectedIcon : item.icon,
                                      color: selected
                                          ? primary
                                          : LettuceGuardColors.textSecondary(
                                              context,
                                            ),
                                      size: 22,
                                    ),
                                  )
                                : Icon(
                                    selected ? item.selectedIcon : item.icon,
                                    color: selected
                                        ? primary
                                        : LettuceGuardColors.textSecondary(
                                            context,
                                          ),
                                    size: 22,
                                  ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? primary
                                    : LettuceGuardColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (sidebarFooter != null) ...[
              const Divider(height: 1),
              Padding(padding: const EdgeInsets.all(10), child: sidebarFooter!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final primary = LettuceGuardColors.primary(context);
    final isDark = LettuceGuardColors.isDark(context);

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: LettuceGuardColors.sidebar(context),
        border: Border(
          right: BorderSide(color: LettuceGuardColors.border(context)),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sidebarHeader != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: sidebarHeader!,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'MONITORING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: LettuceGuardColors.textSecondary(context),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final item = _items[i];
                  final selected = i == currentIndex;
                  final showBadge = i == 2 && alertBadgeCount > 0;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(14),
                      hoverColor: primary.withValues(alpha: 0.06),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: isDark ? 0.18 : 0.11)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? primary.withValues(alpha: 0.28)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? item.selectedIcon : item.icon,
                              size: 21,
                              color: selected
                                  ? primary
                                  : LettuceGuardColors.textSecondary(context),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? primary
                                      : LettuceGuardColors.textPrimary(context),
                                ),
                              ),
                            ),
                            if (showBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: LettuceGuardColors.statusError,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  alertBadgeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (sidebarFooter != null) ...[
              const Divider(height: 1),
              Padding(padding: const EdgeInsets.all(14), child: sidebarFooter!),
            ],
          ],
        ),
      ),
    );
  }
}
