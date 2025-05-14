import 'package:impact_app/api/api_client.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/utils/logger.dart';

class OpenEndingApiService {
  final ApiClient _client = ApiClient();
  final Logger _logger = Logger();
  final String _tag = 'OpenEndingApiService';

  Future<bool> submitOpenEndingData(List<Map<String, dynamic>> openEndingItems) async {
    try {
      _logger.d(_tag, 'Submitting Open Ending data: $openEndingItems');
      // The ApiClient.post method already prepends the baseApiUrl
      final response = await _client.post(ApiConstants.openEnding, openEndingItems);
      _logger.d(_tag, 'Open Ending submission response: $response');
      // Assuming a successful response means the data was accepted.
      // You might need to check specific fields in the response.
      return true; // Or based on response content
    } catch (e) {
      _logger.e(_tag, 'Error submitting Open Ending data: $e');
      return false;
    }
  }
}