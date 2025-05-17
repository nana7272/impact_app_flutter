// screens/activity/model/survey_report.dart
import 'dart:convert';

List<SurveyReport> surveyReportFromJson(String str) => List<SurveyReport>.from(json.decode(str).map((x) => SurveyReport.fromJson(x)));

String surveyReportToJson(List<SurveyReport> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SurveyReport {
    String outletName;
    String transactionDate; // Format "2025-05-17"
    List<QuestionAndAnswer> questionsAndAnswers;

    SurveyReport({
        required this.outletName,
        required this.transactionDate,
        required this.questionsAndAnswers,
    });

    factory SurveyReport.fromJson(Map<String, dynamic> json) => SurveyReport(
        outletName: json["outlet_name"],
        transactionDate: json["transaction_date"],
        questionsAndAnswers: List<QuestionAndAnswer>.from(json["questions_and_answers"].map((x) => QuestionAndAnswer.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "outlet_name": outletName,
        "transaction_date": transactionDate,
        "questions_and_answers": List<dynamic>.from(questionsAndAnswers.map((x) => x.toJson())),
    };
}

class QuestionAndAnswer {
    String questionText;
    String answerText;
    String questionType;

    QuestionAndAnswer({
        required this.questionText,
        required this.answerText,
        required this.questionType,
    });

    factory QuestionAndAnswer.fromJson(Map<String, dynamic> json) => QuestionAndAnswer(
        questionText: json["question_text"],
        answerText: json["answer_text"],
        questionType: json["question_type"],
    );

    Map<String, dynamic> toJson() => {
        "question_text": questionText,
        "answer_text": answerText,
        "question_type": questionType,
    };
}