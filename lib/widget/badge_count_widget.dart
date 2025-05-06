import 'package:flutter/material.dart';
import 'package:impact_app/themes/app_colors.dart';

class BadgeCount extends StatelessWidget {
  final int count;
  final Widget child;
  final Color badgeColor;
  final Color textColor;
  
  const BadgeCount({
    Key? key,
    required this.count,
    required this.child,
    this.badgeColor = AppColors.error,
    this.textColor = Colors.white,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}