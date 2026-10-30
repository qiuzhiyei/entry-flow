import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom navigation with four equal destinations. The "记一笔" destination
/// opens the record screen but deliberately uses the same icon slot and label
/// baseline as the other tabs, so the row stays visually uniform.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: AppColors.surface,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 6, bottom: bottomInset + 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _NavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_outlined,
                  label: '首页',
                  selected: selectedIndex == 0,
                  onTap: () => onSelect(0),
                ),
              ),
              Expanded(
                child: _NavDestination(
                  icon: Icons.bar_chart_rounded,
                  selectedIcon: Icons.bar_chart_rounded,
                  label: '统计',
                  selected: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
              ),
              Expanded(
                child: _NavDestination(
                  icon: Icons.add_rounded,
                  selectedIcon: Icons.add_rounded,
                  label: '记一笔',
                  selected: false,
                  onTap: onAdd,
                ),
              ),
              Expanded(
                child: _NavDestination(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_outline_rounded,
                  label: '我的',
                  selected: selectedIndex == 2,
                  onTap: () => onSelect(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.mint : AppColors.ink3;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(selected ? selectedIcon : icon, size: 23, color: color),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: AppMotion.fast,
                  style: AppText.navLabel.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
