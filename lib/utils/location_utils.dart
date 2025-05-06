import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'logger.dart';

class LocationUtils {
  static final Logger _logger = Logger();
  static const String _tag = 'LocationUtils';
  
  // Request location permissions
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  // Check if location is enabled
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await isLocationEnabled();
      if (!serviceEnabled) {
        _logger.w(_tag, 'Location services are disabled');
        return null;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w(_tag, 'Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _logger.w(_tag, 'Location permissions are permanently denied');
        return null;
      }
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _logger.e(_tag, 'Error getting current location: $e');
      return null;
    }
  }
  
  // Calculate distance between two points (in meters)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}