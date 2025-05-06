import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onScanPressed;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onScanPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: Icon(Icons.search, color: AppColors.textSecondary),
          ),
          // TextField
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
          // Scan Button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.textSecondary),
            onPressed: onScanPressed,
          ),
        ],
      ),
    );
  }
}