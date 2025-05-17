// lib/screens/product/planogram/model/api_display_type_model.dart
class ApiDisplayType {
  final String image;
  final String nama;

  ApiDisplayType({required this.image, required this.nama});

  factory ApiDisplayType.fromJson(Map<String, dynamic> json) {
    return ApiDisplayType(
      image: json['image'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
    );
  }

  // Untuk perbandingan di DropdownButtonFormField
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiDisplayType &&
          runtimeType == other.runtimeType &&
          nama == other.nama;

  @override
  int get hashCode => nama.hashCode;
}
