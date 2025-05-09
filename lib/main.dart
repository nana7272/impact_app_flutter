import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:impact_app/services/notification_service.dart';
import 'screens/intro_screen.dart';
import 'themes/app_theme.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup logger
  Logger().setLogLevel(LogLevel.debug);
  final logger = Logger();
  logger.i('App', 'Starting application...');
  
  try {
    // Inisialisasi Firebase
    await FirebaseService().initialize();
    logger.i('App', 'Firebase initialized successfully');
  } catch (e) {
    logger.e('App', 'Failed to initialize Firebase: $e');
    // Continue even if Firebase fails, app should work without it
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Mengatur orientasi hanya portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Mengatur tampilan system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Impact App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default tema
      home: const IntroScreen(),
    );
  }
}