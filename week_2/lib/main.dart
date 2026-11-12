import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const PortalApp());

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LPU Student Portal · Week 2', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF2F2F2),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF800000))),
    home: const PortalHome(),
  );
}

class PortalHome extends StatefulWidget {
  const PortalHome({super.key});
  @override
  State<PortalHome> createState() => _PortalHomeState();
}

class _PortalHomeState extends State<PortalHome> {
  final name = TextEditingController(text: 'Juan Dela Cruz');
  final program = TextEditingController(text: 'BSIT-WM');
  int tab = 0;
  String student = 'Juan Dela Cruz';
  String studentProgram = 'BSIT-WM';
  late Future<List<Map<String, dynamic>>> users;
  final faculty = const ['Dr. Maria Santos · Computer Science', 'Prof. Jose Reyes · Information Technology', 'Engr. Ana Garcia · Software Engineering'];
  final tracks = const [
    ('BSIT-NS', 'Network & Security', 120, Color(0xFF0096C7)),
    ('BSIT-WM', 'Web & Mobile Development', 150, Color(0xFF7B2CBF)),
    ('BSCS-DS', 'Data Science', 100, Color(0xFFE85D04)),
    ('BSCS-SE', 'Software Engineering', 90, Color(0xFF2563EB)),
  ];
  @override
  void initState() { super.initState(); users = _fetchUsers(); }
  @override
  void dispose() { name.dispose(); program.dispose(); super.dispose(); }
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Could not load directory');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_overview(), _input(), _directory(), _faculty(), _programs()];
    return Scaffold(appBar: AppBar(title: const Text('LPU Student Portal'),
      backgroundColor: Colors.white, foregroundColor: const Color(0xFF800000)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 364), child: pages[tab]))),
      bottomNavigationBar: NavigationBar(selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.edit_outlined), label: 'Input'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Faculty'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Tracks'),
        ]));
  }

  Widget _overview() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Student Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF800000))),
    const SizedBox(height: 14), _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Student profile', style: TextStyle(color: Colors.black54)), const SizedBox(height: 8),
      Text(student, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), Text(studentProgram),
    ])), const SizedBox(height: 14), const Text('CCS Enrolment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), ...tracks.map((t) => _trackCard(t)),
  ]);
  Widget _input() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Student data input', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF800000))),
    const SizedBox(height: 16), TextField(controller: name, decoration: const InputDecoration(labelText: 'Student name', border: OutlineInputBorder())),
    const SizedBox(height: 12), TextField(controller: program, decoration: const InputDecoration(labelText: 'Programme', border: OutlineInputBorder())),
    const SizedBox(height: 16), FilledButton(onPressed: () { if (name.text.trim().isEmpty) return; setState(() { student = name.text.trim(); studentProgram = program.text.trim(); tab = 0; }); }, child: const Text('Save profile')),
  ]);
  Widget _directory() => FutureBuilder<List<Map<String, dynamic>>>(future: users, builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_outlined, size: 36),
        const SizedBox(height: 8),
        const Text('Student directory unavailable. Check your connection and try again.', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () => setState(() => users = _fetchUsers()), icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    ));
    final rows = snapshot.data!;
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Student Directory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF800000))));
        final user = rows[i - 1];
        return _card(ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text(user['name'].toString()[0])), title: Text(user['name']), subtitle: Text(user['email']), isThreeLine: false));
      });
  });
  Widget _faculty() => ListView.builder(padding: const EdgeInsets.all(16), itemCount: faculty.length + 1,
    itemBuilder: (context, i) => i == 0
      ? const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Faculty Directory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF800000))))
      : _card(ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(faculty[i - 1]), subtitle: const Text('College of Computer Studies'))));
  Widget _programs() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('CCS Programmes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF800000))),
    const SizedBox(height: 12), ...tracks.map(_trackCard),
  ]);
  Widget _trackCard((String, String, int, Color) t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _card(ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: t.$4, child: const Icon(Icons.school, color: Colors.white)), title: Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(t.$2), trailing: Text('${t.$3}', style: TextStyle(color: t.$4, fontWeight: FontWeight.w700)))));
  Widget _card(Widget child) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 10)]), child: child);
}
