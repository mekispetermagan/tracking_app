import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';
import '../widgets/buttons.dart';

class AdminStoryEditScreen extends StatefulWidget {
  final AdminStory story;
  final bool isSaving;
  final String? message;

  final VoidCallback clearMessage;
  final Future<bool> Function(String text) onSave;

  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const AdminStoryEditScreen({
    required this.story,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onSave,
    required this.onSaved,
    required this.onCancel,
    super.key,
  });

  @override
  State<AdminStoryEditScreen> createState() => _AdminStoryEditScreenState();
}

class _AdminStoryEditScreenState extends State<AdminStoryEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.story.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(widget.message!)));

        widget.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppTopBar(
        title: const Text('Edit story'),
        showBack: true,
        onBack: widget.isSaving ? null : widget.onCancel,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.story.submitterName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(widget.story.courseName),
              const SizedBox(height: 24),
              TextFormField(
                controller: _textController,
                enabled: !widget.isSaving,
                minLines: 8,
                maxLines: 16,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Story text is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              LargeFilledButton(
                onPressed: widget.isSaving ? null : _save,
                child: Text(widget.isSaving ? 'Saving...' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saved = await widget.onSave(_textController.text.trim());

    if (saved && mounted) {
      widget.onSaved();
    }
  }
}
