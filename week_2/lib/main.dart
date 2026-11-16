import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'services/public_holiday_service.dart';
import 'theme/app_theme.dart';
import 'widgets/swipeable_week_calendar_widget.dart';

void main() => runApp(const PortalApp());

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LPU-Cavite Student Dashboard',
    debugShowCheckedModeBanner: false,
    theme: AppTokens.buildTheme(Brightness.light),
    home: const PortalHome(),
  );
}

class PortalHome extends StatefulWidget {
  const PortalHome({super.key});

  @override
  State<PortalHome> createState() => _PortalHomeState();
}

class _PortalHomeState extends State<PortalHome> {
  static const _defaultLatitude = 14.386;
  static const _defaultLongitude = 120.881;

  int tab = 0;
  String student = 'Juan Dela Cruz';
  String studentProgram = 'BSIT-WM';
  double _latitude = _defaultLatitude;
  double _longitude = _defaultLongitude;
  String _locationLabel = 'LPU Cavite';
  String _networkLabel = 'Checking';
  String _gpsLabel = 'Checking';
  bool _isWifiConnected = false;
  bool _hasNetworkUpdate = false;
  final _studentSearchController = TextEditingController();
  final _facultySearchController = TextEditingController();
  String _studentSearchQuery = '';
  String _facultySearchQuery = '';
  String _studentFilter = 'All';
  String _facultyFilter = 'All';
  late Future<List<Map<String, dynamic>>> users;
  late Future<Map<String, dynamic>> weather;
  late Future<HolidayCalendarData> holidays;
  late Future<List<Map<String, dynamic>>> posts;
  late Future<String> apiStatus;
  late DateTime _selectedCalendarDate;

  // Challenge 1: faculty records are intentionally static mock data, not API users.
  static const List<Map<String, String>> facultyMembers = [
    {
      'name': 'Dr. Maria Santos',
      'department': 'College of Computer Studies',
      'email': 'maria.santos@example.edu',
      'phone': '+63 917 100 2001',
    },
    {
      'name': 'Prof. Carlo Reyes',
      'department': 'Information Technology',
      'email': 'carlo.reyes@example.edu',
      'phone': '+63 917 100 2002',
    },
    {
      'name': 'Engr. Angela Cruz',
      'department': 'Computer Science',
      'email': 'angela.cruz@example.edu',
      'phone': '+63 917 100 2003',
    },
    {
      'name': 'Mr. Daniel Garcia',
      'department': 'Network and Security',
      'email': 'daniel.garcia@example.edu',
      'phone': '+63 917 100 2004',
    },
    {
      'name': 'Ms. Patricia Lim',
      'department': 'Web and Mobile Development',
      'email': 'patricia.lim@example.edu',
      'phone': '+63 917 100 2005',
    },
  ];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final tracks = const [
    ('BSIT-NS', 'Network & Security', 120, Color(0xFF0096C7)),
    ('BSIT-WM', 'Web & Mobile Development', 150, Color(0xFF7B2CBF)),
    ('BSCS-DS', 'Data Science', 100, Color(0xFFE85D04)),
    ('BSCS-SE', 'Software Engineering', 90, Color(0xFF2563EB)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCalendarDate = DateTime.now();
    _reloadApis();
    unawaited(_checkGpsStatus());
    unawaited(_checkNetworkStatus());
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _studentSearchController.dispose();
    _facultySearchController.dispose();
    super.dispose();
  }

  void _reloadApis() {
    users = _fetchUsers();
    weather = _fetchWeather();
    holidays = _fetchHolidays();
    posts = _fetchPosts();
    apiStatus = _checkApiStatus();
  }

  Future<void> _refreshApis() async {
    setState(_reloadApis);
    try {
      await Future.wait([users, weather, holidays, posts]);
    } catch (_) {
      // Each section displays its own API error and retry action.
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final response = await http
        .get(Uri.https('jsonplaceholder.typicode.com', '/users'))
        .timeout(const Duration(seconds: 15));
    debugPrint('GET /users status: ${response.statusCode}');
    debugPrint(
      'GET /users body: ${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}',
    );
    if (response.statusCode != 200) {
      throw Exception('JSONPlaceholder returned HTTP ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid users response.');
    }
    return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  // Part 1: explore the /posts endpoint and decode its JSON response.
  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    final response = await http
        .get(Uri.https('jsonplaceholder.typicode.com', '/posts'))
        .timeout(const Duration(seconds: 15));
    debugPrint('GET /posts status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception(
        'JSONPlaceholder posts returned HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid posts response.');
    }
    return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Future<Map<String, dynamic>> _fetchWeather() async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$_latitude',
      'longitude': '$_longitude',
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
      'timezone': 'Asia/Manila',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo returned HTTP ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['current'] is! Map) {
      throw const FormatException('Invalid weather response.');
    }
    return Map<String, dynamic>.from(decoded['current'] as Map);
  }

  Future<HolidayCalendarData> _fetchHolidays() =>
      PublicHolidayService.fetch(year: _selectedCalendarDate.year);

  Future<String> _checkApiStatus() async {
    try {
      await users;
      await weather;
      final calendar = await holidays;
      await posts;
      if (calendar.isOffline) return 'Using saved holiday dates offline';
      return 'Online';
    } catch (_) {
      return 'One or more APIs are unavailable';
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final connected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    final wifi = results.contains(ConnectivityResult.wifi);
    final changed =
        !_hasNetworkUpdate || connected != (_networkLabel != 'Offline');
    _hasNetworkUpdate = true;
    _isWifiConnected = wifi;
    _networkLabel = wifi
        ? 'Wi-Fi'
        : connected
        ? 'Connected'
        : 'Offline';
    if (mounted) setState(() {});
    if (changed && connected) _refreshApis();
  }

  Future<void> _checkNetworkStatus() async {
    try {
      _handleConnectivityChange(await Connectivity().checkConnectivity());
    } catch (_) {
      if (mounted) setState(() => _networkLabel = 'Unavailable');
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
      if (mounted) setState(() => _gpsLabel = label);
      return label;
    } catch (_) {
      if (mounted) setState(() => _gpsLabel = 'Unavailable');
      return 'Unavailable';
    }
  }

  Future<void> _refreshLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        _showMessage('Location permission was not granted. Using LPU Cavite.');
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage('Location services are off. Using LPU Cavite.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
      try {
        final marks = await Geocoding().placemarkFromCoordinates(
          _latitude,
          _longitude,
        );
        if (marks.isNotEmpty) {
          final mark = marks.first;
          _locationLabel = [mark.locality, mark.administrativeArea]
              .whereType<String>()
              .where((part) => part.trim().isNotEmpty)
              .toSet()
              .join(', ');
        }
      } catch (_) {
        _locationLabel = 'Current location';
      }
      if (!mounted) return;
      setState(() {
        _reloadApis();
        _gpsLabel = 'Active';
      });
      await weather;
    } catch (error) {
      _showMessage('Could not update location: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showDeviceInfo() async {
    final size = MediaQuery.sizeOf(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Information'),
        content: Text(
          'Platform: ${Theme.of(context).platform.name}\n'
          'Resolution: ${size.width.round()} × ${size.height.round()} dp\n'
          'Orientation: ${MediaQuery.orientationOf(context).name}',
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

  Future<void> _showNetworkInfo() async {
    await _checkNetworkStatus();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Status'),
        content: Text(
          'Connection: $_networkLabel\nAPI status: ${_isWifiConnected ? 'Wi-Fi connected' : 'See API status for endpoint health.'}',
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

  Future<void> _showApiInfo() async {
    await _refreshApis();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Connections'),
        content: FutureBuilder<String>(
          future: apiStatus,
          builder: (context, snapshot) => Text(
            'Status: ${snapshot.data ?? 'Checking'}\n\n'
            'Users: JSONPlaceholder\nWeather: Open-Meteo\nHolidays: Nager.Date',
          ),
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

  Future<void> _showReports() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Portal Report'),
        content: Text(
          'Student profile: $student\n'
          'Programme: $studentProgram\n'
          'CCS programmes: ${tracks.length}\n'
          'Directory source: JSONPlaceholder\n'
          'Faculty records: ${facultyMembers.length} static mock entries',
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

  @override
  Widget build(BuildContext context) {
    final pages = [_overview(), _directory(), _facultyPage(), _settings()];
    return Scaffold(
      appBar: AppBar(
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
        title: const Text('LPU-Cavite Student Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh APIs',
            onPressed: _refreshApis,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: IndexedStack(index: tab, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (value) => setState(() => tab = value),
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
            label: 'Students',
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

  Widget _overview() => RefreshIndicator(
    onRefresh: _refreshApis,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        _weatherCard(),
        const SizedBox(height: 14),
        _sectionTitle('Overview'),
        const SizedBox(height: 10),
        _profileCard(),
        const SizedBox(height: 16),
        _sectionTitle('API Statistics'),
        const SizedBox(height: 8),
        _apiStatisticsCard(),
        const SizedBox(height: 16),
        _sectionTitle('API Posts Preview'),
        const SizedBox(height: 8),
        _postsPreviewCard(),
        const SizedBox(height: 16),
        _sectionTitle('Quick Actions'),
        const SizedBox(height: 8),
        _buildQuickActions(),
        const SizedBox(height: 16),
        _sectionTitle('Public Holiday Calendar'),
        const SizedBox(height: 8),
        _holidayCard(),
        const SizedBox(height: 16),
        _sectionTitle('CCS Programme Statistics'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: tracks.map(_trackCard).toList(),
        ),
      ],
    ),
  );

  Widget _apiStatisticsCard() => FutureBuilder<List<Map<String, dynamic>>>(
    future: users,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _card(const LinearProgressIndicator());
      }
      if (snapshot.hasError) {
        return _card(
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Statistics unavailable'),
            subtitle: const Text('Could not load the user API data.'),
            trailing: IconButton(
              onPressed: _refreshApis,
              icon: const Icon(Icons.refresh),
            ),
          ),
        );
      }
      final records = snapshot.data ?? const <Map<String, dynamic>>[];
      final companies = records
          .map(
            (u) =>
                (u['company'] is Map ? (u['company'] as Map)['name'] : null)
                    as String?,
          )
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .toSet()
          .length;
      final emails = records
          .where((u) => (u['email'] as String? ?? '').trim().isNotEmpty)
          .length;
      final phones = records
          .where((u) => (u['phone'] as String? ?? '').trim().isNotEmpty)
          .length;
      return _card(
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    'Total users',
                    records.length,
                    Icons.people_outline,
                  ),
                ),
                Expanded(
                  child: _statTile(
                    'Companies',
                    companies,
                    Icons.business_outlined,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: _statTile('Emails', emails, Icons.email_outlined),
                ),
                Expanded(
                  child: _statTile(
                    'Phone numbers',
                    phones,
                    Icons.phone_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Counts are calculated from the JSONPlaceholder sample API.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    },
  );

  Widget _statTile(String label, int value, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: Row(
      children: [
        Icon(icon, color: AppTokens.maroonPrimary, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _postsPreviewCard() => FutureBuilder<List<Map<String, dynamic>>>(
    future: posts,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _card(const LinearProgressIndicator());
      }
      if (snapshot.hasError) {
        return _card(
          ListTile(
            title: const Text('Posts API unavailable'),
            trailing: IconButton(
              onPressed: _refreshApis,
              icon: const Icon(Icons.refresh),
            ),
          ),
        );
      }
      final items = (snapshot.data ?? const <Map<String, dynamic>>[])
          .take(2)
          .toList();
      return _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loaded ${snapshot.data?.length ?? 0} posts from JSONPlaceholder',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final post in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  radius: 15,
                  child: Text('${post['id'] ?? ''}'),
                ),
                title: Text(
                  post['title'] as String? ?? 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  post['body'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _profileCard() {
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTokens.maroonPrimary,
            child: Text(
              initials.isEmpty ? 'S' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$studentProgram · Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTokens.maroonPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text('LPU Cavite', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() => GridView.count(
    crossAxisCount: 3,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _QuickAction(
        label: 'Device',
        icon: Icons.devices_outlined,
        onTap: _showDeviceInfo,
      ),
      _QuickAction(
        label: 'GPS',
        icon: Icons.gps_fixed_outlined,
        status: _gpsLabel,
        statusColor: _gpsLabel == 'Active' ? Colors.green : Colors.orange,
        onTap: _refreshLocation,
      ),
      _QuickAction(label: 'API', icon: Icons.code_rounded, onTap: _showApiInfo),
      _QuickAction(
        label: 'Network',
        icon: Icons.wifi,
        status: _networkLabel,
        statusColor: _isWifiConnected ? Colors.green : Colors.orange,
        onTap: _showNetworkInfo,
      ),
      _QuickAction(
        label: 'Reports',
        icon: Icons.bar_chart_rounded,
        onTap: _showReports,
      ),
      _QuickAction(
        label: 'Settings',
        icon: Icons.settings_outlined,
        onTap: () => setState(() => tab = 3),
      ),
    ],
  );

  Widget _weatherCard() => FutureBuilder<Map<String, dynamic>>(
    future: weather,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _card(const LinearProgressIndicator());
      }
      if (snapshot.hasError) {
        return _card(
          ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Weather unavailable'),
            subtitle: Text('${snapshot.error}'),
            trailing: IconButton(
              onPressed: _refreshApis,
              icon: const Icon(Icons.refresh),
            ),
          ),
        );
      }
      final data = snapshot.data!;
      final temperature = (data['temperature_2m'] as num?)?.round() ?? 0;
      final feelsLike =
          (data['apparent_temperature'] as num?)?.round() ?? temperature;
      final humidity = (data['relative_humidity_2m'] as num?)?.round() ?? 0;
      final wind = (data['wind_speed_10m'] as num?)?.round() ?? 0;
      final condition = _weatherDescription(
        (data['weather_code'] as num?)?.toInt() ?? 0,
      );
      return _card(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.sunny, color: Color(0xFFF9A825), size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temperature°C · $condition',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Feels like $feelsLike°C · Humidity $humidity% · Wind $wind km/h',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppTokens.maroonPrimary,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh weather',
                onPressed: _refreshApis,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _holidayCard() => FutureBuilder<HolidayCalendarData>(
    future: holidays,
    builder: (context, snapshot) {
      final calendar = snapshot.data;
      return SwipeableWeekCalendarWidget(
        selectedDate: _selectedCalendarDate,
        onDateSelected: _selectCalendarDate,
        holidays: calendar?.holidays ?? const [],
        holidaysOffline: calendar?.isOffline ?? false,
        eventText: snapshot.connectionState == ConnectionState.waiting
            ? 'Loading Nager.Date holidays…'
            : 'No public holiday on this date.',
      );
    },
  );

  void _selectCalendarDate(DateTime date) {
    if (date.year == _selectedCalendarDate.year) {
      setState(() => _selectedCalendarDate = date);
      return;
    }
    setState(() {
      _selectedCalendarDate = date;
      holidays = _fetchHolidays();
      apiStatus = _checkApiStatus();
    });
  }

  String _weatherDescription(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Showers';
    if (code <= 86) return 'Snow showers';
    return 'Thunderstorm';
  }

  Widget _searchBar({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) => Container(
    height: 44,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    ),
  );

  Widget _filterChips({
    required List<String> choices,
    required String selected,
    required ValueChanged<String> onSelected,
  }) => Wrap(
    spacing: 8,
    children: [
      for (final choice in choices)
        ChoiceChip(
          label: Text(choice),
          selected: selected == choice,
          onSelected: (_) => onSelected(choice),
          selectedColor: AppTokens.maroonSubtle,
          labelStyle: TextStyle(
            color: selected == choice
                ? AppTokens.maroonPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: selected == choice
                ? AppTokens.maroonPrimary.withValues(alpha: 0.25)
                : Theme.of(context).dividerColor,
          ),
          showCheckmark: false,
        ),
    ],
  );

  Widget _directoryError(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 36),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _refreshApis,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _directoryRecordCard({
    required String name,
    required String subtitle,
    required String detail,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTokens.maroonPrimary,
              child: initials.isEmpty
                  ? Icon(icon, color: Colors.white, size: 19)
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _directoryEmpty(String message) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.search_off,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );

  Widget _directory() => FutureBuilder<List<Map<String, dynamic>>>(
    future: users,
    builder: (context, snapshot) {
      final rows = snapshot.data ?? const <Map<String, dynamic>>[];
      final query = _studentSearchQuery.toLowerCase();
      final filtered = rows.where((user) {
        final name = user['name'] as String? ?? '';
        final email = user['email'] as String? ?? '';
        final username = user['username'] as String? ?? '';
        final first = name.trim().isEmpty ? '' : name.trim()[0].toLowerCase();
        final matchesSearch =
            query.isEmpty ||
            name.toLowerCase().contains(query) ||
            email.toLowerCase().contains(query) ||
            username.toLowerCase().contains(query);
        final matchesFilter = switch (_studentFilter) {
          'A–M' => first.compareTo('a') >= 0 && first.compareTo('m') <= 0,
          'N–Z' => first.compareTo('n') >= 0 && first.compareTo('z') <= 0,
          _ => true,
        };
        return matchesSearch && matchesFilter;
      }).toList();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Student Directory'),
                const SizedBox(height: 3),
                Text(
                  'Sample users from JSONPlaceholder',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _searchBar(
                  controller: _studentSearchController,
                  hint: 'Search students...',
                  onChanged: (value) =>
                      setState(() => _studentSearchQuery = value.trim()),
                ),
                const SizedBox(height: 8),
                _filterChips(
                  choices: const ['All', 'A–M', 'N–Z'],
                  selected: _studentFilter,
                  onSelected: (value) => setState(() => _studentFilter = value),
                ),
              ],
            ),
          ),
          if (snapshot.connectionState == ConnectionState.waiting)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: snapshot.hasError
                ? _directoryError(
                    'Student directory unavailable. Check your connection and try again.',
                  )
                : snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? _directoryEmpty('No student records match your search.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final userName = user['name'] as String? ?? 'Student';
                      final username = user['username'] as String? ?? '';
                      return _directoryRecordCard(
                        name: userName,
                        subtitle: username.isEmpty
                            ? 'Sample API record'
                            : 'Sample API record · @$username',
                        detail: user['email'] as String? ?? '',
                        icon: Icons.person_outline,
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );

  Widget _facultyPage() {
    final query = _facultySearchQuery.toLowerCase();
    final filtered = facultyMembers.where((faculty) {
      final name = faculty['name']!.toLowerCase();
      final department = faculty['department']!.toLowerCase();
      final email = faculty['email']!.toLowerCase();
      final phone = faculty['phone']!.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          department.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
      final matchesFilter = switch (_facultyFilter) {
        'With phone' => phone.trim().isNotEmpty,
        'With email' => email.trim().isNotEmpty,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Faculty Directory'),
              const SizedBox(height: 3),
              Text(
                'Static mock faculty records for the lab requirement',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _searchBar(
                controller: _facultySearchController,
                hint: 'Search faculty...',
                onChanged: (value) =>
                    setState(() => _facultySearchQuery = value.trim()),
              ),
              const SizedBox(height: 8),
              _filterChips(
                choices: const ['All', 'With phone', 'With email'],
                selected: _facultyFilter,
                onSelected: (value) => setState(() => _facultyFilter = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _directoryEmpty('No faculty records match your search.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final faculty = filtered[index];
                    return _directoryRecordCard(
                      name: faculty['name']!,
                      subtitle: faculty['department']!,
                      detail: '${faculty['email']}\n${faculty['phone']}',
                      icon: Icons.badge_outlined,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _settings() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Settings',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF800000),
        ),
      ),
      const SizedBox(height: 12),
      _card(
        ListTile(
          leading: const Icon(Icons.api_outlined),
          title: const Text('API connections'),
          subtitle: const Text('Refresh Users, Weather, and Holidays'),
          trailing: IconButton(
            onPressed: _refreshApis,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ),
      FutureBuilder<String>(
        future: apiStatus,
        builder: (context, snapshot) => _card(
          ListTile(
            leading: Icon(
              snapshot.data == 'Online'
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_sync_outlined,
            ),
            title: const Text('API Status'),
            subtitle: Text(snapshot.data ?? 'Checking connections…'),
          ),
        ),
      ),
    ],
  );

  Widget _sectionTitle(String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.bold),
  );

  Widget _trackCard((String, String, int, Color) track) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .02),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.$1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              track.$2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: track.$4.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school_outlined, color: track.$4, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  '${track.$3}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          'Students',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _card(Widget child) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.status,
    this.statusColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? status;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: AppTokens.maroonPrimary, size: 24),
                    if (statusColor != null)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.cardColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    status!,
                    maxLines: 2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 8.5,
                      color: statusColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
