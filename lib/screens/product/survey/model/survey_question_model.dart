// lib/models/survey/survey_question_model.dart
import 'dart:convert';

List<SurveyQuestionModel> surveyQuestionModelFromJson(String str) =>
    List<SurveyQuestionModel>.from(json.decode(str).map((x) => SurveyQuestionModel.fromJson(x)));

String surveyQuestionModelToJson(List<SurveyQuestionModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SurveyQuestionModel {
    String id;
    String typeSurvey;
    String idPrinciple;
    String pertanyaan;
    String typeJawaban;
    String doc;
    String status;
    List<SurveyAnswerKeyModel> keys;

    // For UI state
    dynamic answer; // Can be String, File, List<String> (for checkbox IDs), Map<String, bool> for checkbox UI
    String? otherValue; // For "Lainnya" text input
    List<SurveyAnswerKeyModel> selectedCheckboxKeys = []; // For checkbox selected items

    SurveyQuestionModel({
        required this.id,
        required this.typeSurvey,
        required this.idPrinciple,
        required this.pertanyaan,
        required this.typeJawaban,
        required this.doc,
        required this.status,
        required this.keys,
        this.answer,
        this.otherValue,
    });

    factory SurveyQuestionModel.fromJson(Map<String, dynamic> json) => SurveyQuestionModel(
        id: json["id"],
        typeSurvey: json["type_survey"],
        idPrinciple: json["id_principle"],
        pertanyaan: json["pertanyaan"],
        typeJawaban: json["type_jawaban"],
        doc: json["doc"],
        status: json["status"],
        keys: List<SurveyAnswerKeyModel>.from(json["keys"].map((x) => SurveyAnswerKeyModel.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "type_survey": typeSurvey,
        "id_principle": idPrinciple,
        "pertanyaan": pertanyaan,
        "type_jawaban": typeJawaban,
        "doc": doc,
        "status": status,
        "keys": List<dynamic>.from(keys.map((x) => x.toJson())),
    };
}

class SurveyAnswerKeyModel {
    String id;
    String idQuestioner;
    String text;
    String doc;

    // For UI state
    bool isSelected = false; // For checkbox UI
    bool showsOtherField = false; // If this key represents "Lainnya"

    SurveyAnswerKeyModel({
        required this.id,
        required this.idQuestioner,
        required this.text,
        required this.doc,
    }) {
        // A common convention for "Lainnya" or "Others"
        if (text.toLowerCase().contains('lainnya') || text.toLowerCase().contains('others')) {
            showsOtherField = true;
        }
    }

    factory SurveyAnswerKeyModel.fromJson(Map<String, dynamic> json) => SurveyAnswerKeyModel(
        id: json["id"],
        idQuestioner: json["id_questioner"],
        text: json["text"],
        doc: json["doc"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "id_questioner": idQuestioner,
        "text": text,
        "doc": doc,
    };
}
