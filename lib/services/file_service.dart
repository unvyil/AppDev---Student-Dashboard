import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'storage_service.dart';

class FileService {
  static const _fileName = 'student_info.txt';

  /// App-private internal storage. This file is stored on the device and is
  /// retained between launches, but is not placed in Downloads or shared
  /// public storage.
  static Future<Directory> _internalExportDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/exports');
    await directory.create(recursive: true);
    return directory;
  }

  static Future<File> _writeAndVerify(String content) async {
    final directory = await _internalExportDirectory();
    final file = File('${directory.path}/$_fileName');
    await file.writeAsString(content, flush: true);
    if (!await file.exists() || await file.length() == 0) {
      throw FileSystemException(
        'Export file was not written successfully',
        file.path,
      );
    }
    if (await file.readAsString() != content) {
      throw FileSystemException('Export file verification failed', file.path);
    }
    return file;
  }

  static String _reportContents() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return 'LPU STUDENT INFORMATION REPORT\n'
        'Generated: $timestamp\n'
        'Student Name: Novy Chariz Tablac\n'
        'Student ID: 2024-2-02204\n'
        'Program: BSIT-WM (3rd Year)\n'
        'Email: 2024-2-02204@lpunetwork.edu.ph\n';
  }

  static Future<File> exportStudents() async {
    final file = await _writeAndVerify(_reportContents());
    try {
      await StorageService.recordActivity(
        'Student records exported',
        'Saved to internal storage: ${file.path}',
      );
    } catch (_) {
      // A history-write failure does not invalidate the saved file.
    }
    return file;
  }

  static Future<File?> _existingExport() async {
    final directory = await _internalExportDirectory();
    final file = File('${directory.path}/$_fileName');
    return await file.exists() ? file : null;
  }

  static Future<String> readExportedFile() async {
    final file = await _existingExport();
    if (file == null) {
      return 'No exported file yet.\n\nTap Export Student Records to create one.';
    }
    return file.readAsString();
  }

  static Future<String> getFilePath() async {
    final directory = await _internalExportDirectory();
    return '${directory.path}/$_fileName';
  }
}
