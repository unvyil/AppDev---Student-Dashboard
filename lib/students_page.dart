import 'package:flutter/material.dart';

import 'registration_page.dart';
import 'services/storage_service.dart';
import 'widgets/ccs_program_stats_grid_widget.dart';
import 'widgets/student_card.dart';
import 'widgets/student_kpi_row_widget.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  int _selectedTabIndex = 0; // 0: Students, 1: Program Stats
  late Future<List<Student>> _studentsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStudents() {
    _studentsFuture = StorageService.getStudents();
  }

  Future<void> _refresh() async {
    setState(_loadStudents);
    await _studentsFuture;
  }

  void _openEditStudent(Student student) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrationPage(student: student),
      ),
    );
    _refresh();
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
                'Filter Students',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.people_outline, color: Color(0xFF800000)),
                title: const Text('All Tracks'),
                onTap: () {
                  setState(() => _searchQuery = '');
                  _searchController.clear();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF800000)),
                title: const Text('BSIT-NS (Network & Security)'),
                onTap: () {
                  setState(() => _searchQuery = 'BSIT-NS');
                  _searchController.text = 'BSIT-NS';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.devices, color: Color(0xFF800000)),
                title: const Text('BSIT-WM (Web & Mobile)'),
                onTap: () {
                  setState(() => _searchQuery = 'BSIT-WM');
                  _searchController.text = 'BSIT-WM';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.query_stats, color: Color(0xFF800000)),
                title: const Text('BSCS-DS (Data Science)'),
                onTap: () {
                  setState(() => _searchQuery = 'BSCS-DS');
                  _searchController.text = 'BSCS-DS';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Color(0xFF800000)),
                title: const Text('BSCS-SE (Software Engineering)'),
                onTap: () {
                  setState(() => _searchQuery = 'BSCS-SE');
                  _searchController.text = 'BSCS-SE';
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
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8EC),
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
                  color: _selectedTabIndex == 0 ? maroonColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Students',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 0 ? Colors.white : Colors.grey.shade700,
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
                  color: _selectedTabIndex == 1 ? maroonColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Program Stats',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 1 ? Colors.white : Colors.grey.shade700,
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
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.tune,
              color: Color(0xFF1E1E1E),
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
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q) ||
          s.program.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentKpiRowWidget(
          totalStudents: 428,
          activeStudents: 401,
          activeTrend: '+4%',
          avgAttendance: '93%',
        ),
        const SizedBox(height: 16),
        const Text(
          'Student List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 10),
        _buildSearchBar(),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No student records found',
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
          for (final student in filtered)
            StudentCard(
              student: student,
              onTap: () => _openEditStudent(student),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text('Error loading students: ${snapshot.error}'),
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
