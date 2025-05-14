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
  static const String currentVisit = '/api/current-visit'; // Endpoint untuk mendapatkan kunjungan aktif


  // Notification endpoints
  static const String deviceToken = '/api/device-token';
  static const String notifications = '/api/notifications';

  // Sales Print Out endpoints
  static const String salesPrintOut = '/api/salesbyprintout/create';
  static const String searchProducts = '/api/products/search';

  static const String openEnding = '/api/openending';
  static const String posm = '/api/posm';
  static const String outOfStock = '/api/out-of-stock';
  static const String activation = '/api/activation';
  static const String planogram = '/api/planogram';
  static const String priceMonitoring = '/api/price-monitoring';
  static const String competitor = '/api/competitor';

// Availability endpoints
  static const String availability = '/api/availability';
  static const String availabilityHistory = '/api/availability/history';
  static const String availabilitySync = '/api/availability/sync';
  
  // Other endpoints might include:
  static const String availabilityImages = '/api/availability/images';
  static const String availabilityStats = '/api/availability/stats';

  // Tambahkan endpoint Sampling Konsumen
  static const String samplingKonsumen = '/api/sampling-konsumen';
  static const String produkSampling = '/api/produk-sampling';

  // Tambahkan endpoint Promo Audit
  static const String promoAudit = '/api/promo-audit';

}

class Header {
  static headpos() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'IOS 1.0.0 (1)'
    };
  }
  static headget() {
    return {
      'User-Agent': 'IOS 1.0.0 (1)'
    };
  }
}