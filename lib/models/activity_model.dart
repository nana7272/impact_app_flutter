class Activity {
  final String? id;
  final String? storeId;
  final String? storeName;
  final String? date;
  final String? checkInTime;
  final String? checkOutTime;
  final String? duration;
  final String? timestamp;
  
  Activity({
    this.id,
    this.storeId,
    this.storeName,
    this.date,
    this.checkInTime,
    this.checkOutTime,
    this.duration,
    this.timestamp,
  });
  
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      storeId: json['store_id'],
      storeName: json['store_name'],
      date: json['date'],
      checkInTime: json['check_in'],
      checkOutTime: json['check_out'],
      duration: json['duration'],
      timestamp: json['timestamp'],
    );
  }
}