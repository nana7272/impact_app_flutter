// lib/models/survey/offline_survey_model.dart

class OfflineSurveyGroup {
  final String submissionGroupId;
  final String outletName;
  final String? idOutlet;
  final String idPrinciple;
  final String idUser;
  final String tglSubmission; // ISO8601 string of the first item
  final List<OfflineSurveyItemDetail> items;

  OfflineSurveyGroup({
    required this.submissionGroupId,
    required this.outletName,
    this.idOutlet,
    required this.idPrinciple,
    required this.idUser,
    required this.tglSubmission,
    required this.items,
  });
}

class OfflineSurveyItemDetail {
  final int localDbId;
  final String idSoal;
  final String pertanyaan;
  final String typeJawaban;
  final String? idJawabanKey;
  final String? jawabanText;
  final String? valueLainnya;
  final String? imagePath;

  OfflineSurveyItemDetail({
    required this.localDbId,
    required this.idSoal,
    required this.pertanyaan,
    required this.typeJawaban,
    this.idJawabanKey,
    this.jawabanText,
    this.valueLainnya,
    this.imagePath,
  });

  factory OfflineSurveyItemDetail.fromMap(Map<String, dynamic> map) {
    return OfflineSurveyItemDetail(
      localDbId: map['id'],
      idSoal: map['id_soal'],
      pertanyaan: map['pertanyaan'],
      typeJawaban: map['type_jawaban'],
      idJawabanKey: map['id_jawaban_key'],
      jawabanText: map['jawaban_text'],
      valueLainnya: map['value_lainnya'],
      imagePath: map['image_path'],
    );
  }
}
