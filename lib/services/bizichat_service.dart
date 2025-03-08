// lib/services/bizichat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message.dart';

class BizichatService {
  final String _baseUrl = 'https://bizichat.ai/api';
  late final String _accessToken;
  late final String _flowId;

  BizichatService() {
    _accessToken = dotenv.env['BIZICHAT_ACCESS_TOKEN'] ?? '';
    _flowId = dotenv.env['BIZICHAT_FLOW_ID'] ?? '';
    
    if (_accessToken.isEmpty) {
      print('WARNING: Bizichat access token is not set!');
    }
    
    if (_flowId.isEmpty) {
      print('WARNING: Bizichat flow ID is not set!');
    }
  }

  // Create a new user in Bizichat
  Future<String?> createUser(String name, String email) async {
    try {
      final url = Uri.parse('$_baseUrl/users');
      
      // Prepare the request body based on the API structure shown in the screenshot
      final requestBody = {
        "phone": "1234567890", // Placeholder, adjust as needed
        "first_name": name.split(' ').first,
        "last_name": name.split(' ').length > 1 ? name.split(' ').last : "",
        "gender": "unknown", // Default value
        "options": [
          {
            "action": "send_flow",
            "flow_id": _flowId
          },
          {
            "action": "add_tag",
            "tag_name": "APP_USER" // Tag to identify users from your app
          },
          {
            "action": "set_field_value",
            "field_name": "email",
            "value": email
          }
        ]
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // According to the screenshot, the response has a 'data' field with 'id'
        return data['data']?['id'] ?? data['id'] ?? data['user_id'];
      } else {
        print('Failed to create Bizichat user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Create Bizichat user error: $e');
      return null;
    }
  }

  // Get user details from Bizichat
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to get Bizichat user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get Bizichat user error: $e');
      return null;
    }
  }

  // Store user input in Bizichat custom field
  Future<bool> storeUserInput(String userId, String input) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId/custom_fields');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "action": "set_field_value",
          "field_name": "last_input",
          "value": input
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Store user input error: $e');
      return false;
    }
  }

  // Trigger Bizichat flow
  Future<bool> triggerFlow(String userId, {String? flowId}) async {
    try {
      final flowToUse = flowId ?? _flowId;
      final url = Uri.parse('$_baseUrl/users/$userId/actions');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "action": "send_flow",
          "flow_id": flowToUse
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Trigger flow error: $e');
      return false;
    }
  }

  // Get latest AI response from custom field
  Future<String?> getLatestAIResponse(String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId/custom_fields/last_output');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['value'];
      } else {
        print('Failed to get AI response: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get AI response error: $e');
      return null;
    }
  }
}