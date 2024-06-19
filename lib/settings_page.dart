import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedOutputDevice = 'Default Speaker';
  TextEditingController openAiTokenController = TextEditingController();
  TextEditingController elevenLabsTokenController = TextEditingController();
  TextEditingController voiceIdController = TextEditingController();
  TextEditingController porcupineAccessKeyController = TextEditingController();

  List<String> outputDevices = [];
  static const platform = MethodChannel('bluetooth_plugin');

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getPairedDevices();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? openAiToken = prefs.getString('openAiToken');
    String? elevenLabsToken = prefs.getString('elevenLabsToken');
    String? selectedOutputDevice = prefs.getString('selectedOutputDevice');
    String? voiceId = prefs.getString('voiceId');
    String? porcupineAccessKey = prefs.getString('porcupineAccessKey');

    setState(() {
      openAiTokenController.text = openAiToken ?? '';
      elevenLabsTokenController.text = elevenLabsToken ?? '';
      this.selectedOutputDevice = selectedOutputDevice ?? 'Default Speaker';
      voiceIdController.text = voiceId ?? '';
      porcupineAccessKeyController.text = porcupineAccessKey ?? '';
    });
  }

  Future<void> _getPairedDevices() async {
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('getPairedDevices');
      setState(() {
        outputDevices = result.keys.cast<String>().toSet().toList();
        if (!outputDevices.contains(selectedOutputDevice)) {
          selectedOutputDevice = outputDevices.isNotEmpty
              ? outputDevices.first
              : 'Default Speaker';
        }
      });
    } on PlatformException catch (e) {
      print("Failed to get paired devices: '${e.message}'.");
    }
  }

  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('openAiToken', openAiTokenController.text);
    await prefs.setString('elevenLabsToken', elevenLabsTokenController.text);
    await prefs.setString('selectedOutputDevice', selectedOutputDevice);
    await prefs.setString('voiceId', voiceIdController.text);
    await prefs.setString(
        'porcupineAccessKey', porcupineAccessKeyController.text);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Output Sound Device', style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: selectedOutputDevice,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedOutputDevice = newValue!;
                  });
                },
                items:
                    outputDevices.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: voiceIdController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Voice ID',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: openAiTokenController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'OpenAI Token',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: elevenLabsTokenController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Eleven Labs Token',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: porcupineAccessKeyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Porcupine Access Key',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}