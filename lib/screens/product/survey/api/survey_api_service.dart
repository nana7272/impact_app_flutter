import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/survey/model/offline_survey_model.dart';
import 'package:impact_app/screens/product/survey/model/survey_question_model.dart';
import 'package:impact_app/screens/product/survey/model/survey_response_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:path/path.dart' as p; // For basename

class SurveyApiService {
  final String _baseUrl = ApiConstants.baseApiUrl;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();
  final String _tag = 'SurveyApiService';

  Future<List<SurveyQuestionModel>> fetchSurveyQuestions(String typeSurvey, String idPrinciple) async {
    final url = Uri.parse('$_baseUrl/api/questioner/$typeSurvey/$idPrinciple');
    _logger.d(_tag, 'Fetching survey questions from: $url');
    try {
      final response = await http.get(url, headers: Header.headget());
      if (response.statusCode == 200) {
        _logger.i(_tag, 'Survey questions fetched successfully. Response: ${response.body}');
        return surveyQuestionModelFromJson(response.body);
      } else {
        _logger.e(_tag, 'Failed to load survey questions. Status code: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load survey questions (${response.statusCode})');
      }
    } catch (e) {
      _logger.e(_tag, 'Error fetching survey questions: $e');
      throw Exception('Error fetching survey questions: $e');
    }
  }

  Future<bool> submitSurveyResponse(SurveyResponseLocalModel responseModel) async {
    final url = Uri.parse('$_baseUrl/api/questioner_hasil');
    _logger.d(_tag, 'Submitting survey response to: $url for soal: ${responseModel.idSoal}');
    
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({'Content-Type': 'multipart/form-data'}); // Multipart handles content type
    
    request.fields.addAll(responseModel.toApiFormData());

    if (responseModel.imagePath != null && responseModel.imagePath!.isNotEmpty) {
      File imageFile = File(responseModel.imagePath!);
      if (await imageFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
          'image', // API field name for the file
          imageFile.path,
          filename: p.basename(imageFile.path),
        ));
        _logger.d(_tag, 'Added image to request: ${imageFile.path}');
      } else {
         _logger.w(_tag, 'Image file not found at path: ${responseModel.imagePath}');
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i(_tag, 'Survey response submitted successfully for soal ${responseModel.idSoal}. Response: ${response.body}');
        return true;
      } else {
        _logger.e(_tag, 'Failed to submit survey response for soal ${responseModel.idSoal}. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e(_tag, 'Error submitting survey response for soal ${responseModel.idSoal}: $e');
      return false;
    }
  }
  
  Future<void> saveSurveyResponseOffline(SurveyResponseLocalModel responseModel) async {
    try {
      await _dbHelper.insertSurveyResponse(responseModel.toMap());
      _logger.i(_tag, 'Survey response for soal ${responseModel.idSoal} saved offline.');
    } catch (e) {
      _logger.e(_tag, 'Error saving survey response offline for soal ${responseModel.idSoal}: $e');
      throw Exception('Failed to save survey response offline: $e');
    }
  }

  Future<List<OfflineSurveyGroup>> getOfflineSurveyForDisplay() async {
    final List<Map<String, dynamic>> rawResponses = await _dbHelper.getUnsyncedSurveyResponses();
    if (rawResponses.isEmpty) {
      return [];
    }

    Map<String, List<OfflineSurveyItemDetail>> groupedBySubmissionId = {};
    Map<String, Map<String, String>> groupMetadata = {}; // To store outletName, tglSubmission etc. for each group

    for (var rawResponse in rawResponses) {
      final item = OfflineSurveyItemDetail.fromMap(rawResponse);
      final submissionGroupId = rawResponse['submission_group_id'] as String;

      groupedBySubmissionId.putIfAbsent(submissionGroupId, () => []).add(item);
      
      if (!groupMetadata.containsKey(submissionGroupId)) {
        groupMetadata[submissionGroupId] = {
          'outletName': rawResponse['outlet_name'] as String? ?? 'Unknown Outlet',
          'idOutlet': rawResponse['id_outlet'] as String? ?? '',
          'idPrinciple': rawResponse['id_principle'] as String? ?? '',
          'idUser': rawResponse['id_user'] as String? ?? '',
          'tglSubmission': rawResponse['tgl_submission'] as String? ?? DateTime.now().toIso8601String(),
        };
      }
    }

    List<OfflineSurveyGroup> resultGroups = [];
    groupedBySubmissionId.forEach((submissionId, items) {
      final metadata = groupMetadata[submissionId]!;
      resultGroups.add(OfflineSurveyGroup(
        submissionGroupId: submissionId,
        outletName: metadata['outletName']!,
        idOutlet: metadata['idOutlet'],
        idPrinciple: metadata['idPrinciple']!,
        idUser: metadata['idUser']!,
        tglSubmission: metadata['tglSubmission']!,
        items: items,
      ));
    });
    
    // Sort by submission date descending
    resultGroups.sort((a, b) => b.tglSubmission.compareTo(a.tglSubmission));
    _logger.d(_tag, "Loaded ${resultGroups.length} offline survey groups for display.");
    return resultGroups;
  }

  Future<bool> syncOfflineSurveyData() async {
    _logger.i(_tag, 'Starting offline survey data synchronization.');
    List<Map<String, dynamic>> unsyncedResponsesMaps = await _dbHelper.getUnsyncedSurveyResponses();
    
    if (unsyncedResponsesMaps.isEmpty) {
      _logger.i(_tag, 'No offline survey data to sync.');
      return true; // Nothing to sync, so considered successful.
    }

    List<SurveyResponseLocalModel> unsyncedResponses = unsyncedResponsesMaps
        .map((map) => SurveyResponseLocalModel.fromMap(map))
        .toList();
    
    _logger.d(_tag, 'Found ${unsyncedResponses.length} unsynced survey responses.');

    List<int> successfullySyncedIds = [];
    bool allSuccess = true;

    for (SurveyResponseLocalModel responseModel in unsyncedResponses) {
      _logger.d(_tag, 'Attempting to sync survey response ID: ${responseModel.localDbId}, Soal ID: ${responseModel.idSoal}');
      bool success = await submitSurveyResponse(responseModel);
      if (success) {
        if (responseModel.localDbId != null) {
          successfullySyncedIds.add(responseModel.localDbId!);
          _logger.i(_tag, 'Successfully synced survey response ID: ${responseModel.localDbId}');
        }
      } else {
        allSuccess = false;
        _logger.w(_tag, 'Failed to sync survey response ID: ${responseModel.localDbId}. It will remain offline.');
        // Optionally, break or continue based on requirements
      }
    }

    if (successfullySyncedIds.isNotEmpty) {
      _logger.d(_tag, 'Deleting ${successfullySyncedIds.length} successfully synced survey responses from local DB.');
      await _dbHelper.deleteSurveyResponsesByIds(successfullySyncedIds);
    }

    _logger.i(_tag, 'Offline survey data synchronization finished. Overall success: $allSuccess');
    return allSuccess;
  }
}
