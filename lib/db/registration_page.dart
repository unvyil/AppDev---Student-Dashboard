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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.person_add_alt_1,
              size: 52,
              color: Color(0xFF800000),
            ),
            const SizedBox(height: 12),
            const Text(
              'Register a Student',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the student information below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
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
              decoration: const InputDecoration(
                labelText: 'Program',
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
              decoration: const InputDecoration(
                labelText: 'Year Level',
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
            ),
            _textField(
              'Address (Optional)',
              _addressController,
              icon: Icons.home_outlined,
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
