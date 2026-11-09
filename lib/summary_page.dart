import 'package:flutter/material.dart';

import 'services/storage_service.dart';
import 'services/file_service.dart';

class SummaryPage extends StatelessWidget {
  final Student student;
  final bool isUpdate;

  const SummaryPage({super.key, required this.student, this.isUpdate = false});

  Widget _detail(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      subtitle: Text(
        value.isEmpty ? 'Not provided' : value,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final file = await FileService.exportStudents();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 42),
          title: const Text('Export Successful'),
          content: SelectableText(
            'Student information was exported to:\n\n${file.path}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Summary')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFEFE1E1),
            child: Icon(Icons.person, size: 48, color: Color(0xFF800000)),
          ),
          const SizedBox(height: 16),
          Text(
            isUpdate ? 'Profile Updated' : 'Registration Complete',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            isUpdate
                ? 'Your student profile has been updated on this device.'
                : 'The student information has been saved on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Details',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  _detail('Student Name', student.name),
                  _detail('Student ID', student.id),
                  _detail('Email', student.email),
                  _detail('Program', student.program),
                  _detail('Year Level', student.yearLevel),
                  _detail('Contact Number', student.contact),
                  _detail('Address', student.address),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Export Student Information'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Registration'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
