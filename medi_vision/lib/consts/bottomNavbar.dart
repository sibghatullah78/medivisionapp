import 'package:flutter/material.dart';
import 'package:medi_vision_app/consts/themes.dart';

class AnimatedNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BottomAppBar(
      elevation: 4,
      padding: EdgeInsets.zero,
      notchMargin: 8.0,
      shape: const CircularNotchedRectangle(),
      child: Container(
        height: kBottomNavigationBarHeight,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 0, "Home", theme),
            _buildNavItem(Icons.qr_code_scanner, 1, "Scan", theme),
            _buildNavItem(Icons.person, 2, "Profile", theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bool isSelected = widget.currentIndex == index;
    final Color iconColor = isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6);
    final Color backgroundColor = isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent;
    final Color textColor = isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 28.0,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    child: child,
                  ),
                );
              },
              child: isSelected
                  ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}