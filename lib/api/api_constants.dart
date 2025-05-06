class ApiConstants {
  // Base URL API
  static const String baseApiUrl = 'https://api.impactdigitalreport.com/public';
  
  // Auth endpoints
  static const String login = '/api/users/login';
  static const String register = '/api/users/register';
  static const String masterData = '/api/users/masterdata';
  
  // Protected endpoints
  static const String profile = '/api/profile';
  static const String stores = '/api/stores';
  static const String products = '/api/products';
  static const String checkin = '/api/checkin';
  static const String checkout = '/api/checkout';
  static const String activities = '/api/activities';

  // Notification endpoints
  static const String deviceToken = '/api/device-token';
  static const String notifications = '/api/notifications';

  // Sales Print Out endpoints
  static const String salesPrintOut = '/api/sales-print-out';
  static const String searchProducts = '/api/products/search';
}