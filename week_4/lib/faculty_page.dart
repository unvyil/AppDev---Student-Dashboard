import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/portal_data_service.dart';
import 'widgets/faculty_card.dart';

class FacultyMember {
  final String name;
  final String department;
  final String email;
  final String phone;
  final String initials;
  final bool isCustom;

  const FacultyMember({
    required this.name,
    required this.department,
    required this.email,
    required this.phone,
    this.initials = 'J',
    this.isCustom = false,
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

  static const String _customFacultyKey = 'lpu_custom_faculty';

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
      _facultyFuture = _loadFaculty();
    }
  }

  Future<List<FacultyMember>> _getCustomFaculty() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customFacultyKey);

    if (raw == null || raw.isEmpty) {
      return <FacultyMember>[];
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException('Faculty data must be a JSON list.');
    }

    return decoded.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      final name = data['name'] as String? ?? '';

      return FacultyMember(
        name: name,
        department: data['department'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        initials: name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join(),
        isCustom: true,
      );
    }).toList();
  }

  Future<void> _saveCustomFaculty(List<FacultyMember> faculty) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _customFacultyKey,
      jsonEncode(
        faculty.map((member) {
          return {
            'name': member.name,
            'department': member.department,
            'email': member.email,
            'phone': member.phone,
          };
        }).toList(),
      ),
    );
  }

  Future<void> _showFacultyForm({FacultyMember? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final department = TextEditingController(text: existing?.department ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');

    final formKey = GlobalKey<FormState>();

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(existing == null ? 'Add Faculty' : 'Edit Faculty'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in <(String, TextEditingController)>[
                    ('Full name', name),
                    ('Department', department),
                    ('Email', email),
                    ('Phone', phone),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: entry.$2,
                        decoration: InputDecoration(
                          labelText: entry.$1,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (saved != true) return;

      final custom = await _getCustomFaculty();

      final updated = FacultyMember(
        name: name.text.trim(),
        department: department.text.trim(),
        email: email.text.trim(),
        phone: phone.text.trim(),
        initials: name.text
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join(),
        isCustom: true,
      );

      if (existing == null) {
        if (custom.any(
          (item) => item.email.toLowerCase() == updated.email.toLowerCase(),
        )) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A faculty member with this email already exists.',
                ),
              ),
            );
          }
          return;
        }

        custom.add(updated);
      } else {
        final index = custom.indexWhere((item) => item.email == existing.email);

        if (index >= 0) {
          custom[index] = updated;
        }
      }

      await _saveCustomFaculty(custom);

      if (mounted) {
        setState(() {
          _facultyFuture = _loadFaculty();
        });
      }
    } finally {
      name.dispose();
      department.dispose();
      email.dispose();
      phone.dispose();
    }
  }

  Future<void> _showFacultyActions(FacultyMember faculty) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit faculty'),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFF800000),
              ),
              title: const Text('Delete faculty'),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      await _showFacultyForm(existing: faculty);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete faculty?'),
          content: Text('Remove ${faculty.name} from saved faculty records?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final custom = await _getCustomFaculty();

        custom.removeWhere((item) => item.email == faculty.email);

        await _saveCustomFaculty(custom);

        if (mounted) {
          setState(() {
            _facultyFuture = _loadFaculty();
          });
        }
      }
    }
  }

  Future<List<FacultyMember>> _loadFaculty() async {
    final custom = await _getCustomFaculty();

    // Mock data OFF: only show faculty members saved by the user.
    if (!widget.useMockData) {
      return custom;
    }

    final byEmail = <String, FacultyMember>{};

    for (final member in _defaultFaculty) {
      byEmail.putIfAbsent(member.email.toLowerCase(), () => member);
    }

    try {
      final users = await PortalDataService.fetchUsers();

      for (final user in users) {
        final name = user['name'] as String? ?? 'Faculty member';

        final member = FacultyMember(
          name: name,
          department: user['company'] is Map
              ? (user['company'] as Map)['name'] as String? ??
                    'Academic Affairs'
              : 'Academic Affairs',
          email: user['email'] as String? ?? '',
          phone: user['phone'] as String? ?? '',
          initials: name
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join(),
        );

        byEmail.putIfAbsent(member.email.toLowerCase(), () => member);
      }
    } catch (_) {
      // Retain bundled faculty records if the remote service is unavailable.
    }

    for (final member in custom) {
      byEmail[member.email.toLowerCase()] = member;
    }

    return byEmail.values.toList();
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
            // Do not fall back to demo records when mock data is disabled.
            final source = snapshot.data ?? <FacultyMember>[];

            final filtered = source.where((faculty) {
              if (_searchQuery.isEmpty) return true;

              final query = _searchQuery.toLowerCase();

              return faculty.name.toLowerCase().contains(query) ||
                  faculty.department.toLowerCase().contains(query) ||
                  faculty.email.toLowerCase().contains(query);
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
                      'Could not load faculty records: ${snapshot.error}',
                    ),
                  ),

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
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.trim();
                            });
                          },
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
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: IconButton(
                        tooltip: 'Add faculty',
                        onPressed: () => _showFacultyForm(),
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: Color(0xFF800000),
                        ),
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
                      onManageTap: faculty.isCustom
                          ? () => _showFacultyActions(faculty)
                          : null,
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
