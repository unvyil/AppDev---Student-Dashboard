import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:all_lab_tablac_8/main.dart';
import 'package:all_lab_tablac_8/services/app_preferences.dart';
import 'package:all_lab_tablac_8/services/storage_service.dart';
import 'package:all_lab_tablac_8/widgets/faculty_card.dart';
import 'package:all_lab_tablac_8/widgets/kpi_card.dart';
import 'package:all_lab_tablac_8/widgets/program_stat_card.dart';
import 'package:all_lab_tablac_8/widgets/quick_action_button.dart';
import 'package:all_lab_tablac_8/widgets/student_card.dart';

void main() {
  testWidgets('Renders all modular widgets cleanly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const KpiCard(
                  title: 'Total Students',
                  value: '428',
                  badge: '+7%',
                ),
                const StudentCard(
                  student: Student(
                    name: 'Juan De La Cruz',
                    id: '2024-2-00294',
                    email: '2024-2-00294@lpunetwork.edu.ph',
                    program: 'BSIT-NS',
                    yearLevel: '3rd Year',
                    contact: '+63 234 508 2435',
                    status: 'Active',
                    attendance: 0.95,
                  ),
                ),
                FacultyCard(
                  name: 'Dr. Jane Doe',
                  department: 'College of Information Technology and Computer Science (CCS)',
                  email: '2024-2-00294@lpunetwork.edu.ph',
                  phone: '+63 234 508 2435',
                  onEmailTap: () {},
                  onCallTap: () {},
                ),
                ProgramStatCard(
                  code: 'BSCS-DS',
                  name: 'Data Science',
                  count: 96,
                  icon: Icons.storage,
                  iconColor: Colors.orange,
                  iconBackgroundColor: Colors.orange.shade50,
                ),
                QuickActionButton(
                  label: 'Device',
                  icon: Icons.devices,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Total Students'), findsOneWidget);
    expect(find.text('Juan De La Cruz'), findsOneWidget);
    expect(find.text('Dr. Jane Doe'), findsOneWidget);
    expect(find.text('BSCS-DS'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
  });

  testWidgets('App loads Home Overview, switches tabs to Users and Faculty',
      (tester) async {
    final preferences = AppPreferences();
    await tester.pumpWidget(LpuStudentApp(preferences: preferences));
    await tester.pump();

    // Verify Home tab elements
    expect(find.text('LPU-Cavite Student Dashboard'), findsOneWidget);
    expect(find.text('Novy Chariz Tablac'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);

    // Switch to Users tab
    await tester.tap(find.text('Users'));
    await tester.pump();

    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Program Stats'), findsOneWidget);
    expect(find.text('Total Students'), findsOneWidget);
    expect(find.text('Active Students'), findsOneWidget);
    expect(find.text('Avg. Attendance'), findsOneWidget);

    // Switch to Program Stats toggle
    await tester.tap(find.text('Program Stats'));
    await tester.pump();

    expect(find.text('CCS Programmes'), findsOneWidget);
    expect(find.text('BSCS-DS'), findsOneWidget);
    expect(find.text('BSCS-SE'), findsOneWidget);
    expect(find.text('BSIT-NS'), findsOneWidget);
    expect(find.text('BSIT-WM'), findsOneWidget);

    // Switch to Faculty tab
    await tester.tap(find.text('Faculty'));
    await tester.pump();

    expect(find.text('Dr. Jane Doe'), findsWidgets);
    expect(find.text('Email'), findsWidgets);
    expect(find.text('Call'), findsWidgets);

    // Switch to Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(find.text('Settings'), findsWidgets);
  });
}
