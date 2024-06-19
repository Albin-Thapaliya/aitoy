import 'dart:io';
import 'dart:typed_data';
import 'package:aitoy/EditablePromptPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'elevenlabs_service.dart';
import 'openai_service.dart';
import 'settings_page.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Toy',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  PorcupineManager? _porcupineManager;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  String name = '';
  String promptText = '';
  String imageUrl = '';
  String welcomeMessage = '';
  TextEditingController promptController = TextEditingController();
  String openAiToken = '';
  String elevenLabsToken = '';
  String openAiResponse = '';
  final audioPlayer = AudioPlayer();

  final List<Map<String, dynamic>> profiles = [
    {
      'name': 'Rodney Dangerfield',
      'context':
          'This GPT is a doll version of Rodney Dangerfield, focusing on delivering very mean and edgy jokes in the comedian\'s signature style.',
      'description':
          'Rodney Dangerfield doll cracking very mean and edgy jokes.',
      'prompt_starters': [
        'Say Hey Rodney, tell me a joke.',
      ],
      'welcomeMessage':
          'Hey pal, I don\'t got time for this, what do you want?',
      'imageUrl':
          'https://upload.wikimedia.org/wikipedia/commons/7/71/Rodney_Dangerfield_1972-1.jpg'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _loadProfile(0);
    _loadSettings();
  }

  void _initializeSpeech() async {
    bool available = await _speechToText.initialize(
        onError: (val) => print("STT Error: $val"),
        onStatus: (val) => print("STT Status: $val"));

    if (!available) {
      print("Speech recognition unavailable.");
    } else {
      print("Speech recognition available.");
    }
  }

  void _initPorcupine() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accessKey = prefs.getString('porcupineAccessKey') ?? '';
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        ["assets/keywords/Hey-Rodney_en_android_v3_0_0.ppn"],
        _wakeWordDetected,
      );
      _porcupineManager!.start();
    } catch (e) {
      print("Error initializing Porcupine: $e");
    }
  }

  void _wakeWordDetected(int keywordIndex) {
    print("Wake word detected");
    _stopPorcupineAndListen();
  }

  void _stopPorcupineAndListen() async {
    await _porcupineManager?.stop();
    print("Porcupine stopped, starting STT...");
    if (!_speechToText.isAvailable) {
      print("STT Service is not available.");
      return;
    }

    _listen();
  }

  void _listen() async {
    if (!_speechToText.isAvailable) {
      print("STT Service is not available.");
      return;
    }

    if (_isListening) {
      print("Already listening. Attempting to stop and restart STT.");
      _speechToText.stop(); // Ensure it's stopped before restarting
      _isListening = false; // Reset listening state
    }

    _speechToText.listen(
      onResult: (result) {
        if (result.finalResult && result.confidence > 0) {
          print("Final result: ${result.recognizedWords}");
          _sendPrompt(result.recognizedWords);
          _isListening = false;
          _speechToText.stop();
          _restartPorcupine();
        }
      },
      onSoundLevelChange: (level) => print("Sound level: $level"),
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 5),
      localeId: "en_US",
    );
  }

  void _restartPorcupine() async {
    if (_porcupineManager != null) {
      try {
        print("Restarting Porcupine...");
        await _porcupineManager?.start();
      } catch (e) {
        print("Error restarting Porcupine: $e");
      }
    }
  }

  @override
  void dispose() {
    _porcupineManager?.stop();
    _porcupineManager?.delete();
    _speechToText.stop();
    super.dispose();
  }

  void _loadProfile(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPrompt =
        prefs.getString('promptText_${profiles[index]['name']}');
    setState(() {
      name = profiles[index]['name'];
      promptText = storedPrompt ?? profiles[index]['prompt_starters'][0];
      imageUrl = profiles[index]['imageUrl'];
      welcomeMessage = profiles[index]['welcomeMessage'];
    });
  }

  void _chooseProfile() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(profiles[index]['name']),
                subtitle: Text(profiles[index]['description']),
                onTap: () {
                  _loadProfile(index);
                  Navigator.pop(context);
                  _initPorcupine();
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _sendPrompt([String text = ""]) async {
    _loadSettings();
    promptController.text = text;
    Map<String, dynamic> currentProfile = profiles.firstWhere(
      (profile) => profile['name'] == name,
      orElse: () => profiles.first,
    );

    final openAIService = GPTService(openAiToken);
    try {
      final responseText = await openAIService.getResponse(
          promptController.text, currentProfile);
      setState(() {
        openAiResponse = responseText;
      });
      await _playResponse(responseText);
    } catch (e) {
      setState(() {
        openAiResponse = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _playResponse(String text) async {
    final voiceService = VoiceService(elevenLabsToken, "7p1Ofvcwsv7UBPoFNcpI");
    try {
      Uint8List? audioData = await voiceService.textToSpeech(text);
      if (audioData != null) {
        String path = await _writeToFile(audioData);
        await audioPlayer.play(
          DeviceFileSource(path),
        );
      } else {
        throw Exception("No audio data received");
      }
    } catch (e) {
      setState(() {
        openAiResponse = 'Failed to play response: ${e.toString()}';
      });
    }
  }

  Future<String> _writeToFile(Uint8List data) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tempAudio.mp3');
    await file.writeAsBytes(data);
    return file.path;
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    openAiToken = prefs.getString('openAiToken') ?? '';
    elevenLabsToken = prefs.getString('elevenLabsToken') ?? '';
  }

  void _savePromptToPreferences(String newPrompt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('promptText_$name', newPrompt);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _editPrompt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditablePromptPage(
          currentPrompt: promptText,
          onSave: (newPrompt) {
            setState(() {
              promptText = newPrompt;
            });
            _savePromptToPreferences(newPrompt);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Toy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPrompt,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(imageUrl),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 20),
              Text(welcomeMessage),
              const SizedBox(height: 20),
              Text(promptText),
              const SizedBox(height: 20),
              Text(
                openAiResponse,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _chooseProfile,
        child: const Icon(Icons.account_circle),
      ),
    );
  }
}