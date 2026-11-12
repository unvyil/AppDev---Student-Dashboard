import 'package:flutter/material.dart';

import 'services/storage_service.dart';
import 'summary_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, this.student});

  final Student? student;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  String? _program;
  String? _yearLevel;
  bool _saving = false;

  final List<String> _programs = [
    'BSIT-NS',
    'BSIT-WM',
    'BSCS-DS',
    'BSCS-SE',
    'BS Information Technology',
    'BS Computer Science',
    'BS Business Administration',
    'BS Hospitality Management',
  ];

  final List<String> _yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    if (student == null) return;
    _nameController.text = student.name;
    _idController.text = student.id;
    _emailController.text = student.email;
    _contactController.text = student.contact;
    _addressController.text = student.address;
    if (_programs.contains(student.program)) _program = student.program;
    if (_yearLevels.contains(student.yearLevel)) _yearLevel = student.yearLevel;
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_program == null || _yearLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a program and year level.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final student = Student(
      name: _nameController.text.trim(),
      id: _idController.text.trim(),
      email: _emailController.text.trim(),
      program: _program!,
      yearLevel: _yearLevel!,
      contact: _contactController.text.trim(),
      address: _addressController.text.trim(),
    );

    try {
      if (widget.student == null) {
        await StorageService.saveStudent(student);
      } else {
        await StorageService.updateStudent(widget.student!.id, student);
      }

      if (!mounted) return;

      if (widget.student != null) {
        Navigator.pop(context);
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SummaryPage(student: student, isUpdate: false),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? icon,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          label: _fieldLabel(label, isRequired),
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, [bool isRequired = true]) => RichText(
    text: TextSpan(
      style: Theme.of(context).textTheme.bodyMedium,
      children: [
        TextSpan(text: label),
        if (isRequired)
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Color(0xFFD32F2F)),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.student == null ? 'Student Registration' : 'Edit Profile',
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              widget.student == null ? 'Student details' : 'Edit student details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              'Fields marked with * are required. Contact number and address are optional.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            _textField(
              'Student Name',
              _nameController,
              icon: Icons.person_outline,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the student name'
                  : null,
            ),
            _textField(
              'Student ID',
              _idController,
              icon: Icons.badge_outlined,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the student ID'
                  : null,
            ),
            _textField(
              'Email Address',
              _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the email address';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),

            DropdownButtonFormField<String>(
              initialValue: _program,
              isExpanded: true,
              validator: (value) => value == null ? 'Select a program' : null,
              decoration: InputDecoration(
                label: _fieldLabel('Program'),
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: _programs
                  .map(
                    (program) =>
                        DropdownMenuItem(value: program, child: Text(program)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _program = value),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _yearLevel,
              validator: (value) => value == null ? 'Select a year level' : null,
              decoration: InputDecoration(
                label: _fieldLabel('Year level'),
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: _yearLevels
                  .map(
                    (year) => DropdownMenuItem(value: year, child: Text(year)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _yearLevel = value),
            ),
            const SizedBox(height: 16),

            _textField(
              'Contact Number (Optional)',
              _contactController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isRequired: false,
            ),
            _textField(
              'Address (Optional)',
              _addressController,
              icon: Icons.home_outlined,
              isRequired: false,
            ),

            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _saveStudent,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _saving
                    ? 'Saving...'
                    : widget.student == null
                    ? 'Save Student'
                    : 'Update Student',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
