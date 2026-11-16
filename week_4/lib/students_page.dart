import 'package:flutter/material.dart';

import 'registration_page.dart';
import 'services/storage_service.dart';
import 'services/portal_data_service.dart';
import 'widgets/ccs_program_stats_grid_widget.dart';
import 'widgets/student_card.dart';
import 'widgets/student_kpi_row_widget.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key, this.useMockData = false});

  final bool useMockData;

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  int _selectedTabIndex = 0; // 0: Students, 1: Program Stats
  late Future<List<Student>> _studentsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _courseFilter = 'All Students';

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  @override
  void didUpdateWidget(covariant StudentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.useMockData != widget.useMockData) {
      _studentsFuture = _loadStudents();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Student>> _loadStudents() async {
    // Records saved through registration.
    final savedStudents = await StorageService.getStudents();

    // Always retain the original Week 3 student records.
    final merged = <String, Student>{};

    for (final student in StorageService.defaultStudents) {
      merged[student.id] = student;
    }

    // Add records created by the user.
    for (final student in savedStudents) {
      merged[student.id] = student;
    }

    // When mock data is OFF, return Week 3 records and saved records only.
    if (!widget.useMockData) {
      return merged.values.toList();
    }

    // When mock data is ON, include additional demo/API records.
    for (final student in StorageService.getMockStudents()) {
      merged.putIfAbsent(student.id, () => student);
    }

    try {
      final users = await PortalDataService.fetchUsers();

      for (var index = 0; index < users.length; index++) {
        final student = PortalDataService.toStudent(users[index], index);
        merged.putIfAbsent(student.id, () => student);
      }
    } catch (_) {
      // Keep locally available records if the remote source fails.
    }

    return merged.values.toList();
  }

  Future<void> _openAddStudent() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationPage()),
    );
    if (mounted) await _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _studentsFuture = _loadStudents());
    await _studentsFuture;
  }

  Future<void> _openEditStudent(Student student) async {
    final custom = await StorageService.getStudents();
    if (!mounted) return;
    if (!custom.any((item) => item.id == student.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo records cannot be edited.')),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => RegistrationPage(student: student)),
    );
    if (mounted) await _refresh();
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Remove ${student.name} from saved student records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final custom = await StorageService.getStudents();
    if (!custom.any((item) => item.id == student.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo records cannot be deleted.')),
        );
      }
      return;
    }
    await StorageService.deleteStudent(student.id);
    if (!mounted) return;
    await _refresh();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${student.name} was deleted.')));
    }
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
                'Filter by course',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (final course in const [
                'All Students',
                'BSIT',
                'BSCS',
                'BSIS',
              ])
                ListTile(
                  leading: Icon(
                    course == 'All Students'
                        ? Icons.people_outline
                        : Icons.school_outlined,
                    color: const Color(0xFF800000),
                  ),
                  title: Text(course),
                  selected: _courseFilter == course,
                  onTap: () {
                    setState(() => _courseFilter = course);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedToggle() {
    const maroonColor = Color(0xFF800000);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toggleBg = isDark ? const Color(0xFF262626) : const Color(0xFFE8E8EC);
    final selectedColor = isDark ? const Color(0xFFE0B0B0) : maroonColor;
    final inactiveTextColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: toggleBg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? selectedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Students',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 0
                        ? (isDark ? const Color(0xFF171717) : Colors.white)
                        : inactiveTextColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? selectedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Program Stats',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 1
                        ? (isDark ? const Color(0xFF171717) : Colors.white)
                        : inactiveTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    return Row(
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
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildStudentsView(List<Student> students) {
    final filtered = students.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q) ||
          s.course.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q);
      final course = s.course.toUpperCase();
      final matchesCourse = switch (_courseFilter) {
        'BSIT' => course.startsWith('BSIT'),
        'BSCS' => course.startsWith('BSCS'),
        'BSIS' => course.startsWith('BSIS'),
        _ => true,
      };
      return matchesSearch && matchesCourse;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentKpiRowWidget(
          totalStudents: students.length,
          activeStudents: students
              .where((student) => student.status.toLowerCase() == 'active')
              .length,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Student List',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _openAddStudent,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Add Student'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildSearchBar(),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final course in const ['All Students', 'BSIT', 'BSCS', 'BSIS'])
              ChoiceChip(
                label: Text(course),
                selected: _courseFilter == course,
                onSelected: (_) => setState(() => _courseFilter = course),
                selectedColor: const Color(0xFFF9EAEA),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No student records found',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final student = filtered[index];
              return StudentCard(
                student: student,
                onTap: () => _openEditStudent(student),
                onDelete: () => _deleteStudent(student),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSegmentedToggle(),
                const SizedBox(height: 16),
                if (_selectedTabIndex == 1)
                  CcsProgramStatsGridWidget(
                    onProgramSelected: (programCode) {
                      setState(() {
                        _selectedTabIndex = 0;
                        _searchQuery = programCode;
                        _searchController.text = programCode;
                      });
                    },
                  )
                else
                  FutureBuilder<List<Student>>(
                    future: _studentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            'Error loading students: ${snapshot.error}',
                          ),
                        );
                      }
                      final students = snapshot.data ?? [];
                      return _buildStudentsView(students);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
