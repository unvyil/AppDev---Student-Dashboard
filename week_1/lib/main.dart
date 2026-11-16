import 'package:flutter/material.dart';

void main() => runApp(const PortalApp());

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'LPU Smart Campus Dashboard · Week 1',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
          cardColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF800000),
            primary: const Color(0xFF800000),
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF800000),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: Color(0xFFF9EAEA),
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
  void dispose() {
    name.dispose();
    program.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _studentForm(), _facultyPlaceholder(), _settings()];
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.school_outlined),
        title: const Text('LPU Smart Campus Dashboard'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 364),
            child: pages[tab],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Faculty',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _home() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Home',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF800000),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Welcome to your LPU Smart Campus dashboard.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      _buildProfileCard(),
      const SizedBox(height: 24),
      _sectionTitle('KPI Cards'),
      _maintenanceSection(
        'KPI Cards coming soon. \n'
            '(Network, GPS, API, and storage metrics)',
      ),
      const SizedBox(height: 8),
      _sectionTitle('Quick Actions'),
      _maintenanceSection(
        'Quick Actions coming soon. \n'
            '(Device, API, GPS, and Network shortcuts)',
      ),
      const SizedBox(height: 8),
      _sectionTitle('Recent Activity'),
      _maintenanceSection(
        'No recent activity.',
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _buildProfileCard() {
    final theme = Theme.of(context);
    final initials = student
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF800000),
                child: Text(
                  initials.isEmpty ? 'S' : initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studentProgram,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF800000),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LPU Cavite · Android device',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => tab = 1),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF800000),
                side: const BorderSide(color: Color(0xFF800000)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      );

  Widget _maintenanceSection(String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Text(
      detail,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );


  Widget _studentForm() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Student Profile'),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Student name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: program,
            decoration: const InputDecoration(
              labelText: 'Programme',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              setState(() {
                student = name.text.trim();
                studentProgram = program.text.trim();
                tab = 0;
              });
            },
            child: const Text('Save Profile'),
          ),
        ],
      );

  Widget _facultyPlaceholder() => _placeholderPage(
        Icons.groups_outlined,
        'Faculty directory',
        'Faculty information coming soon.',
      );

  Widget _settings() => _placeholderPage(
        Icons.settings_outlined,
        'Settings',
        'Settings features coming soon',
      );

  Widget _placeholderPage(IconData icon, String title, String detail) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(detail, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
