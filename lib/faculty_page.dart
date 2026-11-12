import 'package:flutter/material.dart';

import 'widgets/faculty_card.dart';

class FacultyMember {
  final String name;
  final String department;
  final String email;
  final String phone;
  final String initials;

  const FacultyMember({
    required this.name,
    required this.department,
    required this.email,
    required this.phone,
    this.initials = 'J',
  });
}

class FacultyPage extends StatefulWidget {
  const FacultyPage({super.key});

  @override
  State<FacultyPage> createState() => _FacultyPageState();
}

class _FacultyPageState extends State<FacultyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<FacultyMember> _defaultFaculty = [
    FacultyMember(
      name: 'Dr. Jane Doe',
      department:
          'College of Information Technology and Computer Science (CCS)',
      email: '2024-2-00294@lpunetwork.edu.ph',
      phone: '+63 234 508 2435',
      initials: 'J',
    ),
    FacultyMember(
      name: 'Dr. Jane Doe',
      department:
          'College of Information Technology and Computer Science (CCS)',
      email: '2024-2-00294@lpunetwork.edu.ph',
      phone: '+63 234 508 2435',
      initials: 'J',
    ),
    FacultyMember(
      name: 'Dr. Jane Doe',
      department:
          'College of Information Technology and Computer Science (CCS)',
      email: '2024-2-00294@lpunetwork.edu.ph',
      phone: '+63 234 508 2435',
      initials: 'J',
    ),
    FacultyMember(
      name: 'Dr. Jane Doe',
      department:
          'College of Information Technology and Computer Science (CCS)',
      email: '2024-2-00294@lpunetwork.edu.ph',
      phone: '+63 234 508 2435',
      initials: 'J',
    ),
    FacultyMember(
      name: 'Dr. Jane Doe',
      department:
          'College of Information Technology and Computer Science (CCS)',
      email: '2024-2-00294@lpunetwork.edu.ph',
      phone: '+63 234 508 2435',
      initials: 'J',
    ),
    FacultyMember(
      name: 'Dr. Jane Doe',
      department:
          'College of Information Technology and Computer Science (CCS)',
      email: '2024-2-00294@lpunetwork.edu.ph',
      phone: '+63 234 508 2435',
      initials: 'J',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Faculty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.school, color: Color(0xFF800000)),
                title: const Text('All Departments'),
                onTap: () {
                  setState(() => _searchQuery = '');
                  _searchController.clear();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.computer, color: Color(0xFF800000)),
                title: const Text('Computer Studies (CCS)'),
                onTap: () {
                  setState(() => _searchQuery = 'CCS');
                  _searchController.text = 'CCS';
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _defaultFaculty.where((f) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return f.name.toLowerCase().contains(q) ||
          f.department.toLowerCase().contains(q) ||
          f.email.toLowerCase().contains(q);
    }).toList();

    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Search Bar with Filter Icon
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search faculty...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: isDark ? Colors.white70 : const Color(0xFF1E1E1E),
                      size: 20,
                    ),
                    onPressed: _showFilterSheet,
                    tooltip: 'Filter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No faculty members found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final faculty in filtered)
                FacultyCard(
                  name: faculty.name,
                  department: faculty.department,
                  email: faculty.email,
                  phone: faculty.phone,
                  initials: faculty.initials,
                  onEmailTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Composing email to ${faculty.email}')),
                    );
                  },
                  onCallTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${faculty.phone}')),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
