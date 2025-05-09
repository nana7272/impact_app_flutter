import 'package:flutter/material.dart';

/// Helper class for working with product status in the availability feature
class ProductStatusHelper {
  // Critical threshold (red)
  static const int criticalThreshold = 5;
  
  // Warning threshold (orange)
  static const int warningThreshold = 10;
  
  // Get status color based on stock level
  static Color getStatusColor(int totalStock) {
    if (totalStock <= criticalThreshold) {
      return Colors.red;
    } else if (totalStock <= warningThreshold) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  // Get status name
  static String getStatusName(int totalStock) {
    if (totalStock <= criticalThreshold) {
      return 'Critical';
    } else if (totalStock <= warningThreshold) {
      return 'Warning';
    } else {
      return 'Good';
    }
  }
  
  // Get status icon
  static IconData getStatusIcon(int totalStock) {
    if (totalStock <= criticalThreshold) {
      return Icons.error_outline;
    } else if (totalStock <= warningThreshold) {
      return Icons.warning_amber_outlined;
    } else {
      return Icons.check_circle_outline;
    }
  }
  
  // Get progress indicator value (for UI)
  static double getProgressValue(int totalStock) {
    // Maximum reasonable stock to consider as 100%
    const int maxStock = 30;
    
    if (totalStock <= 0) {
      return 0.0;
    } else if (totalStock >= maxStock) {
      return 1.0;
    } else {
      return totalStock / maxStock;
    }
  }
  
  // Determine if total stock is low (for filtering)
  static bool isLowStock(int totalStock) {
    return totalStock <= warningThreshold;
  }
  
  // Determine if total stock is critical (for alerts)
  static bool isCriticalStock(int totalStock) {
    return totalStock <= criticalThreshold;
  }
  
  // Calculate status value (0-3) for sorting and storage
  static int calculateStatusValue(int totalStock) {
    if (totalStock <= criticalThreshold) {
      return 3; // Critical
    } else if (totalStock <= warningThreshold) {
      return 2; // Warning
    } else {
      return 1; // Good
    }
  }
}