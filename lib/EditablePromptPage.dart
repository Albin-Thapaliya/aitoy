import 'package:flutter/material.dart';

class EditablePromptPage extends StatefulWidget {
  final String currentPrompt;
  final Function(String) onSave;

  const EditablePromptPage(
      {required this.currentPrompt, required this.onSave, Key? key})
      : super(key: key);

  @override
  _EditablePromptPageState createState() => _EditablePromptPageState();
}

class _EditablePromptPageState extends State<EditablePromptPage> {
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.currentPrompt);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _savePrompt() {
    widget.onSave(_promptController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Prompt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Prompt',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePrompt,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}