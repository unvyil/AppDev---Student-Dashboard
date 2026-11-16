import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  late Future<Student?> _profileFuture;
  bool _exporting = false;
  bool _clearing = false;
  bool _refreshing = false;
  bool _changingMockData = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = StorageService.getProfile();
  }

  Future<void> _exportStudents() async {
    setState(() => _exporting = true);
    try {
      await FileService.exportStudents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File exported successfully to ${await FileService.getFilePath()}',
          ),
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

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF800000),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.preferences.logout();
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
      setState(_loadProfile);
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
      await StorageService.recordActivity(
        'Dashboard data refreshed',
        'Manual refresh',
      );
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
      final hasNetwork = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!hasNetwork) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Network diagnostics'),
            content: const Text(
              'No network connection is available. Student and faculty data will use the last locally cached JSONPlaceholder records.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        return;
      }
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
      MaterialPageRoute(
        builder: (_) =>
            RegistrationPage(student: student, isProfileEditor: true),
      ),
    );
    if (mounted) {
      setState(_loadProfile);
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
      await StorageService.recordActivity(
        enabled ? 'Dark mode enabled' : 'Dark mode disabled',
        'Display settings',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update theme: $error')));
    }
  }

  Future<void> _changeMockData(bool enabled) async {
    if (_changingMockData || enabled == widget.preferences.useMockData) return;
    setState(() => _changingMockData = true);
    try {
      await widget.preferences.setUseMockData(enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Mock data enabled for Users and Faculty.'
                  : 'Live directory data restored.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _recordMockDataActivity(enabled);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update data mode: $error')),
      );
    } finally {
      if (mounted) setState(() => _changingMockData = false);
    }
  }

  Future<void> _recordMockDataActivity(bool enabled) async {
    try {
      await StorageService.recordActivity(
        enabled ? 'Mock data enabled' : 'Mock data disabled',
        enabled
            ? 'Using JSONPlaceholder directory data'
            : 'Using saved portal data',
      );
    } catch (error) {
      debugPrint('Could not record mock data activity: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.preferences,
      builder: (context, child) {
        final content = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Student?>(
              future: _profileFuture,
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
                        onPressed: () => setState(_loadProfile),
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  );
                }
                final student = snapshot.data;
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                student?.id ?? '2023-1-00123',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              Text(
                                student?.program ?? 'BSIT-WM',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                student?.email ?? 'novy.tablac@lpu.edu.ph',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                    secondary: _changingMockData
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.api_outlined),
                    title: const Text('Use mock data'),
                    subtitle: const Text(
                      'Switch Users and Faculty directories to sample data',
                    ),
                    value: widget.preferences.useMockData,
                    onChanged: _changingMockData ? null : _changeMockData,
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _logOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF800000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
        if (!widget.showAppBar) return content;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
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
