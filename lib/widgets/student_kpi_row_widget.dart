import 'package:flutter/material.dart';

class StudentKpiRowWidget extends StatelessWidget {
  const StudentKpiRowWidget({
    super.key,
    this.totalStudents = 428,
    this.activeStudents = 401,
    this.activeTrend = '+4%',
    this.avgAttendance = '93%',
  });

  final int totalStudents;
  final int activeStudents;
  final String activeTrend;
  final String avgAttendance;

  Widget _buildCard({
    required String title,
    required String value,
    Widget? badge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                badge,
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Total Students',
            value: '$totalStudents',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard(
            title: 'Active Students',
            value: '$activeStudents',
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                activeTrend,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard(
            title: 'Avg. Attendance',
            value: avgAttendance,
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.arrow_upward,
                size: 9,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
