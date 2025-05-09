import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import '../utils/logger.dart';
import '../utils/session_manager.dart';
import '../api/notification_api_service.dart';

// Fungsi handler untuk message di background (saat aplikasi ditutup)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseService().setupFlutterNotifications();
  
  Logger().i('FirebaseService', 'Handling background message: ${message.messageId}');
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final Logger _logger = Logger();
  final String _tag = 'FirebaseService';

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool isFlutterLocalNotificationsInitialized = false;

  // Inisialisasi Firebase Messaging
  Future<void> initialize() async {
    try {
      // Pastikan Firebase sudah diinisialisasi
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set handler background message
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Inisialisasi flutter local notifications
      await setupFlutterNotifications();

      // Request permission
      await requestPermission();

      // Listener untuk foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.i(_tag, 'Got a message whilst in the foreground!');
        _logger.i(_tag, 'Message data: ${message.data}');

        if (message.notification != null) {
          _logger.i(_tag, 'Message also contained a notification: ${message.notification!.title}');
          _showNotification(message);
        }
      });

      // Listener untuk message yang dibuka
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _logger.i(_tag, 'A new onMessageOpenedApp event was published!');
        _handleNotificationOpen(message);
      });

      // Handle initial message (app dibuka dari notifikasi)
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          _logger.i(_tag, 'App opened from terminated state via notification');
          _handleNotificationOpen(message);
        }
      });

      // Register device token after user logged in
      final bool isLoggedIn = await SessionManager().isLoggedIn();
      if (isLoggedIn) {
        await registerDeviceToken();
      }
    } catch (e) {
      _logger.e(_tag, 'Error initializing Firebase: $e');
    }
  }

  // Setup Flutter Local Notifications
  Future<void> setupFlutterNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }
    
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Initialize settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          Map<String, dynamic> data = json.decode(response.payload!);
          // Handle payload data untuk navigasi
        }
      },
    );

    isFlutterLocalNotificationsInitialized = true;
  }

  // Request notification permission
  Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _logger.i(_tag, 'User granted permission: ${settings.authorizationStatus}');
  }

  // Mendapatkan FCM token
  Future<String?> getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      _logger.i(_tag, 'FCM Token: $token');
      return token;
    } catch (e) {
      _logger.e(_tag, 'Error getting FCM token: $e');
      return null;
    }
  }

  // Register device token ke server
  Future<bool> registerDeviceToken() async {
    try {
      // Make sure user is logged in
      final isLoggedIn = await SessionManager().isLoggedIn();
      if (!isLoggedIn) {
        _logger.w(_tag, 'User is not logged in, cannot register device token');
        return false;
      }
      
      // Check for user ID presence
      final user = await SessionManager().getCurrentUser();
      if (user == null || user.id == null) {
        _logger.e(_tag, 'User data not found or user ID is null, cannot register device token');
        return false;
      }
      
      // Use dedicated service to register token
      return await NotificationApiService().registerDeviceToken();
    } catch (e) {
      _logger.e(_tag, 'Error registering device token: $e');
      return false;
    }
  }

  // Subscribe ke topic
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    _logger.i(_tag, 'Subscribed to topic: $topic');
  }

  // Unsubscribe dari topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    _logger.i(_tag, 'Unsubscribed from topic: $topic');
  }

  // Menampilkan local notification
  void _showNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // Handle when notification is opened
  void _handleNotificationOpen(RemoteMessage message) {
    // Implementasi navigasi berdasarkan data notifikasi
    // Contoh:
    // if (message.data.containsKey('screen')) {
    //   final String screen = message.data['screen'];
    //   navigateToScreen(screen, message.data);
    // }
  }
}