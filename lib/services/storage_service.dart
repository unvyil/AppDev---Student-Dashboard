import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Student {
  final String name;
  final String id;
  final String email;
  final String program;
  final String yearLevel;
  final String contact;
  final String address;
  final String status;
  final double attendance;

  const Student({
    required this.name,
    required this.id,
    required this.email,
    required this.program,
    required this.yearLevel,
    this.contact = '',
    this.address = '',
    this.status = 'Active',
    this.attendance = 0.95,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'email': email,
    'program': program,
    'yearLevel': yearLevel,
    'contact': contact,
    'address': address,
    'status': status,
    'attendance': attendance,
  };

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      program: json['program'] ?? '',
      yearLevel: json['yearLevel'] ?? '',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'Active',
      attendance: (json['attendance'] as num?)?.toDouble() ?? 0.95,
    );
  }
}

class RecentActivity {
  final String title;
  final String detail;
  final DateTime timestamp;

  const RecentActivity({
    required this.title,
    required this.detail,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'detail': detail,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
    title: json['title'] as String? ?? 'Activity',
    detail: json['detail'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

class StorageService {
  static const String _key = 'lpu_students';
  static const String _activityKey = 'lpu_recent_activity';

  static const List<Student> defaultStudents = [
    Student(
      name: 'Juan De La Cruz',
      id: '2024-2-00294',
      email: '2024-2-00294@lpunetwork.edu.ph',
      program: 'BSIT-NS',
      yearLevel: '3rd Year',
      contact: '+63 234 508 2435',
      address: 'General Trias, Cavite',
      status: 'Active',
      attendance: 0.95,
    ),
    Student(
      name: 'Juan De La Cruz',
      id: '2024-2-00295',
      email: '2024-2-00295@lpunetwork.edu.ph',
      program: 'BSIT-NS',
      yearLevel: '3rd Year',
      contact: '+63 234 508 2435',
      address: 'General Trias, Cavite',
      status: 'Active',
      attendance: 0.93,
    ),
    Student(
      name: 'Juan De La Cruz',
      id: '2024-2-00296',
      email: '2024-2-00296@lpunetwork.edu.ph',
      program: 'BSIT-NS',
      yearLevel: '3rd Year',
      contact: '+63 234 508 2435',
      address: 'General Trias, Cavite',
      status: 'Active',
      attendance: 0.88,
    ),
    Student(
      name: 'Juan De La Cruz',
      id: '2024-2-00297',
      email: '2024-2-00297@lpunetwork.edu.ph',
      program: 'BSIT-NS',
      yearLevel: '3rd Year',
      contact: '+63 234 508 2435',
      address: 'General Trias, Cavite',
      status: 'Inactive',
      attendance: 0.65,
    ),
    Student(
      name: 'Juan De La Cruz',
      id: '2024-2-00298',
      email: '2024-2-00298@lpunetwork.edu.ph',
      program: 'BSIT-NS',
      yearLevel: '3rd Year',
      contact: '+63 234 508 2435',
      address: 'General Trias, Cavite',
      status: 'Active',
      attendance: 0.95,
    ),
    Student(
      name: 'Juan De La Cruz',
      id: '2024-2-00299',
      email: '2024-2-00299@lpunetwork.edu.ph',
      program: 'BSIT-NS',
      yearLevel: '3rd Year',
      contact: '+63 234 508 2435',
      address: 'General Trias, Cavite',
      status: 'Active',
      attendance: 0.91,
    ),
  ];

  static Future<List<RecentActivity>> getRecentActivity() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_activityKey);
    if (raw == null) {
      return [
        RecentActivity(
          title: 'Logged in to portal',
          detail: 'Cavite Campus Network',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Activity data must be a JSON list.');
    }
    final list = decoded
        .whereType<Map>()
        .map(
          (item) => RecentActivity.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    if (list.isEmpty) {
      return [
        RecentActivity(
          title: 'Logged in to portal',
          detail: 'Cavite Campus Network',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
    }
    return list;
  }

  static Future<void> recordActivity(String title, String detail) async {
    final activities = await getRecentActivity();
    activities.insert(
      0,
      RecentActivity(title: title, detail: detail, timestamp: DateTime.now()),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _activityKey,
      jsonEncode(activities.take(10).map((item) => item.toJson()).toList()),
    );
  }

  static Future<List<Student>> getStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) {
      return List<Student>.from(defaultStudents);
    }

    final List<dynamic> decoded = jsonDecode(raw);
    final list = decoded
        .map((item) => Student.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    if (list.isEmpty) {
      return List<Student>.from(defaultStudents);
    }
    return list;
  }

  static Future<void> saveStudent(Student student) async {
    final students = await getStudents();

    final duplicate = students.any((existing) => existing.id == student.id);

    if (duplicate) {
      throw Exception('A student with this ID is already registered.');
    }

    students.add(student);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(students.map((s) => s.toJson()).toList()),
    );
    await recordActivity('Student registered', student.name);
  }

  static Future<void> updateStudent(String existingId, Student student) async {
    final students = await getStudents();
    final existingIndex = students.indexWhere(
      (existing) => existing.id == existingId,
    );
    if (existingIndex < 0) {
      throw Exception('The student record could not be found.');
    }
    final duplicate = students.any(
      (existing) => existing.id == student.id && existing.id != existingId,
    );
    if (duplicate) {
      throw Exception('A student with this ID is already registered.');
    }
    students[existingIndex] = student;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(students.map((item) => item.toJson()).toList()),
    );
    await recordActivity('Student profile updated', student.name);
  }

  static Future<void> deleteStudent(String id) async {
    final students = await getStudents();
    students.removeWhere((student) => student.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(students.map((s) => s.toJson()).toList()),
    );
  }
}
