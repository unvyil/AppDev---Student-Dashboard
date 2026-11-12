import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:all_lab_tablac_8/main.dart';
import 'package:all_lab_tablac_8/services/app_preferences.dart';
import 'package:all_lab_tablac_8/services/storage_service.dart';
import 'package:all_lab_tablac_8/widgets/ccs_program_stats_grid_widget.dart';
import 'package:all_lab_tablac_8/widgets/faculty_card.dart';
import 'package:all_lab_tablac_8/widgets/kpi_card.dart';
import 'package:all_lab_tablac_8/widgets/overview_card_widget.dart';
import 'package:all_lab_tablac_8/widgets/program_stat_card.dart';
import 'package:all_lab_tablac_8/widgets/quick_action_button.dart';
import 'package:all_lab_tablac_8/widgets/student_card.dart';
import 'package:all_lab_tablac_8/widgets/student_kpi_row_widget.dart';
import 'package:all_lab_tablac_8/widgets/swipeable_week_calendar_widget.dart';
import 'package:all_lab_tablac_8/widgets/weather_header_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
                  department:
                      'College of Information Technology and Computer Science (CCS)',
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
                const OverviewCardWidget(
                  email: '2024-2-02204@lpunetwork.edu.ph',
                ),
                const WeatherHeaderCardWidget(
                  temperature: 31,
                  condition: 'Sunny',
                  windSpeed: 7,
                  humidity: 56,
                  time: '10:49',
                  date: 'Tuesday, 27 October 2026',
                  location: 'Manggahan, General Trias',
                ),
                SwipeableWeekCalendarWidget(
                  selectedDate: DateTime(2026, 10, 27),
                  onDateSelected: (_) {},
                ),
                const StudentKpiRowWidget(),
                const CcsProgramStatsGridWidget(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Total Students'), findsWidgets);
    expect(find.text('Juan De La Cruz'), findsOneWidget);
    expect(find.text('Dr. Jane Doe'), findsOneWidget);
    expect(find.text('BSCS-DS'), findsWidgets);
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Email: 2024-2-02204@lpunetwork.edu.ph'), findsOneWidget);
    expect(find.text('31°C'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('CCS Programmes'), findsOneWidget);
  });

  testWidgets('App loads Home Overview, switches tabs to Users and Faculty',
      (tester) async {
    final preferences = AppPreferences();
    await preferences.load();
    await preferences.setUseMockData(true);

    await tester.pumpWidget(LpuStudentApp(preferences: preferences));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Home tab elements
    expect(find.text('LPU-Cavite Student Dashboard'), findsOneWidget);
    expect(find.text('Novy Chariz Tablac'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('World Clock'), findsOneWidget);
    expect(find.text('Academic Calendar'), findsOneWidget);

    // Verify correct student email
    expect(find.text('Email: 2024-2-02204@lpunetwork.edu.ph'), findsOneWidget);

    // Switch to Users tab
    await tester.tap(find.text('Users'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Program Stats'), findsOneWidget);
    expect(find.text('Total Students'), findsOneWidget);
    expect(find.text('Active Students'), findsOneWidget);
    expect(find.text('Avg. Attendance'), findsOneWidget);
    expect(find.text('+4%'), findsOneWidget);
    expect(find.text('Student List'), findsOneWidget);

    // Switch to Program Stats toggle
    await tester.tap(find.text('Program Stats'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('CCS Programmes'), findsOneWidget);
    expect(find.text('BSCS-DS'), findsOneWidget);
    expect(find.text('BSCS-SE'), findsOneWidget);
    expect(find.text('BSIT-NS'), findsOneWidget);
    expect(find.text('BSIT-WM'), findsOneWidget);

    // Switch to Faculty tab
    await tester.tap(find.text('Faculty'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Dr. Jane Doe'), findsWidgets);
    expect(find.text('Email'), findsWidgets);
    expect(find.text('Call'), findsWidgets);

    // Switch to Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Settings'), findsWidgets);

    // Tear down to cancel periodic timer
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
