import 'package:flutter/material.dart';
import 'package:impact_app/screens/checin_screen.dart';
import 'package:impact_app/utils/bottom_menu_handler.dart';
import 'package:impact_app/widget/custom_navbar_bottom_widget.dart';
import 'package:impact_app/api/notification_api_service.dart';
import 'package:impact_app/models/notification_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationApiService _apiService = NotificationApiService();
  bool _isLoading = true;
  List<AppNotification> _notifications = [];
  int _selectedIndex = 2; // Index for navigation bar

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _apiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat notifikasi: $e')),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      bool success = await _apiService.markAsRead(notificationId);
      if (success) {
        setState(() {
          for (var i = 0; i < _notifications.length; i++) {
            if (_notifications[i].id == notificationId) {
              final updatedNotification = AppNotification(
                id: _notifications[i].id,
                title: _notifications[i].title,
                body: _notifications[i].body,
                image: _notifications[i].image,
                type: _notifications[i].type,
                data: _notifications[i].data,
                isRead: true,
                readAt: DateTime.now().toIso8601String(),
                createdAt: _notifications[i].createdAt,
              );
              _notifications[i] = updatedNotification;
              break;
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai notifikasi: $e')),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Handle notification tap based on notification type
    if (!notification.isRead) {
      _markAsRead(notification.id!);
    }
    
    if (notification.type == 'checkout_reminder') {
      // Navigate to check-in screen for checkout
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => CheckinMapScreen(),
        ),
      );
    } else if (notification.type == 'activity') {
      // Navigate to activity screen
      BottomMenu.onItemTapped(context, 1);
    } else {
      // Show notification details
      _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title ?? 'Notification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    notification.image!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 60),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(notification.body ?? ''),
              const SizedBox(height: 8),
              Text(
                _formatDate(notification.createdAt),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyNotifications()
                : _buildNotificationsList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => CheckinMapScreen(),
            ),
          );
        },
        backgroundColor: AppColors.success,
        child: const Icon(Icons.location_on, color: Colors.white, size: 30),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _selectedIndex,
        onTabSelected: (i) => BottomMenu.onItemTapped(context, i),
        onCheckInPressed: () {},
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/no_notification.png', height: 200),
          const SizedBox(height: 24),
          const Text(
            'Tidak Ada Notifikasi',
            style: TextStyle(fontSize: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anda belum memiliki notifikasi',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: notification.isRead ? 1 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: notification.isRead
                ? BorderSide.none
                : const BorderSide(color: AppColors.primary, width: 1),
          ),
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator
                      notification.isRead
                          ? const SizedBox(width: 24)
                          : const Padding(
                              padding: EdgeInsets.only(top: 4, right: 8),
                              child: Icon(
                                Icons.circle,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ),
                      
                      // Notification content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date and time
                            Text(
                              _formatDate(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Image if available
                            if (notification.image != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  notification.image!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported, size: 40),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Title
                            Text(
                              notification.title ?? 'Notification',
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // Body
                            Text(
                              notification.body ?? '',
                              style: TextStyle(
                                color: notification.isRead
                                    ? Colors.grey.shade700
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}