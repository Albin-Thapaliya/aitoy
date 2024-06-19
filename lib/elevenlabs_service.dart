import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class VoiceService {
  final String apiKey;
  final String voiceId;

  VoiceService(this.apiKey, this.voiceId);

  Future<Uint8List?> textToSpeech(String text) async {
    var url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': apiKey,
        'Accept': 'audio/mpeg'
      },
      body: jsonEncode({
        'text': text,
        'model_id': 'eleven_monolingual_v1',
        'voice_settings': {'stability': 0.5, 'similarity_boost': 0.5}
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      print(
          'Failed to fetch or convert speech from ElevenLabs API: ${response.statusCode} ${response.reasonPhrase}');
      return null;
    }
  }
}