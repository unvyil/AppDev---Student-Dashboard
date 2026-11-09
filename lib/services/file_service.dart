import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'storage_service.dart';

class FileService {
  static Future<File> exportStudents() async {
    final students = await StorageService.getStudents();

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/student_info.txt');

    final buffer = StringBuffer()
      ..writeln('LPU STUDENT INFORMATION')
      ..writeln('Generated: ${DateTime.now()}')
      ..writeln('Total Students: ${students.length}')
      ..writeln(List.filled(35, '=').join())
      ..writeln();

    for (final student in students) {
      buffer
        ..writeln('Student Name: ${student.name}')
        ..writeln('Student ID: ${student.id}')
        ..writeln('Email: ${student.email}')
        ..writeln('Program: ${student.program}')
        ..writeln('Year Level: ${student.yearLevel}')
        ..writeln('Contact: ${student.contact}')
        ..writeln('Address: ${student.address}')
        ..writeln(List.filled(35, '-').join())
        ..writeln();
    }

    await file.writeAsString(buffer.toString());
    await StorageService.recordActivity(
      'Student records exported',
      '${students.length} record${students.length == 1 ? '' : 's'} exported',
    );
    return file;
  }

  static Future<String> readExportedFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/student_info.txt');

    if (!await file.exists()) {
      return 'No exported file yet.\n\nTap Export Student Information to create one.';
    }

    return file.readAsString();
  }

  static Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/student_info.txt';
  }
}
