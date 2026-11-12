import 'package:flutter/material.dart';

import 'services/storage_service.dart';
import 'widgets/profile_avatar.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  int _selectedCategory = 0;
  late Future<List<Student>> _studentsFuture;

  static const _tracks = [
    ('BSIT-NS', 'Network & Security', Icons.security_outlined),
    ('BSIT-WM', 'Web & Mobile Development', Icons.devices_outlined),
    ('BSCS-DS', 'Data Science', Icons.query_stats_outlined),
    ('BSCS-SE', 'Software Engineering', Icons.code_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _studentsFuture = StorageService.getStudents();
  }

  Future<void> _refresh() async {
    setState(() => _studentsFuture = StorageService.getStudents());
    await _studentsFuture;
  }

  int _columns(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 4 : 2;

  Widget _pill(String label, {Color color = const Color(0xFFDBFF49)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _metricGrid() {
    const metrics = [
      ('Total students', '428', '↑ 4%', Icons.groups_outlined),
      ('Active students', '401', '↓ 7%', Icons.verified_user_outlined),
      ('On leave', '12', 'Current', Icons.event_busy_outlined),
      ('Avg attendance', '93%', 'Sample', Icons.fact_check_outlined),
    ];
    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns(context),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(metric.$4, color: const Color(0xFF800000), size: 20),
                    const Spacer(),
                    _pill(metric.$3),
                  ],
                ),
                Text(
                  metric.$2,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  metric.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _trackEnrollment(List<Student> students, String code) => students
      .where((student) => student.program.toUpperCase().contains(code))
      .length;

  Widget _programGrid(List<Student> students) {
    return GridView.builder(
      itemCount: _tracks.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns(context),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 170,
      ),
      itemBuilder: (context, index) {
        final track = _tracks[index];
        final enrollment = _trackEnrollment(students, track.$1);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(track.$3, color: const Color(0xFF800000)),
                    const Spacer(),
                    _pill('$enrollment enrolled'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  track.$1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Text(
                    track.$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const LinearProgressIndicator(
                  value: 0.93,
                  minHeight: 5,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  color: Color(0xFF800000),
                  backgroundColor: Color(0xFFEAECEF),
                ),
                const SizedBox(height: 5),
                Text(
                  '93% sample performance',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _studentCard(Student student, int index) {
    final nameParts = student.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = nameParts.length > 1
        ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
        : nameParts.isEmpty
        ? 'NT'
        : nameParts.first[0].toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  bytes: null,
                  initials: initials,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        student.id,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _pill('Active'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: Color(0xFF800000),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    student.program,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Text(
                  '93%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const LinearProgressIndicator(
              value: 0.93,
              minHeight: 5,
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: Color(0xFF800000),
              backgroundColor: Color(0xFFEAECEF),
            ),
            const SizedBox(height: 4),
            Text(
              'Sample attendance metric · record ${index + 1}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(List<Student> students) {
    if (_selectedCategory == 1) return _programGrid(students);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricGrid(),
        const SizedBox(height: 18),
        const Text(
          'Registered students',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Attendance figures are illustrative sample metrics.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (students.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.people_outline, color: Color(0xFF800000)),
              title: Text('No registered student records'),
              subtitle: Text('Student records you add will appear here.'),
            ),
          )
        else
          for (var index = 0; index < students.length; index++)
            _studentCard(students[index], index),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Students',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Student and CCS programme overview',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.groups_outlined),
                label: Text('Student Stats'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.school_outlined),
                label: Text('Program Stats'),
              ),
            ],
            selected: {_selectedCategory},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() => _selectedCategory = selection.first);
            },
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Student>>(
            future: _studentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: const Text('Unable to load student records'),
                    subtitle: Text('${snapshot.error}'),
                    trailing: IconButton(
                      tooltip: 'Retry',
                      onPressed: () =>
                          setState(() => _studentsFuture = StorageService.getStudents()),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                );
              }
              return _content(snapshot.data ?? const []);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
