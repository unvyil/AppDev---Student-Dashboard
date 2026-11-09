import 'dart:convert';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'faculty_page.dart';
import 'registration_page.dart';
import 'services/app_preferences.dart';
import 'services/storage_service.dart';
import 'settings_page.dart';
import 'students_page.dart';
import 'widgets/profile_avatar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _hasUnreadNotifications = true;
  final _dashboardKey = GlobalKey<_DashboardContentState>();

  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_onPreferencesChanged);
  }

  @override
  void dispose() {
    widget.preferences.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshDashboard() async {
    await _dashboardKey.currentState?._refreshDashboard();
  }

  Future<void> _openRegistration() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationPage()),
    );
    await _refreshDashboard();
  }

  void _openSettings() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          preferences: widget.preferences,
          onRefreshCache: _refreshDashboard,
        ),
      ),
    );
  }

  Future<String> _notificationStatus() async {
    final network = await Connectivity().checkConnectivity();
    if (widget.preferences.useMockData) {
      final networkName = network.map((result) => result.name).join(', ');
      return 'Network: ${networkName.isEmpty ? 'unknown' : networkName}\n'
          'Student API: mock data enabled';
    }
    final response = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/users'))
        .timeout(const Duration(seconds: 10));
    final networkName = network.map((result) => result.name).join(', ');
    return 'Network: ${networkName.isEmpty ? 'unknown' : networkName}\n'
        'Student API: HTTP ${response.statusCode}';
  }

  void _showNotifications() {
    setState(() => _hasUnreadNotifications = false);
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
                'System alerts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<String>(
                future: _notificationStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text('Checking system status'),
                    );
                  }
                  if (snapshot.hasError) {
                    return ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: const Text('Could not load current alerts'),
                      subtitle: Text('${snapshot.error}'),
                    );
                  }
                  return ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: const Text('Latest device check'),
                    subtitle: Text(snapshot.data!),
                  );
                },
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('No other unread alerts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardContent(
        key: _dashboardKey,
        preferences: widget.preferences,
        onOpenSettings: _openSettings,
        onRegisterStudent: _openRegistration,
      ),
      const StudentsPage(),
      const FacultyPage(),
      SettingsPage(
        preferences: widget.preferences,
        onRefreshCache: _refreshDashboard,
        showAppBar: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/img/lpu-logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.school, size: 30),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LPU-Cavite',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Student Dashboard',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 28),
                if (_hasUnreadNotifications)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF006E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotifications,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Student profile',
              onPressed: _openSettings,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: ProfileAvatar(
                bytes: widget.preferences.profilePhotoBytes,
                initials: 'NT',
                radius: 18,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Faculty',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({
    super.key,
    required this.preferences,
    required this.onOpenSettings,
    required this.onRegisterStudent,
  });

  final AppPreferences preferences;
  final VoidCallback onOpenSettings;
  final VoidCallback onRegisterStudent;

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  static const double _caviteLatitude = 14.386;
  static const double _caviteLongitude = 120.881;

  late Future<List<Student>> _studentsFuture;
  late Future<Map<String, dynamic>> _weatherFuture;
  late Future<List<Map<String, dynamic>>> _calendarFuture;
  late Future<String> _apiStatusFuture;
  late Future<String> _wifiStatusFuture;
  late Future<String> _gpsStatusFuture;
  late Future<String> _storageStatusFuture;
  late DateTime _clockNow;
  Timer? _clockTimer;
  int _studentCount = 0;
  late Future<List<RecentActivity>> _activityFuture;
  int _selectedLiveFeedTab = 0;
  late DateTime _selectedCalendarDate;
  late bool _lastMockDataSetting;

  @override
  void initState() {
    super.initState();
    _lastMockDataSetting = widget.preferences.useMockData;
    widget.preferences.addListener(_onPreferencesChanged);
    _clockNow = DateTime.now().toUtc();
    _selectedCalendarDate = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _clockNow = DateTime.now().toUtc());
    });
    _reloadDashboard();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    widget.preferences.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    final useMockData = widget.preferences.useMockData;
    if (useMockData == _lastMockDataSetting) return;
    _lastMockDataSetting = useMockData;
    if (mounted) setState(_reloadDashboard);
  }

  void _reloadDashboard() {
    _studentsFuture = StorageService.getStudents();
    _activityFuture = StorageService.getRecentActivity();
    _weatherFuture = _fetchWeather();
    _calendarFuture = _fetchCalendar();
    _apiStatusFuture = _checkApiStatus();
    _wifiStatusFuture = _checkWifiStatus();
    _gpsStatusFuture = _checkGpsStatus();
    _storageStatusFuture = _checkStorageStatus();
    _studentsFuture.then(
      (students) {
        if (mounted) {
          setState(() {
            _studentCount = students.length;
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Could not load registered student count: $error');
      },
    );
  }

  Future<String> _checkApiStatus() async {
    if (widget.preferences.useMockData) return 'Mock data';
    try {
      await Future.wait([
        _weatherFuture,
        _calendarFuture,
        http
            .get(Uri.parse('https://jsonplaceholder.typicode.com/users'))
            .timeout(const Duration(seconds: 15))
            .then((response) {
              if (response.statusCode != 200) {
                throw Exception(
                  'JSONPlaceholder returned ${response.statusCode}.',
                );
              }
            }),
      ]);
      return 'Online';
    } catch (error) {
      debugPrint('API health check failed: $error');
      return 'Degraded';
    }
  }

  Future<String> _checkWifiStatus() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.wifi)) return 'Connected';
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return 'Disconnected';
    }
    return 'Other network';
  }

  Future<String> _checkGpsStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    return enabled ? 'Active' : 'Disabled';
  }

  Future<String> _checkStorageStatus() async {
    await StorageService.getStudents();
    return 'Optimal';
  }

  Future<void> _refreshDashboard() async {
    setState(_reloadDashboard);
    try {
      await Future.wait([_studentsFuture, _weatherFuture, _calendarFuture]);
    } catch (error) {
      debugPrint('Dashboard refresh failed: $error');
    }
  }

  Future<Map<String, dynamic>> _fetchWeather() async {
    if (widget.preferences.useMockData) {
      return {
        'temperature_2m': 29,
        'relative_humidity_2m': 72,
        'apparent_temperature': 32,
        'weather_code': 2,
      };
    }
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$_caviteLatitude',
      'longitude': '$_caviteLongitude',
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code',
      'timezone': 'Asia/Manila',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    debugPrint('Weather API status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('Weather API returned ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['current'] is! Map<String, dynamic>) {
      throw const FormatException('Unexpected weather API response.');
    }
    return Map<String, dynamic>.from(decoded['current'] as Map);
  }

  Future<List<Map<String, dynamic>>> _fetchCalendar() async {
    if (widget.preferences.useMockData) {
      final nextMonth = DateTime.now().add(const Duration(days: 30));
      return [
        {
          'date':
              '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01',
          'localName': 'Sample semester orientation',
          'name': 'Demo academic calendar event',
        },
        {
          'date':
              '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-15',
          'localName': 'Sample registration period',
          'name': 'Demo academic calendar event',
        },
      ];
    }
    final year = DateTime.now().year;
    final response = await http
        .get(Uri.https('date.nager.at', '/api/v3/PublicHolidays/$year/PH'))
        .timeout(const Duration(seconds: 15));
    debugPrint('Calendar API status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('Calendar API returned ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Unexpected calendar API response.');
    }
    return decoded
        .whereType<Map>()
        .map((holiday) => Map<String, dynamic>.from(holiday))
        .toList();
  }

  int _gridColumnCount(BuildContext context, int itemCount) {
    final width = MediaQuery.sizeOf(context).width;
    final desiredColumns = width >= 600 ? 4 : 2;
    return itemCount < desiredColumns ? itemCount : desiredColumns;
  }

  Widget _statusKpis() {
    final kpis = [
      (
        'Wi-Fi',
        _wifiStatusFuture,
        Icons.wifi,
        () => setState(() => _wifiStatusFuture = _checkWifiStatus()),
      ),
      (
        'API',
        _apiStatusFuture,
        Icons.cloud_done_outlined,
        () => setState(() => _apiStatusFuture = _checkApiStatus()),
      ),
      (
        'GPS',
        _gpsStatusFuture,
        Icons.gps_fixed,
        () => setState(() => _gpsStatusFuture = _checkGpsStatus()),
      ),
      (
        'Storage',
        _storageStatusFuture,
        Icons.storage_outlined,
        () => setState(() => _storageStatusFuture = _checkStorageStatus()),
      ),
    ];

    return GridView.count(
      crossAxisCount: _gridColumnCount(context, kpis.length),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      mainAxisExtent: 82,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: kpis.map((kpi) {
        return Card(
          child: FutureBuilder<String>(
            future: kpi.$2,
            builder: (context, snapshot) {
              final waiting =
                  snapshot.connectionState == ConnectionState.waiting;
              final status = snapshot.hasError
                  ? 'Unavailable'
                  : snapshot.data ?? 'Unavailable';
              final healthy =
                  status == 'Connected' ||
                  status == 'Online' ||
                  status == 'Mock data' ||
                  status == 'Active' ||
                  status == 'Optimal';

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (waiting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        kpi.$3,
                        color: healthy
                            ? Colors.green.shade700
                            : snapshot.hasError
                            ? Colors.red
                            : Colors.orange,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$status\n${kpi.$1}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (snapshot.hasError)
                      IconButton(
                        tooltip: 'Retry ${kpi.$1} status',
                        onPressed: kpi.$4,
                        icon: const Icon(Icons.refresh, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  String _clockTime(int offsetHours) {
    final localTime = _clockNow.add(Duration(hours: offsetHours));
    final hour = (localTime.hour % 12 == 0 ? 12 : localTime.hour % 12)
        .toString()
        .padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _worldClockCard() {
    const cities = [
      ('Manila', 8, 'PHT · Philippines'),
      ('Tokyo', 9, 'JST · Japan'),
      ('UTC', 0, 'Coordinated Universal Time'),
    ];

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final city = cities[index];
          final localTime = _clockNow.add(Duration(hours: city.$2));
          final isDay = localTime.hour >= 6 && localTime.hour < 18;
          return SizedBox(
            width: 172,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            city.$1,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          isDay ? Icons.wb_sunny_outlined : Icons.nightlight,
                          color: const Color(0xFF800000),
                          size: 18,
                        ),
                      ],
                    ),
                    Text(
                      city.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _clockTime(city.$2),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _statusPill(isDay ? 'DAYTIME' : 'NIGHT', isDay),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusPill(String text, bool positive) {
    final color = positive ? const Color(0xFFDBFF49) : const Color(0xFFEAE5EF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      ('Device', Icons.devices_outlined, _showDeviceInfo),
      ('API', Icons.api_outlined, _showApiStatus),
      ('GPS', Icons.gps_fixed, _showGpsStatus),
      ('Network', Icons.wifi, _showNetworkStatus),
      ('Reports', Icons.assessment_outlined, _showReports),
      ('Settings', Icons.settings_outlined, widget.onOpenSettings),
    ];

    return GridView.count(
      crossAxisCount: _gridColumnCount(context, actions.length),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      mainAxisExtent: 80,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.map((action) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: action.$3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.$2, color: const Color(0xFF800000)),
                const SizedBox(width: 8),
                Text(
                  action.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showReports() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Report'),
        content: Text('Registered students: $_studentCount'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeviceInfo() async {
    final size = MediaQuery.sizeOf(context);
    final platform = Theme.of(context).platform.name;
    final orientation = MediaQuery.orientationOf(context).name;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device'),
        content: Text(
          'Platform: $platform\n'
          'Screen: ${size.width.round()} × ${size.height.round()} logical pixels\n'
          'Orientation: $orientation',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showApiStatus() async {
    setState(() {
      _weatherFuture = _fetchWeather();
      _calendarFuture = _fetchCalendar();
      _apiStatusFuture = _checkApiStatus();
    });
    await _showStatusDialog(
      'API status',
      _apiStatusFuture,
      'Weather, public-holiday, and JSONPlaceholder APIs',
    );
  }

  Future<void> _showGpsStatus() async {
    setState(() => _gpsStatusFuture = _checkGpsStatus());
    await _showStatusDialog(
      'GPS status',
      _gpsStatusFuture,
      'Uses the device location-service setting. The app does not request or read your location.',
    );
  }

  Future<void> _showNetworkStatus() async {
    setState(() => _wifiStatusFuture = _checkWifiStatus());
    await _showStatusDialog(
      'Network status',
      _wifiStatusFuture,
      'Wi-Fi connection status from the device.',
    );
  }

  Future<void> _showStatusDialog(
    String title,
    Future<String> status,
    String description,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: FutureBuilder<String>(
          future: status,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text('Could not read status: ${snapshot.error}');
            }
            return Text('${snapshot.data}\n\n$description');
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _studentDetails(
    List<Student> students, {
    required VoidCallback onRegisterStudent,
  }) {
    final student =
        students
            .where((item) => item.name.toLowerCase().contains('novy'))
            .firstOrNull ??
        (students.isEmpty ? null : students.first);
    final name = student?.name ?? 'Novy Chariz Tablac';
    final studentId = student?.id ?? '2023-1-00123';
    final program = student?.program ?? 'BSIT-WM';
    final yearLevel = student?.yearLevel ?? '3rd Year';
    final nameParts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = nameParts.isEmpty
        ? 'NT'
        : nameParts.length > 1
        ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
        : nameParts.first[0].toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  bytes: widget.preferences.profilePhotoBytes,
                  initials: initials,
                  radius: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$program · $yearLevel',
                        style: const TextStyle(
                          color: Color(0xFF800000),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Register student',
                  onPressed: onRegisterStudent,
                  icon: const Icon(Icons.person_add_alt_1),
                  color: const Color(0xFF800000),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _profilePill('ID', studentId),
                _profilePill(
                  'Email',
                  student?.email ?? 'novy.tablac@lpu.edu.ph',
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showFullProfile(
                  name: name,
                  studentId: studentId,
                  email: student?.email ?? 'Not provided',
                  program: program,
                  yearLevel: yearLevel,
                  contact: student?.contact ?? '',
                  address: student?.address ?? '',
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View Full Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilePill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showFullProfile({
    required String name,
    required String studentId,
    required String email,
    required String program,
    required String yearLevel,
    required String contact,
    required String address,
  }) {
    final details = [
      ('Student ID', studentId, Icons.badge_outlined),
      ('Email', email, Icons.email_outlined),
      ('Program', program, Icons.school_outlined),
      ('Year Level', yearLevel, Icons.event_note),
      if (contact.isNotEmpty) ('Contact Number', contact, Icons.phone_outlined),
      if (address.isNotEmpty) ('Address', address, Icons.home_outlined),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final detail in details)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(detail.$3, color: const Color(0xFF800000)),
                  title: Text(detail.$1),
                  subtitle: Text(detail.$2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _weatherDescription(Object? code) {
    return switch (code) {
      0 => 'Clear sky',
      1 || 2 => 'Mostly clear',
      3 => 'Cloudy',
      45 || 48 => 'Fog',
      51 || 53 || 55 => 'Drizzle',
      61 || 63 || 65 || 80 || 81 || 82 => 'Rain',
      71 || 73 || 75 || 77 => 'Snow',
      95 || 96 || 99 => 'Thunderstorm',
      _ => 'Current conditions',
    };
  }

  Widget _weatherCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading Cavite weather...'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _apiErrorCard('Weather', snapshot.error!, () {
            setState(() => _weatherFuture = _fetchWeather());
          });
        }

        final current = snapshot.data!;
        final temperature = current['temperature_2m'];
        final humidity = current['relative_humidity_2m'];
        final description = _weatherDescription(current['weather_code']);

        return Card(
          color: const Color(0xFFFFFFFF),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  current['weather_code'] == 0
                      ? Icons.wb_sunny_outlined
                      : Icons.cloud_outlined,
                  color: const Color(0xFF800000),
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cavite',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Humidity ${humidity ?? '--'}% · $description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${temperature ?? '--'}°C',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF800000),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _calendarCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _calendarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Philippines calendar'),
              subtitle: Text('Loading calendar...'),
            ),
          );
        }
        if (snapshot.hasError) {
          return _apiErrorCard('Calendar', snapshot.error!, () {
            setState(() => _calendarFuture = _fetchCalendar());
          });
        }

        final today = DateTime.now();
        final holidays = (snapshot.data ?? [])
            .where((holiday) {
              final date = DateTime.tryParse(holiday['date']?.toString() ?? '');
              return date != null &&
                  !date.isBefore(DateTime(today.year, today.month, today.day));
            })
            .take(4);

        if (holidays.isEmpty) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.event_available, color: Color(0xFF800000)),
              title: Text('Philippines calendar'),
              subtitle: Text(
                widget.preferences.useMockData
                    ? 'No sample events are scheduled.'
                    : 'No upcoming public holidays found this year.',
              ),
            ),
          );
        }

        return Card(
          child: Column(
            children: [
              for (final holiday in holidays)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: Color(0xFFFF006E), width: 4),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        holiday['localName']?.toString() ??
                            holiday['name']?.toString() ??
                            'Calendar event',
                      ),
                      subtitle: Text(
                        '${holiday['date']?.toString() ?? ''}'
                        '${widget.preferences.useMockData ? ' · Sample event' : ' · Public holiday (Nager.Date)'}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  String _weekdayLabel(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

  Widget _calendarWeekStrip() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = start.add(Duration(days: index));
          final selected =
              date.year == _selectedCalendarDate.year &&
              date.month == _selectedCalendarDate.month &&
              date.day == _selectedCalendarDate.day;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _selectedCalendarDate = date),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF800000) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF800000)
                      : const Color(0xFFE8E8EC),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(date.weekday),
                    style: TextStyle(
                      color: selected ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime timestamp) {
    final elapsed = DateTime.now().difference(timestamp);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }

  Widget _recentActivityCard() {
    return FutureBuilder<List<RecentActivity>>(
      future: _activityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return _apiErrorCard('Recent activity', snapshot.error!, () {
            setState(
              () => _activityFuture = StorageService.getRecentActivity(),
            );
          });
        }
        final activities = snapshot.data ?? const <RecentActivity>[];
        if (activities.isEmpty) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.timeline, color: Color(0xFF800000)),
              title: Text('No recent activity'),
              subtitle: Text(
                'Your registration and export actions will appear here.',
              ),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                for (var index = 0; index < activities.length; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 36,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFFFEAF2),
                                  child: Icon(
                                    activities[index].title.contains('export')
                                        ? Icons.file_download_outlined
                                        : Icons.person_outline,
                                    size: 17,
                                    color: const Color(0xFF800000),
                                  ),
                                ),
                                if (index < activities.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      margin: const EdgeInsets.only(top: 4),
                                      color: const Color(0xFFE9DDE2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activities[index].title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    activities[index].detail,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            _timeAgo(activities[index].timestamp),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _liveFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Calendar')),
            ButtonSegment(value: 1, label: Text('Recent activity')),
          ],
          selected: {_selectedLiveFeedTab},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            setState(() => _selectedLiveFeedTab = selection.first);
          },
        ),
        const SizedBox(height: 12),
        if (_selectedLiveFeedTab == 0) ...[
          _calendarWeekStrip(),
          const SizedBox(height: 8),
          _calendarCard(),
        ] else
          _recentActivityCard(),
      ],
    );
  }

  Widget _apiErrorCard(String apiName, Object error, VoidCallback onRetry) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.cloud_off, color: Colors.red),
        title: Text('$apiName API unavailable'),
        subtitle: Text(error.toString()),
        trailing: IconButton(
          tooltip: 'Retry $apiName',
          icon: const Icon(Icons.refresh),
          onPressed: onRetry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _weatherCard(),
          const SizedBox(height: 10),
          const Text(
            'Hello, Novy 👋',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
                return _apiErrorCard(
                  'Student details',
                  snapshot.error!,
                  () => setState(
                    () => _studentsFuture = StorageService.getStudents(),
                  ),
                );
              }
              return _studentDetails(
                snapshot.data ?? [],
                onRegisterStudent: widget.onRegisterStudent,
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'System health',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _statusKpis(),
          const SizedBox(height: 20),
          const Text(
            'Quick actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _quickActions(),
          const SizedBox(height: 20),
          const Text(
            'World clock',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _worldClockCard(),
          const SizedBox(height: 20),
          const Text(
            'Calendar & activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _liveFeed(),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
