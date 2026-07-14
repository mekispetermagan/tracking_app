import 'package:flutter/material.dart';

import '../models/models.dart';

class MentorProfileScreen extends StatefulWidget {
  final Mentor? mentor;
  final String? countryName;
  final List<String> courseNames;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final Future<bool> Function(MentorSelfUpdateRequest request) onSave;
  final VoidCallback onChangePin;
  final VoidCallback onReload;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const MentorProfileScreen({
    required this.mentor,
    required this.countryName,
    required this.courseNames,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onSave,
    required this.onChangePin,
    required this.onReload,
    required this.onHome,
    required this.onLogout,
    super.key,
  });

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();

    _setMentor(widget.mentor);
  }

  @override
  void didUpdateWidget(covariant MentorProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mentor != widget.mentor) {
      _setMentor(widget.mentor);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(widget.message!)));

        widget.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        leading: BackButton(onPressed: widget.onHome),
        actions: [
          TextButton(onPressed: widget.onLogout, child: const Text('Logout')),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading && widget.mentor == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final mentor = widget.mentor;

    if (mentor == null) {
      return Center(
        child: FilledButton(
          onPressed: widget.onReload,
          child: const Text('Retry'),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('First name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _firstNameController,
            enabled: !widget.isSaving,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 20),

          const Text('Last name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastNameController,
            enabled: !widget.isSaving,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 20),

          const Text('Phone'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            enabled: !widget.isSaving,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: _required,
          ),
          const SizedBox(height: 32),

          Text(
            'Account information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          _ReadOnlyValue(
            label: 'Country',
            value: widget.countryName ?? 'Not set',
          ),
          const SizedBox(height: 12),

          _ReadOnlyValue(
            label: 'Status',
            value: mentor.active ? 'Active' : 'Inactive',
          ),
          const SizedBox(height: 12),

          const Text('Assigned courses'),
          const SizedBox(height: 8),

          if (widget.courseNames.isEmpty)
            const Text('No assigned courses')
          else
            ...widget.courseNames.map(
              (courseName) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.school_outlined),
                title: Text(courseName),
              ),
            ),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: widget.isSaving ? null : _submit,
            child: Text(widget.isSaving ? 'Saving...' : 'Save changes'),
          ),
          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: widget.isSaving ? null : widget.onChangePin,
            child: const Text('Change PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onSave(
      MentorSelfUpdateRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  void _setMentor(Mentor? mentor) {
    _firstNameController.text = mentor?.firstName ?? '';
    _lastNameController.text = mentor?.lastName ?? '';
    _phoneController.text = mentor?.phone ?? '';
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }
}

class _ReadOnlyValue extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(value),
    );
  }
}
