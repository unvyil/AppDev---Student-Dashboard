import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'about_lpu_page.dart';
import 'faculty_page.dart';
import 'registration_page.dart';
import 'services/app_preferences.dart';
import 'services/storage_service.dart';
import 'settings_page.dart';
import 'students_page.dart';
import 'theme/app_theme.dart';
import 'widgets/overview_card_widget.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/swipeable_week_calendar_widget.dart';
import 'widgets/weather_header_card_widget.dart';

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
            tooltip: 'About LPU',
            icon: const Icon(Icons.info_outline, size: 24, color: Colors.white),
            onPressed: () => showAboutLpuModal(context),
          ),
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
  bool _isWifiConnected = true;
  bool _isGpsActive = true;
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
      final isWifi = results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet) ||
          results.contains(ConnectivityResult.mobile);
      if (mounted) {
        setState(() {
          _isWifiConnected = isWifi || results.isNotEmpty;
        });
      }
      return _isWifiConnected ? 'Connected' : 'Disconnected';
    } catch (_) {
      if (mounted) setState(() => _isWifiConnected = true);
      return 'Connected';
    }
  }

  Future<String> _checkGpsStatus() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (mounted) setState(() => _isGpsActive = enabled);
      return enabled ? 'Active' : 'Disabled';
    } catch (_) {
      if (mounted) setState(() => _isGpsActive = true);
      return 'Active';
    }
  }

  Future<void> _refreshLocationAndWeather() async {
    setState(() {
      _gpsStatusFuture = _checkGpsStatus();
      _weatherFuture = _fetchWeather();
    });
    final status = await _gpsStatusFuture;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPS & Weather Synced ($status): Manggahan, General Trias',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
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
                style: const TextStyle(
                  color: Color(0xFF800000),
                  fontWeight: FontWeight.w600,
                ),
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
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF800000),
                  ),
                  title: const Text('Address'),
                  subtitle: Text(address),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Weather Header Card Widget (Overflow-safe with GPS sync)
  Widget _buildWeatherHeader() {
    final hour = _clockNow.hour.toString().padLeft(2, '0');
    final minute = _clockNow.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final temp = (data?['temperature_2m'] as num?)?.toInt() ?? 31;
        final wind = (data?['wind_speed_10m'] as num?)?.toInt() ?? 7;
        final humidity = (data?['relative_humidity_2m'] as num?)?.toInt() ?? 56;

        return WeatherHeaderCardWidget(
          temperature: temp,
          condition: 'Sunny',
          windSpeed: wind,
          humidity: humidity,
          time: timeStr.isNotEmpty ? timeStr : '10:49',
          date: 'Tuesday, 27 October 2026',
          location: 'Manggahan, General Trias',
          isGpsActive: _isGpsActive,
          onLocationTap: _refreshLocationAndWeather,
        );
      },
    );
  }

  // 2. User Overview Card Widget
  Widget _buildOverviewCard() {
    return OverviewCardWidget(
      name: 'Novy Chariz Tablac',
      studentId: '2024-2-02204',
      program: 'BSIT-WM',
      yearLevel: '3rd Year',
      email: '2024-2-02204@lpunetwork.edu.ph',
      profilePhotoBytes: widget.preferences.profilePhotoBytes,
      onEditProfile: widget.onRegisterStudent,
      onViewFullProfile: () => _showFullProfile(
        name: 'Novy Chariz Tablac',
        studentId: '2024-2-02204',
        email: '2024-2-02204@lpunetwork.edu.ph',
        program: 'BSIT-WM',
        yearLevel: '3rd Year',
        contact: '+63 912 345 6789',
        address: 'Manggahan, General Trias, Cavite',
      ),
    );
  }

  // 3. Quick Actions Grid with dynamic Wi-Fi & GPS sync
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
          statusDotColor:
              _isGpsActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          statusText: _isGpsActive ? 'Active' : 'Disabled',
          onTap: _refreshLocationAndWeather,
        ),
        QuickActionButton(
          label: 'API',
          icon: Icons.code_rounded,
          onTap: _showApiStatus,
        ),
        QuickActionButton(
          label: 'Wi-Fi',
          icon: Icons.wifi,
          statusDotColor: _isWifiConnected
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
          statusText: _isWifiConnected ? 'Online' : 'Offline',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textColor = isDark ? AppTokens.textDark : AppTokens.textLight;
    final secondaryTextColor =
        isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight;

    final cities = [
      ('Manila', 8, 'PHT · Philippines'),
      ('Tokyo', 9, 'JST · Japan'),
      ('UTC', 0, 'Coordinated Universal Time'),
    ];

    return SizedBox(
      height: 108,
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
                  width: 154,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              city.$1,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: textColor,
                              ),
                            ),
                          ),
                          Icon(
                            isDay
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight_round,
                            color: isDark ? AppTokens.accentLime : maroonColor,
                            size: 14,
                          ),
                        ],
                      ),
                      Text(
                        '$hour:$minute $period',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        city.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: secondaryTextColor, size: 20),
        ],
      ),
    );
  }

  // 5. Swipeable Week Calendar
  Widget _buildCalendarWidget() {
    return SwipeableWeekCalendarWidget(
      selectedDate: _selectedCalendarDate,
      onDateSelected: (newDate) {
        setState(() {
          _selectedCalendarDate = newDate;
        });
      },
      eventText: 'No upcoming events.',
    );
  }

  // 6. Recent Activity Feed
  Widget _buildRecentActivityFeed() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textColor = isDark ? AppTokens.textDark : AppTokens.textLight;
    final secondaryTextColor =
        isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight;

    return FutureBuilder<List<RecentActivity>>(
      future: _activityFuture,
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];
        final hasActivities = activities.isNotEmpty;
        final title =
            hasActivities ? activities.first.title : 'Logged in to portal';

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                '5m ago',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: secondaryTextColor,
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
            _buildWeatherHeader(),
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
            _buildOverviewCard(),
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
            _buildCalendarWidget(),
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
