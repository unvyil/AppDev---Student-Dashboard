import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'about_lpu_page.dart';
import 'auth_page.dart';
import 'registration_page.dart';
import 'services/app_preferences.dart';
import 'services/file_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/profile_avatar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.preferences,
    required this.onRefreshCache,
    this.showAppBar = true,
  });

  final AppPreferences preferences;
  final Future<void> Function() onRefreshCache;
  final bool showAppBar;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<List<Student>> _studentsFuture;
  bool _exporting = false;
  bool _clearing = false;
  bool _refreshing = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  void _loadStudent() {
    _studentsFuture = StorageService.getStudents();
  }

  Future<void> _exportStudents() async {
    setState(() => _exporting = true);
    try {
      final file = await FileService.exportStudents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File exported successfully to:\n${file.path}'),
          duration: const Duration(seconds: 4),
          backgroundColor: AppTokens.maroonPrimary,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _clearLocalStorage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local storage?'),
        content: const Text(
          'This permanently removes saved student records and app preferences '
          'from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _clearing = true);
    try {
      await widget.preferences.clearLocalStorage();
      await widget.onRefreshCache();
      if (!mounted) return;
      setState(_loadStudent);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Local storage cleared.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear local storage: $error')),
      );
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _refreshCache() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefreshCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard data refreshed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh dashboard data: $error')),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _networkDiagnostics() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final results = await Connectivity().checkConnectivity();
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Network diagnostics'),
          content: Text(
            'Network: ${results.map((result) => result.name).join(', ')}\n'
            'API check: HTTP ${response.statusCode}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Network diagnostics failed: $error')),
      );
    }
  }

  Future<void> _editProfile(Student? student) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => RegistrationPage(student: student)),
    );
    if (mounted) {
      setState(_loadStudent);
      await widget.onRefreshCache();
    }
  }

  Future<void> _editProfilePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from photos'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            if (widget.preferences.profilePhotoBase64 != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () async {
                  await _removeProfilePhoto();
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (photo == null) return;
      final Uint8List bytes = await photo.readAsBytes();
      await widget.preferences.setProfilePhoto(bytes);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile photo: $error')),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      await widget.preferences.setProfilePhoto(null);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove profile photo: $error')),
      );
    }
  }

  Future<void> _changeDarkMode(bool enabled) async {
    try {
      await widget.preferences.setDarkMode(enabled);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update theme: $error')));
    }
  }

  Future<void> _changeMockData(bool enabled) async {
    try {
      await widget.preferences.setUseMockData(enabled);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update data mode: $error')),
      );
    }
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
          'This student app stores registration records and preferences '
          'locally on this device. Weather, holiday, and directory requests '
          'are sent to their respective public APIs. This summary is not an '
          'official LPU privacy notice; refer to the University’s published '
          'privacy policy for official terms.',
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

  void _showSystemInfo() {
    final size = MediaQuery.sizeOf(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System information'),
        content: Text(
          'Platform: ${Theme.of(context).platform.name}\n'
          'Screen: ${size.width.round()} × ${size.height.round()} logical pixels\n'
          'Theme: ${widget.preferences.themeMode.name}',
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
    return AnimatedBuilder(
      animation: widget.preferences,
      builder: (context, child) {
        final content = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!widget.showAppBar)
                  IconButton(
                    tooltip: 'About LPU',
                    icon: const Icon(Icons.info_outline),
                    color: AppTokens.maroonPrimary,
                    onPressed: () => showAboutLpuModal(context),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Student>>(
              future: _studentsFuture,
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
                  return Card(
                    child: ListTile(
                      title: const Text('Unable to load profile'),
                      subtitle: Text('${snapshot.error}'),
                      trailing: IconButton(
                        tooltip: 'Retry',
                        onPressed: () => setState(_loadStudent),
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  );
                }
                final students = snapshot.data ?? const <Student>[];
                final student =
                    students
                        .where(
                          (item) => item.name.toLowerCase().contains('novy'),
                        )
                        .firstOrNull ??
                    (students.isEmpty ? null : students.first);
                final name = student?.name ?? 'Novy Chariz Tablac';
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
                    child: Row(
                      children: [
                        ProfileAvatar(
                          bytes: widget.preferences.profilePhotoBytes,
                          initials: initials,
                          radius: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                student?.id ?? '2023-1-00123',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                student?.program ?? 'BSIT-WM',
                                style: const TextStyle(
                                  color: Color(0xFF800000),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                student?.email ?? 'novy.tablac@lpu.edu.ph',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Edit profile',
                          onSelected: (action) {
                            if (action == 'photo') _editProfilePhoto();
                            if (action == 'details') _editProfile(student);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'photo',
                              child: Text('Edit profile photo'),
                            ),
                            PopupMenuItem(
                              value: 'details',
                              child: Text('Edit account details'),
                            ),
                          ],
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _sectionTitle('App & Data'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Export Student Records to File'),
                    subtitle: const Text(
                      'Save a plain-text file on this device',
                    ),
                    trailing: _exporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _exporting ? null : _exportStudents,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark mode'),
                    value: widget.preferences.themeMode == ThemeMode.dark,
                    onChanged: _changeDarkMode,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Clear Local Storage'),
                    subtitle: const Text(
                      'Remove saved records and preferences',
                    ),
                    trailing: _clearing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _clearing ? null : _clearLocalStorage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('API & System'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.api_outlined),
                    title: const Text('Use mock data'),
                    subtitle: const Text(
                      'Use local sample data instead of APIs',
                    ),
                    value: widget.preferences.useMockData,
                    onChanged: _changeMockData,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Refresh dashboard data'),
                    subtitle: const Text(
                      'Reload weather, calendar, and statuses',
                    ),
                    trailing: _refreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _refreshing ? null : _refreshCache,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.network_check),
                    title: const Text('Network Diagnostics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _networkDiagnostics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('About & Legal'),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('LPU Student App'),
                    subtitle: Text('Version 0.1.0+1'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.school_outlined,
                        color: AppTokens.maroonPrimary),
                    title: const Text('About LPU-Cavite'),
                    subtitle:
                        const Text('Vision, Mission, and Core Values (4L)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showAboutLpuModal(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('LPU Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showPrivacyPolicy,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.devices_outlined),
                    title: const Text('System Info'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showSystemInfo,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AuthPage(preferences: widget.preferences),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
        if (!widget.showAppBar) return content;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            actions: [
              IconButton(
                tooltip: 'About LPU',
                icon: const Icon(Icons.info_outline),
                onPressed: () => showAboutLpuModal(context),
              ),
            ],
          ),
          body: content,
        );
      },
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}
