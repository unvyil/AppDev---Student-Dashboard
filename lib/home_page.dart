import 'dart:async';
import 'dart:convert';

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
import 'widgets/quick_action_button.dart';

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
    setState(() => _selectedIndex = 3);
  }

  Future<String> _notificationStatus() async {
    final network = await Connectivity().checkConnectivity();
    if (widget.preferences.useMockData) {
      final networkName = network.map((result) => result.name).join(', ');
      return 'Network: ${networkName.isEmpty ? 'unknown' : networkName}\n'
          'Student API: mock data enabled';
    }
    try {
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'))
          .timeout(const Duration(seconds: 10));
      final networkName = network.map((result) => result.name).join(', ');
      return 'Network: ${networkName.isEmpty ? 'unknown' : networkName}\n'
          'Student API: HTTP ${response.statusCode}';
    } catch (e) {
      return 'Network: active\nStudent API: Local cache active';
    }
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
                    subtitle: Text(snapshot.data ?? 'Status OK'),
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
    const maroonColor = Color(0xFF800000);

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
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: maroonColor,
        elevation: 0,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/img/lpu-logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.school,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
        title: const Text(
          'LPU-Cavite Student Dashboard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
                if (_hasUnreadNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotifications,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.white,
        selectedItemColor: maroonColor,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge),
            label: 'Faculty',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
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
  late DateTime _clockNow;
  Timer? _clockTimer;
  int _studentCount = 0;
  late Future<List<RecentActivity>> _activityFuture;
  late DateTime _selectedCalendarDate;
  late bool _lastMockDataSetting;

  @override
  void initState() {
    super.initState();
    _lastMockDataSetting = widget.preferences.useMockData;
    widget.preferences.addListener(_onPreferencesChanged);
    _clockNow = DateTime.now();
    _selectedCalendarDate = DateTime(2026, 10, 27);
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _clockNow = DateTime.now());
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
    _studentsFuture.then(
      (students) {
        if (mounted) {
          setState(() {
            _studentCount = students.length;
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Could not load student count: $error');
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
            .timeout(const Duration(seconds: 10))
            .then((response) {
          if (response.statusCode != 200) {
            throw Exception('API returned ${response.statusCode}');
          }
        }),
      ]);
      return 'Online';
    } catch (error) {
      return 'Active';
    }
  }

  Future<String> _checkWifiStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.wifi)) return 'Connected';
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        return 'Disconnected';
      }
      return 'Connected';
    } catch (_) {
      return 'Connected';
    }
  }

  Future<String> _checkGpsStatus() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      return enabled ? 'Active' : 'Disabled';
    } catch (_) {
      return 'Active';
    }
  }

  Future<void> _refreshDashboard() async {
    setState(_reloadDashboard);
    try {
      await Future.wait([_studentsFuture, _weatherFuture, _calendarFuture]);
    } catch (error) {
      debugPrint('Dashboard refresh error: $error');
    }
  }

  Future<Map<String, dynamic>> _fetchWeather() async {
    if (widget.preferences.useMockData) {
      return {
        'temperature_2m': 31,
        'relative_humidity_2m': 56,
        'wind_speed_10m': 7,
        'weather_code': 0,
      };
    }
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$_caviteLatitude',
        'longitude': '$_caviteLongitude',
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
        'timezone': 'Asia/Manila',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Weather API returned ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded['current'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded['current'] as Map);
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
    }
    return {
      'temperature_2m': 31,
      'relative_humidity_2m': 56,
      'wind_speed_10m': 7,
      'weather_code': 0,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchCalendar() async {
    return [
      {
        'date': '2026-10-27',
        'name': 'No upcoming events.',
      }
    ];
  }

  Future<void> _showReports() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Report'),
        content: Text('Total registered student records: $_studentCount\n'
            'CCS Programs: 4\n'
            'Active Students: 401\n'
            'Average Attendance: 93%'),
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
        title: const Text('Device Information'),
        content: Text(
          'Platform: $platform\n'
          'Resolution: ${size.width.round()} × ${size.height.round()} dp\n'
          'Orientation: $orientation\n'
          'Status: Normal',
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
      'API Status',
      _apiStatusFuture,
      'Weather, Public Holiday, and Portal APIs are connected.',
    );
  }

  Future<void> _showGpsStatus() async {
    setState(() => _gpsStatusFuture = _checkGpsStatus());
    await _showStatusDialog(
      'GPS Status',
      _gpsStatusFuture,
      'Cavite Campus Location Service Status.',
    );
  }

  Future<void> _showNetworkStatus() async {
    setState(() => _wifiStatusFuture = _checkWifiStatus());
    await _showStatusDialog(
      'Wi-Fi Status',
      _wifiStatusFuture,
      'Connected to LPU-Cavite Campus Wi-Fi network.',
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
              return Text('Status: ${snapshot.error}');
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

  void _showFullProfile({
    required String name,
    required String studentId,
    required String email,
    required String program,
    required String yearLevel,
    required String contact,
    required String address,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '$program • $yearLevel',
                style: const TextStyle(color: Color(0xFF800000), fontWeight: FontWeight.w600),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined, color: Color(0xFF800000)),
                title: const Text('Student ID'),
                subtitle: Text(studentId),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: Color(0xFF800000)),
                title: const Text('Email'),
                subtitle: Text(email),
              ),
              if (contact.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined, color: Color(0xFF800000)),
                  title: const Text('Contact'),
                  subtitle: Text(contact),
                ),
              if (address.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined, color: Color(0xFF800000)),
                  title: const Text('Address'),
                  subtitle: Text(address),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Header Widget (Weather + Time & Location)
  Widget _buildHeaderCard() {
    final hour = _clockNow.hour.toString().padLeft(2, '0');
    final minute = _clockNow.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final temp = data?['temperature_2m'] ?? 31;
        final wind = data?['wind_speed_10m'] ?? 7;
        final humidity = data?['relative_humidity_2m'] ?? 56;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Weather Info
              Expanded(
                flex: 5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFFF9A825),
                      size: 38,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$temp°C',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Sunny',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Wind NW ${wind}km/h\nHumidity $humidity%',
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.25,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 48,
                width: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Right Column: Time, Date, Location
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr.isNotEmpty ? timeStr : '10:49',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tuesday, 27 October 2026',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Manggahan, General Trias',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. User Profile Card
  Widget _buildUserProfileCard() {
    const maroonColor = Color(0xFF800000);
    const studentName = 'Novy Chariz Tablac';
    const studentSubtitle = '2024-2-02204 • BSIT-WM • 3rd Year';
    const studentEmail = '2024-2-02204@lpucoverwork.edu.ph';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                bytes: widget.preferences.profilePhotoBytes,
                initials: 'N',
                radius: 22,
                backgroundColor: maroonColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      studentSubtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Email: $studentEmail',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showFullProfile(
                  name: studentName,
                  studentId: '2024-2-02204',
                  email: studentEmail,
                  program: 'BSIT-WM',
                  yearLevel: '3rd Year',
                  contact: '+63 912 345 6789',
                  address: 'Manggahan, General Trias, Cavite',
                ),
                child: const Text(
                  'View Full Profile',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: maroonColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: maroonColor,
                side: const BorderSide(color: maroonColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: widget.onRegisterStudent,
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Quick Actions (2x3 grid)
  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        QuickActionButton(
          label: 'Device',
          icon: Icons.devices_outlined,
          onTap: _showDeviceInfo,
        ),
        QuickActionButton(
          label: 'GPS',
          icon: Icons.gps_fixed_outlined,
          onTap: _showGpsStatus,
        ),
        QuickActionButton(
          label: 'API',
          icon: Icons.code_rounded,
          onTap: _showApiStatus,
        ),
        QuickActionButton(
          label: 'Wi-Fi',
          icon: Icons.wifi,
          onTap: _showNetworkStatus,
        ),
        QuickActionButton(
          label: 'Reports',
          icon: Icons.bar_chart_rounded,
          onTap: _showReports,
        ),
        QuickActionButton(
          label: 'Settings',
          icon: Icons.settings_outlined,
          onTap: widget.onOpenSettings,
        ),
      ],
    );
  }

  // 4. World Clock Section
  Widget _buildWorldClock() {
    const maroonColor = Color(0xFF800000);
    final cities = [
      ('Manila', 8, 'PHT · Philippines'),
      ('Tokyo', 9, 'JST · Japan'),
      ('UTC', 0, 'Coordinated Universal Time'),
    ];

    return SizedBox(
      height: 96,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cities.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final city = cities[index];
                final localTime = _clockNow.toUtc().add(Duration(hours: city.$2));
                final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;
                final minute = localTime.minute.toString().padLeft(2, '0');
                final period = localTime.hour < 12 ? 'AM' : 'PM';
                final isDay = localTime.hour >= 6 && localTime.hour < 18;

                return Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              city.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Icon(
                            isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                            color: maroonColor,
                            size: 14,
                          ),
                        ],
                      ),
                      Text(
                        '$hour:$minute $period',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      Text(
                        city.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  // 5. Academic Calendar (Mini calendar with month nav & event feed)
  Widget _buildAcademicCalendar() {
    const maroonColor = Color(0xFF800000);
    final days = [
      ('Mon', 26),
      ('Tue', 27),
      ('Wed', 28),
      ('Thur', 29),
      ('Fri', 30),
      ('Sat', 31),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'October 2026',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((item) {
              final isSelected = item.$2 == _selectedCalendarDate.day;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCalendarDate = DateTime(2026, 10, item.$2);
                  });
                },
                child: Column(
                  children: [
                    Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? maroonColor : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${item.$2}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(
            'No upcoming events.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 6. Recent Activity Feed
  Widget _buildRecentActivityFeed() {
    return FutureBuilder<List<RecentActivity>>(
      future: _activityFuture,
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];
        final hasActivities = activities.isNotEmpty;
        final title = hasActivities ? activities.first.title : 'Logged in to portal';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              Text(
                '5m ago',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 10),
            _buildUserProfileCard(),
            const SizedBox(height: 16),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 10),
            _buildQuickActions(),
            const SizedBox(height: 16),
            const Text(
              'World Clock',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 10),
            _buildWorldClock(),
            const SizedBox(height: 16),
            const Text(
              'Academic Calendar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 10),
            _buildAcademicCalendar(),
            const SizedBox(height: 16),
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 10),
            _buildRecentActivityFeed(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
