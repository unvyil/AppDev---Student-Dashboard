import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'storage_service.dart';

class FileService {
  static Future<Directory> getPublicExportDirectory() async {
    if (Platform.isAndroid) {
      final permission = await Permission.manageExternalStorage.request();
      if (!permission.isGranted) {
        throw FileSystemException(
          'Allow file access to export to the public Downloads folder.',
          '/storage/emulated/0/Download',
        );
      }
      // 1. Primary Android public user-accessible Download folder
      final publicDownload = Directory('/storage/emulated/0/Download');
      // Creating it here also gives a useful write error if Android denies
      // public storage access, instead of silently exporting into app-private
      // storage where the user cannot find the file.
      await publicDownload.create(recursive: true);
      return publicDownload;

    }

    // On Linux / macOS / Windows / iOS:
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir;
      }
    } catch (_) {}

    return await getApplicationDocumentsDirectory();
  }

  static Future<File> exportStudents() async {
    final directory = await getPublicExportDirectory();
    final file = File('${directory.path}/student_info.txt');

    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final buffer = StringBuffer()
      ..writeln('LPU STUDENT INFORMATION REPORT')
      ..writeln('Generated: $timestamp')
      ..writeln('Student Name: Novy Chariz Tablac')
      ..writeln('Student ID: 2024-2-02204')
      ..writeln('Program: BSIT-WM (3rd Year)')
      ..writeln('Email: 2024-2-02204@lpunetwork.edu.ph');

    await file.writeAsString(buffer.toString());
    await StorageService.recordActivity(
      'Student records exported',
      'Saved to ${file.path}',
    );

    return file;
  }

  static Future<String> readExportedFile() async {
    final directory = await getPublicExportDirectory();
    final file = File('${directory.path}/student_info.txt');

    if (!await file.exists()) {
      return 'No exported file yet.\n\nTap Export Student Records to create one.';
    }

    return file.readAsString();
  }

  static Future<String> getFilePath() async {
    final directory = await getPublicExportDirectory();
    return '${directory.path}/student_info.txt';
  }
}
