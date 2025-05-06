import 'package:flutter/material.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/widget/badge_count_widget.dart';

class CustomBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onCheckInPressed;

  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCheckInPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.grey[300],
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(icon: Icons.home, label: 'Home', index: 0),
            _buildTabItem(icon: Icons.bar_chart, label: 'Activity', index: 1),
            const SizedBox(width: 40), // space for FAB
            _buildTabItem(icon: Icons.notifications, label: 'Notification', index: 2),
            _buildTabItem(icon: Icons.settings, label: 'Profil', index: 3),
          ],
        ),
      ),
    );
  }

  // Widget _buildTabItem({required IconData icon, required String label, required int index}) {
  //   final isSelected = currentIndex == index;
  //   final color = isSelected ? Colors.blue : Colors.black87;
  //   return GestureDetector(
  //     onTap: () => onTabSelected(index),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(icon, color: color),
  //         Text(label, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTabItem({
  required IconData icon, 
  required String label, 
  required int index,
  int badgeCount = 0,
}) {
  final isSelected = currentIndex == index;
  final color = isSelected ? AppColors.primary : Colors.black87;
  
  Widget iconWidget = Icon(icon, color: color);
  
  // Add badge for notification icon
  if (index == 2 && badgeCount > 0) {
    iconWidget = BadgeCount(
      count: badgeCount,
      child: iconWidget,
    );
  }
  
  return GestureDetector(
    onTap: () => onTabSelected(index),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
        Text(
          label, 
          style: TextStyle(
            color: color, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
}