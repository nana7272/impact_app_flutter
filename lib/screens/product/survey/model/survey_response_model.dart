// lib/models/survey/survey_response_model.dart
import 'dart:io';

class SurveyResponseLocalModel {
  int? localDbId; // Nullable for new entries before DB insert
  String submissionGroupId;
  String idUser;
  String idPrinciple;
  String? idOutlet;
  String? outletName;
  String idSoal;
  String pertanyaan;
  String typeJawaban;
  String? idJawabanKey; // ID of the selected dropdown/checkbox option
  String? jawabanText;  // Text of the selected dropdown/checkbox option, or essay answer
  String? valueLainnya;
  String? imagePath;    // Local path for image file
  String tglSubmission; // ISO8601 String
  int isSynced;

  SurveyResponseLocalModel({
    this.localDbId,
    required this.submissionGroupId,
    required this.idUser,
    required this.idPrinciple,
    this.idOutlet,
    this.outletName,
    required this.idSoal,
    required this.pertanyaan,
    required this.typeJawaban,
    this.idJawabanKey,
    this.jawabanText,
    this.valueLainnya,
    this.imagePath,
    required this.tglSubmission,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': localDbId, // Will be handled by AUTOINCREMENT if null
      'submission_group_id': submissionGroupId,
      'id_user': idUser,
      'id_principle': idPrinciple,
      'id_outlet': idOutlet,
      'outlet_name': outletName,
      'id_soal': idSoal,
      'pertanyaan': pertanyaan,
      'type_jawaban': typeJawaban,
      'id_jawaban_key': idJawabanKey,
      'jawaban_text': jawabanText,
      'value_lainnya': valueLainnya,
      'image_path': imagePath,
      'tgl_submission': tglSubmission,
      'is_synced': isSynced,
    };
  }

  factory SurveyResponseLocalModel.fromMap(Map<String, dynamic> map) {
    return SurveyResponseLocalModel(
      localDbId: map['id'],
      submissionGroupId: map['submission_group_id'],
      idUser: map['id_user'],
      idPrinciple: map['id_principle'],
      idOutlet: map['id_outlet'],
      outletName: map['outlet_name'],
      idSoal: map['id_soal'],
      pertanyaan: map['pertanyaan'],
      typeJawaban: map['type_jawaban'],
      idJawabanKey: map['id_jawaban_key'],
      jawabanText: map['jawaban_text'],
      valueLainnya: map['value_lainnya'],
      imagePath: map['image_path'],
      tglSubmission: map['tgl_submission'],
      isSynced: map['is_synced'],
    );
  }

  // For API submission
  Map<String, String> toApiFormData() {
    final Map<String, String> data = {
      'id_user': idUser,
      'id_principle': idPrinciple,
      'id_soal': idSoal,
      'status': '1', // Default status
    };
    if (idOutlet != null) data['id_outlet'] = idOutlet!;
    if (idJawabanKey != null) data['id_jawaban'] = idJawabanKey!;
    if (jawabanText != null) data['text'] = jawabanText!; // For essay or selected option text
    if (valueLainnya != null && valueLainnya!.isNotEmpty) data['value_lainnya'] = valueLainnya!;
    
    return data;
  }
}
