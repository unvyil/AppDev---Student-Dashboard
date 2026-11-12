import 'package:flutter/material.dart';

class FacultyPage extends StatelessWidget {
  const FacultyPage({super.key});

  static const _faculty = [
    (
      'Faculty Name',
      'faculty@example.edu',
      'College of Computer Studies',
      '+63 000 000 0000',
    ),
    (
      'Faculty Name',
      'faculty2@example.edu',
      'College of Business Administration',
      '+63 000 000 0000',
    ),
    (
      'Faculty Name',
      'faculty3@example.edu',
      'College of Arts and Sciences',
      '+63 000 000 0000',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Faculty Directory',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Sample directory cards. Replace with verified faculty details.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        for (final faculty in _faculty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFEFE1E1),
                        child: Icon(
                          Icons.person_outline,
                          color: Color(0xFF800000),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          faculty.$1,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detail(Icons.email_outlined, faculty.$2),
                  _detail(Icons.school_outlined, faculty.$3),
                  _detail(Icons.phone_outlined, faculty.$4),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _detail(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
