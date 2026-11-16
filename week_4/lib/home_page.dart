import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import 'about_lpu_page.dart';
import 'faculty_page.dart';
import 'online_directory_page.dart';
import 'registration_page.dart';
import 'services/app_preferences.dart';
import 'services/public_holiday_service.dart';
import 'services/portal_data_service.dart';
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
  final _dashboardKey = GlobalKey<_DashboardPageState>();

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
                'Recent notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<RecentActivity>>(
                future: StorageService.getRecentActivity(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text('Loading notifications'),
                    );
                  }
                  if (snapshot.hasError) {
                    return ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: const Text('Could not load notifications'),
                      subtitle: Text('${snapshot.error}'),
                    );
                  }
                  final activities = (snapshot.data ?? []).take(4).toList();
                  if (activities.isEmpty) {
                    return const ListTile(
                      leading: Icon(Icons.notifications_none),
                      title: Text('No recent notifications'),
                    );
                  }
                  return Column(
                    children: [
                      for (final activity in activities)
                        ListTile(
                          leading: const Icon(Icons.notifications_none),
                          title: Text(activity.title),
                          subtitle: Text(activity.detail),
                          trailing: Text(
                            _formatActivityTime(activity.timestamp),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatActivityTime(DateTime time) {
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inMinutes < 1) return 'Now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m';
    if (elapsed.inDays < 1) return '${elapsed.inHours}h';
    return '${elapsed.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);

    final pages = [
      DashboardPage(
        key: _dashboardKey,
        preferences: widget.preferences,
        onOpenSettings: _openSettings,
        onRegisterStudent: _openRegistration,
      ),
      StudentsPage(
        key: const ValueKey<String>('portal-students-page'),
        useMockData: widget.preferences.useMockData,
      ),
      FacultyPage(
        key: const ValueKey<String>('portal-faculty-page'),
        useMockData: widget.preferences.useMockData,
      ),
      SettingsPage(
        key: const ValueKey<String>('portal-settings'),
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
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.school, size: 26, color: Colors.white),
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
                const Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: Colors.white,
                ),
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
          setState(() {
            _selectedIndex = index;
            _hasUnreadNotifications = true;
          });
          const sections = ['Home', 'Students', 'Faculty', 'Settings'];
          StorageService.recordActivity(
            'Opened ${sections[index]}',
            'Portal navigation',
          ).then((_) => _dashboardKey.currentState?._refreshActivity());
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.preferences,
    required this.onOpenSettings,
    required this.onRegisterStudent,
  });

  final AppPreferences preferences;
  final VoidCallback onOpenSettings;
  final VoidCallback onRegisterStudent;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const double _caviteLatitude = 14.386;
  static const double _caviteLongitude = 120.881;

  late Future<List<Student>> _studentsFuture;
  late Future<Student?> _profileStudentFuture;
  late Future<Map<String, dynamic>> _weatherFuture;
  late Future<HolidayCalendarData> _calendarFuture;
  late Future<String> _apiStatusFuture;
  late Future<String> _wifiStatusFuture;
  late Future<String> _gpsStatusFuture;
  late Future<List<Map<String, dynamic>>> _onlineUsersFuture;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isWifiConnected = false;
  bool _hasConnectivityUpdate = false;
  bool _isGpsActive = true;
  String _gpsStatusLabel = 'Checking';
  String _weatherLocationLabel = 'LPU Cavite';
  late DateTime _clockNow;
  Timer? _clockTimer;
  int _studentCount = 0;
  late Future<List<RecentActivity>> _activityFuture;
  late DateTime _selectedCalendarDate;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    _clockNow = DateTime.now();
    _selectedCalendarDate = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _clockNow = DateTime.now());
    });
    _reloadDashboard();
    _refreshLocationAndWeather(
      announce: false,
      openSettingsIfDeniedForever: false,
    );
    _recordDashboardOpen();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _reloadDashboard() {
    _studentsFuture = StorageService.getStudents();
    _profileStudentFuture = StorageService.getProfile();
    _activityFuture = StorageService.getRecentActivity();
    _weatherFuture = _fetchWeather();
    _calendarFuture = _fetchCalendar();
    _apiStatusFuture = _checkApiStatus();
    _onlineUsersFuture = PortalDataService.fetchUsers();
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

  Future<void> _recordDashboardOpen() async {
    await StorageService.recordActivity('Portal session started', 'Home');
    await StorageService.recordActivity('Dashboard opened', 'Home overview');
    if (!mounted) return;
    setState(() => _activityFuture = StorageService.getRecentActivity());
  }

  void _refreshActivity() {
    if (!mounted) return;
    setState(() => _activityFuture = StorageService.getRecentActivity());
  }

  Future<String> _checkApiStatus() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.every((result) => result == ConnectivityResult.none)) {
        return 'Offline (using cached data)';
      }
      await Future.wait([
        _weatherFuture,
        _calendarFuture.then((calendar) {
          if (calendar.isOffline) {
            throw const FormatException(
              'Public holidays are using offline data.',
            );
          }
        }),
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
      _handleConnectivityChange(results, announce: false);
      return _isWifiConnected ? 'Connected' : 'Disconnected';
    } catch (_) {
      _handleConnectivityChange(const [
        ConnectivityResult.none,
      ], announce: false);
      return 'Disconnected';
    }
  }

  void _handleConnectivityChange(
    List<ConnectivityResult> results, {
    bool announce = true,
  }) {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    final wasInitialized = _hasConnectivityUpdate;
    final changed = isConnected != _isWifiConnected;
    _hasConnectivityUpdate = true;
    if (!changed && wasInitialized) return;

    if (!mounted) {
      _isWifiConnected = isConnected;
      return;
    }

    setState(() {
      _isWifiConnected = isConnected;
      _wifiStatusFuture = Future.value(
        isConnected ? 'Connected' : 'Disconnected',
      );
      PortalDataService.resetInFlightRequest();
      _reloadDashboard();
    });

    if (changed && wasInitialized && announce) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected
                ? 'Connection restored. Portal data is syncing.'
                : 'You are offline. Showing locally cached portal data.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String> _checkGpsStatus() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final label = !enabled
          ? 'Location off'
          : permission == LocationPermission.deniedForever
          ? 'Allow in settings'
          : permission == LocationPermission.denied
          ? 'Permission needed'
          : 'Active';
      final available = label == 'Active';
      if (mounted) {
        setState(() {
          _isGpsActive = available;
          _gpsStatusLabel = label;
        });
      }
      return label;
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGpsActive = false;
          _gpsStatusLabel = 'Unavailable';
        });
      }
      return 'Unavailable';
    }
  }

  Future<void> _refreshLocationAndWeather({
    bool announce = true,
    bool openSettingsIfDeniedForever = true,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever &&
          openSettingsIfDeniedForever) {
        await Geolocator.openAppSettings();
      }
    } catch (_) {
      // Weather falls back to the LPU Cavite coordinates if location is unavailable.
    }
    setState(() {
      _gpsStatusFuture = _checkGpsStatus();
      _weatherFuture = _fetchWeather();
    });
    final status = await _gpsStatusFuture;
    await _weatherFuture;
    if (mounted && announce) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPS & Weather Synced ($status): $_weatherLocationLabel',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _refreshDashboard() async {
    setState(_reloadDashboard);
    try {
      await Future.wait([
        _studentsFuture,
        _weatherFuture,
        _calendarFuture,
        _onlineUsersFuture,
      ]);
    } catch (error) {
      debugPrint('Dashboard refresh error: $error');
    }
  }

  Future<void> _openOnlineDirectory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OnlineDirectoryPage(useMockData: widget.preferences.useMockData),
      ),
    );
    if (mounted) {
      setState(() => _onlineUsersFuture = PortalDataService.fetchUsers());
    }
  }

  Future<Map<String, dynamic>> _fetchWeather() async {
    try {
      var latitude = _caviteLatitude;
      var longitude = _caviteLongitude;
      var locationLabel = 'LPU Cavite';
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      if (locationEnabled &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always)) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        latitude = position.latitude;
        longitude = position.longitude;
        locationLabel = await _resolveLocationName(latitude, longitude);
        _isGpsActive = true;
      }
      _weatherLocationLabel = locationLabel;
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
        'timezone': 'auto',
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

  Future<String> _resolveLocationName(double latitude, double longitude) async {
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (places.isNotEmpty) {
        final place = places.first;
        const broadAreas = {
          'cavite',
          'calabarzon',
          'region iv-a',
          'philippines',
        };
        final localityCandidates =
            [place.locality, place.subAdministrativeArea, place.subLocality]
                .whereType<String>()
                .map((value) => value.trim())
                .where(
                  (value) =>
                      value.isNotEmpty &&
                      !broadAreas.contains(value.toLowerCase()),
                );
        final locality = localityCandidates.firstOrNull;
        if (locality != null) {
          final region = [place.subAdministrativeArea, place.administrativeArea]
              .whereType<String>()
              .map((value) => value.trim())
              .firstWhere(
                (value) =>
                    value.isNotEmpty &&
                    value.toLowerCase() != locality.toLowerCase() &&
                    !{
                      'calabarzon',
                      'region iv-a',
                      'philippines',
                    }.contains(value.toLowerCase()),
                orElse: () => '',
              );
          final parts = [
            locality,
            region,
          ].where((part) => part.isNotEmpty).toList();
          return parts.join(', ');
        }
      }
    } catch (error) {
      debugPrint('Reverse geocoding failed: $error');
    }
    return 'GPS ${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
  }

  Future<HolidayCalendarData> _fetchCalendar() =>
      PublicHolidayService.fetch(year: _selectedCalendarDate.year);

  void _selectCalendarDate(DateTime date) {
    final yearChanged = date.year != _selectedCalendarDate.year;
    setState(() {
      _selectedCalendarDate = date;
      if (yearChanged) {
        _calendarFuture = PublicHolidayService.fetch(year: date.year);
        _apiStatusFuture = _checkApiStatus();
      }
    });
  }

  Future<void> _showReports() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Report'),
        content: Text(
          'Total registered student records: $_studentCount\n'
          'CCS Programs: 4\n'
          'Active Students: 401\n'
          'Average Attendance: 93%',
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
      'Network Status',
      _wifiStatusFuture,
      'When there is no network, student and faculty data is read from the local cache.',
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                leading: const Icon(
                  Icons.badge_outlined,
                  color: Color(0xFF800000),
                ),
                title: const Text('Student ID'),
                subtitle: Text(studentId),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF800000),
                ),
                title: const Text('Email'),
                subtitle: Text(email),
              ),
              if (contact.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF800000),
                  ),
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
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dateStr =
        '${weekdays[_clockNow.weekday - 1]}, ${_clockNow.day} ${months[_clockNow.month - 1]} ${_clockNow.year}';

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
          time: timeStr,
          date: dateStr,
          location: _weatherLocationLabel,
          isGpsActive: _isGpsActive,
          onLocationTap: () => _refreshLocationAndWeather(),
        );
      },
    );
  }

  // 2. User Overview Card Widget
  Widget _buildDashboardStatistics() => FutureBuilder<List<Student>>(
    future: _studentsFuture,
    builder: (context, studentSnapshot) {
      final students = studentSnapshot.data ?? const <Student>[];
      final averageGrade = students.isEmpty
          ? 0.0
          : students.fold<double>(0, (sum, student) => sum + student.grade) /
                students.length;
      Student? topPerformer;
      for (final student in students) {
        if (topPerformer == null || student.grade > topPerformer.grade) {
          topPerformer = student;
        }
      }

      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.48,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _dashboardStatCard(
            title: 'Total Students',
            value: studentSnapshot.connectionState == ConnectionState.waiting
                ? '…'
                : '${students.length}',
            subtitle: 'Saved student records',
            icon: Icons.people_outline,
          ),
          _dashboardStatCard(
            title: 'Average Grade',
            value: '${averageGrade.toStringAsFixed(1)}%',
            subtitle: 'Across registered students',
            icon: Icons.insights_outlined,
          ),
          _dashboardStatCard(
            title: 'Top Performer',
            value: topPerformer?.name ?? 'No records',
            subtitle: topPerformer == null
                ? 'Highest grade unavailable'
                : 'Highest grade · ${topPerformer.grade.toStringAsFixed(1)}%',
            icon: Icons.emoji_events_outlined,
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _onlineUsersFuture,
            builder: (context, onlineSnapshot) => _dashboardStatCard(
              title: 'Online Users',
              value: onlineSnapshot.connectionState == ConnectionState.waiting
                  ? '…'
                  : '${onlineSnapshot.data?.length ?? 0}',
              subtitle: 'JSONPlaceholder API data',
              icon: Icons.cloud_done_outlined,
            ),
          ),
        ],
      );
    },
  );

  Widget _dashboardStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTokens.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppTokens.maroonPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: title == 'Top Performer' ? 15 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return FutureBuilder<Student?>(
      future: _profileStudentFuture,
      builder: (context, snapshot) {
        final student = snapshot.data;
        final name = student?.name ?? 'Student profile';
        final id = student?.id ?? 'Register a student to complete your profile';
        final program = student?.program ?? '';
        final year = student?.yearLevel ?? '';
        final email = student?.email ?? '';
        return OverviewCardWidget(
          name: name,
          studentId: id,
          program: program,
          yearLevel: year,
          email: email,
          profilePhotoBytes: widget.preferences.profilePhotoBytes,
          onEditProfile: student == null
              ? widget.onRegisterStudent
              : () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistrationPage(
                        student: student,
                        isProfileEditor: true,
                      ),
                    ),
                  );
                  if (mounted) setState(_reloadDashboard);
                },
          onViewFullProfile: student == null
              ? widget.onRegisterStudent
              : () => _showFullProfile(
                  name: student.name,
                  studentId: student.id,
                  email: student.email,
                  program: student.program,
                  yearLevel: student.yearLevel,
                  contact: student.contact,
                  address: student.address,
                ),
        );
      },
    );
  }

  // 3. Quick Actions Grid with dynamic network & GPS status
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
          statusDotColor: _isGpsActive
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
          statusText: _gpsStatusLabel,
          onTap: _refreshLocationAndWeather,
        ),
        QuickActionButton(
          label: 'API',
          icon: Icons.code_rounded,
          onTap: _showApiStatus,
        ),
        QuickActionButton(
          label: 'Network',
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
          label: 'Online Users',
          icon: Icons.cloud_sync_outlined,
          onTap: _openOnlineDirectory,
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < 360 ? 144.0 : 154.0;
    final textColor = isDark ? AppTokens.textDark : AppTokens.textLight;
    final secondaryTextColor = isDark
        ? AppTokens.textSecondaryDark
        : AppTokens.textSecondaryLight;

    final cities = [
      ('Manila', 8, 'PHT · Philippines'),
      ('Tokyo', 9, 'JST · Japan'),
      ('UTC', 0, 'Coordinated Universal Time'),
    ];

    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
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
            width: cardWidth,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor.withValues(alpha: .7)),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        city.$1,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                    ),
                    Icon(
                      isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                      color: isDark ? AppTokens.maroonOnDark : maroonColor,
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '$hour:$minute $period',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Text(
                  city.$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    height: 1.15,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 5. Swipeable Week Calendar
  Widget _buildCalendarWidget() {
    return FutureBuilder<HolidayCalendarData>(
      future: _calendarFuture,
      builder: (context, snapshot) {
        final calendar = snapshot.data;
        return SwipeableWeekCalendarWidget(
          selectedDate: _selectedCalendarDate,
          onDateSelected: _selectCalendarDate,
          holidays: calendar?.holidays ?? const [],
          holidaysOffline: calendar?.isOffline ?? false,
          eventText: snapshot.connectionState == ConnectionState.waiting
              ? 'Loading public holiday dates…'
              : 'No public holiday on this date.',
        );
      },
    );
  }

  // 6. Recent Activity Feed
  String _formatActivityTime(DateTime time) {
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inMinutes < 1) return 'Now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m';
    if (elapsed.inDays < 1) return '${elapsed.inHours}h';
    return '${elapsed.inDays}d';
  }

  Widget _buildRecentActivityFeed() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textColor = isDark ? AppTokens.textDark : AppTokens.textLight;
    final secondaryTextColor = isDark
        ? AppTokens.textSecondaryDark
        : AppTokens.textSecondaryLight;

    return FutureBuilder<List<RecentActivity>>(
      future: _activityFuture,
      builder: (context, snapshot) {
        final activities = (snapshot.data ?? []).take(4).toList();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (activities.isEmpty) {
          return Text(
            'No activity yet',
            style: TextStyle(color: secondaryTextColor),
          );
        }
        return Column(
          children: [
            for (final activity in activities)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: secondaryTextColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (activity.detail.isNotEmpty)
                            Text(
                              activity.detail,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: secondaryTextColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _formatActivityTime(activity.timestamp),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dashboard Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh dashboard statistics',
                  onPressed: _refreshDashboard,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            _buildDashboardStatistics(),
            const SizedBox(height: 16),
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _buildOverviewCard(),
            const SizedBox(height: 16),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _buildQuickActions(),
            const SizedBox(height: 16),
            Text(
              'World Clock',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _buildWorldClock(),
            const SizedBox(height: 16),
            Text(
              'Academic Calendar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _buildCalendarWidget(),
            const SizedBox(height: 16),
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
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
