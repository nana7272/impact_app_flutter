// posm_models.dart

class PosmType {
  final String id;
  final String nama;

  PosmType({required this.id, required this.nama});

  factory PosmType.fromJson(Map<String, dynamic> json) {
    return PosmType(
      id: json['id'] as String,
      nama: json['nama'] as String,
    );
  }
}

class PosmStatus {
  final String id;
  final String nama;

  PosmStatus({required this.id, required this.nama});

  factory PosmStatus.fromJson(Map<String, dynamic> json) {
    return PosmStatus(
      id: json['id'] as String,
      nama: json['nama'] as String,
    );
  }
}