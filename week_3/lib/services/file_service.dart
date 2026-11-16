import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'storage_service.dart';

class FileService {
  static const _fileName = 'student_info.txt';

  /// Required app Documents copy, accessible through Android Studio's
  /// Device File Explorer.
  static Future<Directory> _internalExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
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

  static Future<String> _reportContents() async {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final students = await StorageService.getStudents();
    final records = students.isEmpty
        ? 'No student records.'
        : students
              .map(
                (student) => [
                  'Name: ${student.name}',
                  'ID: ${student.id}',
                  'Program: ${student.program}',
                  'Year: ${student.yearLevel}',
                  'Email: ${student.email}',
                  if (student.contact.isNotEmpty) 'Contact: ${student.contact}',
                  if (student.address.isNotEmpty) 'Address: ${student.address}',
                  'Status: ${student.status}',
                  'Attendance: ${(student.attendance * 100).round()}%',
                ].join('\n'),
              )
              .join('\n\n');

    return 'STUDENT INFORMATION\n'
        'Generated: $timestamp\n'
        'Student count: ${students.length}\n\n'
        '$records\n';
  }

  static Future<File> exportStudents() async {
    final content = await _reportContents();
    final file = await _writeAndVerify(content);
    try {
      await StorageService.recordActivity(
        'Student records exported',
        'Saved to app-private Documents storage',
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
