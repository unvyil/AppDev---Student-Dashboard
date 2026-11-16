import 'package:flutter/material.dart';

class StudentKpiRowWidget extends StatelessWidget {
  const StudentKpiRowWidget({
    super.key,
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.avgAttendance = '0%',
  });

  final int totalStudents;
  final int activeStudents;
  final String avgAttendance;

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 26,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        final gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _statCard(
                context,
                title: 'Total students',
                value: '$totalStudents',
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                context,
                title: 'Active students',
                value: '$activeStudents',
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                context,
                title: 'Avg. attendance',
                value: avgAttendance,
              ),
            ),
          ],
        );
      },
    );
  }
}
