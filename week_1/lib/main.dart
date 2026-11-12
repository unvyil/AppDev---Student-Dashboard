import 'package:flutter/material.dart';

void main() => runApp(const PortalApp());

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LPU Student Portal · Week 1',
    debugShowCheckedModeBanner: false,
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
  String student = 'Juan Dela Cruz';
  String studentProgram = 'BSIT-WM';
  int tab = 0;
  @override
  void dispose() { name.dispose(); program.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pages = [_overview(), _input(), _profile()];
    return Scaffold(
      appBar: AppBar(title: const Text('LPU Student Portal'),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF800000)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 364), child: pages[tab]))),
      bottomNavigationBar: NavigationBar(selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.edit_outlined), label: 'Input'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ]),
    );
  }

  Widget _overview() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Student Overview', style: TextStyle(fontSize: 22,
      fontWeight: FontWeight.w700, color: Color(0xFF800000))),
    const SizedBox(height: 14),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Student profile', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 8), Text(student, style: const TextStyle(
        fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4), Text(studentProgram,
        style: const TextStyle(color: Color(0xFF800000), fontWeight: FontWeight.w600)),
    ])),
    const SizedBox(height: 12),
    _card(const Text('Welcome to your student portal overview.')),
  ]);

  Widget _input() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Student data input', style: TextStyle(fontSize: 22,
      fontWeight: FontWeight.w700, color: Color(0xFF800000))),
    const SizedBox(height: 16),
    TextField(controller: name, decoration: const InputDecoration(
      labelText: 'Student name', border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: program, decoration: const InputDecoration(
      labelText: 'Programme', border: OutlineInputBorder())),
    const SizedBox(height: 16),
    FilledButton(onPressed: () {
      if (name.text.trim().isEmpty) return;
      setState(() { student = name.text.trim(); studentProgram = program.text.trim(); tab = 0; });
    }, child: const Text('Save profile')),
  ]);

  Widget _profile() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Student Profile', style: TextStyle(fontSize: 22,
      fontWeight: FontWeight.w700, color: Color(0xFF800000))),
    const SizedBox(height: 14),
    _card(Column(children: [const CircleAvatar(radius: 34,
      child: Icon(Icons.person, size: 38)), const SizedBox(height: 12),
      Text(student, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      Text(studentProgram)])),
  ]);

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06),
        blurRadius: 12, offset: const Offset(0, 3))]), child: child);
}
