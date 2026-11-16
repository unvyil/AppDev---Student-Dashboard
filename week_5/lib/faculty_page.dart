import 'package:flutter/material.dart';

import 'services/portal_data_service.dart';
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
  const FacultyPage({super.key, this.useMockData = false});

  final bool useMockData;

  @override
  State<FacultyPage> createState() => _FacultyPageState();
}

class _FacultyPageState extends State<FacultyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<FacultyMember>> _facultyFuture;

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
  void initState() {
    super.initState();
    _facultyFuture = _loadFaculty();
  }

  @override
  void didUpdateWidget(covariant FacultyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useMockData != widget.useMockData) {
      setState(() {
        _facultyFuture = _loadFaculty();
      });
    }
  }

  Future<List<FacultyMember>> _loadFaculty() async {
    if (!widget.useMockData) return _defaultFaculty;
    final users = await PortalDataService.fetchUsers();
    return users.map((user) {
      return FacultyMember(
        name: user['name'] as String? ?? 'Faculty member',
        department: user['company'] is Map
            ? (user['company'] as Map)['name'] as String? ?? 'Academic Affairs'
            : 'Academic Affairs',
        email: user['email'] as String? ?? '',
        phone: user['phone'] as String? ?? '',
        initials: (user['name'] as String? ?? 'F')
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join(),
      );
    }).toList();
  }

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
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<FacultyMember>>(
          future: _facultyFuture,
          builder: (context, snapshot) {
            final source =
                snapshot.data ??
                (widget.useMockData ? <FacultyMember>[] : _defaultFaculty);
            final filtered = source.where((f) {
              if (_searchQuery.isEmpty) return true;
              final q = _searchQuery.toLowerCase();
              return f.name.toLowerCase().contains(q) ||
                  f.department.toLowerCase().contains(q) ||
                  f.email.toLowerCase().contains(q);
            }).toList();
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Could not load faculty mock data: ${snapshot.error}',
                    ),
                  ),
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search faculty...',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          Icon(
                            Icons.search_off,
                            size: 40,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No faculty members found',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                          SnackBar(
                            content: Text(
                              'Composing email to ${faculty.email}',
                            ),
                          ),
                        );
                      },
                      onCallTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${faculty.phone}')),
                        );
                      },
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
