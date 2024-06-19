import 'dart:convert';
import 'package:http/http.dart' as http;

class GPTService {
  final String apiKey;
  final Uri apiUrl = Uri.parse('https://api.openai.com/v1/chat/completions');

  GPTService(this.apiKey);

  Future<String> getResponse(
      String userInput, Map<String, dynamic> profile) async {
    List<Map<String, dynamic>> messages = [
      {'role': 'system', 'content': profile['context']},
      {'role': 'user', 'content': userInput}
    ];

    final response = await http.post(
      apiUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4-turbo',
        'messages': messages,
        'max_tokens': 150,
        'temperature': 0.9
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to fetch response from OpenAI: ${errorData['error']['message']}');
    }
  }
}