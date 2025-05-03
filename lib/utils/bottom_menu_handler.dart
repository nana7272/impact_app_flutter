
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity_screen.dart';
import 'package:impact_app/screens/home_screen.dart';
import 'package:impact_app/screens/notification_screen.dart';
import 'package:impact_app/screens/setting_profile_screen.dart';

class BottomMenu {

static void onItemTapped(context, int index) {

    switch (index) {
      case 0:
      Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const HomeScreen()),
                                            (route) => false);
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ActivityScreen()),
                                            (route) => false);
        break;
      case 2:
        Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const NotificationScreen()),
                                            (route) => false);
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const SettingScreen()),
                                            (route) => false);
        break;
    }
}

}