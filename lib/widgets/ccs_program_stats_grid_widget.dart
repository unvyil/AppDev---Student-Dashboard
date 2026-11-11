import 'package:flutter/material.dart';

class CcsProgramData {
  final String code;
  final String name;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String statusText;

  const CcsProgramData({
    required this.code,
    required this.name,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.statusText = 'Actively Enrolled',
  });
}

class CcsProgramStatsGridWidget extends StatelessWidget {
  const CcsProgramStatsGridWidget({
    super.key,
    this.programs = defaultPrograms,
    this.onProgramSelected,
  });

  final List<CcsProgramData> programs;
  final ValueChanged<String>? onProgramSelected;

  static const List<CcsProgramData> defaultPrograms = [
    CcsProgramData(
      code: 'BSCS-DS',
      name: 'Data Science',
      count: 96,
      icon: Icons.storage_rounded,
      iconColor: Color(0xFFE65100),
      iconBackgroundColor: Color(0xFFFFF3E0),
    ),
    CcsProgramData(
      code: 'BSCS-SE',
      name: 'Software Engineering',
      count: 104,
      icon: Icons.code_rounded,
      iconColor: Color(0xFF1565C0),
      iconBackgroundColor: Color(0xFFE3F2FD),
    ),
    CcsProgramData(
      code: 'BSIT-NS',
      name: 'Network & Security',
      count: 128,
      icon: Icons.shield_outlined,
      iconColor: Color(0xFF00838F),
      iconBackgroundColor: Color(0xFFE0F7FA),
    ),
    CcsProgramData(
      code: 'BSIT-WM',
      name: 'Web & Mobile Technology',
      count: 142,
      icon: Icons.public_rounded,
      iconColor: Color(0xFF7B1FA2),
      iconBackgroundColor: Color(0xFFF3E5F5),
    ),
  ];

  Widget _buildCard(BuildContext context, CcsProgramData program) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onProgramSelected?.call(program.code),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      program.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: program.iconBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        program.icon,
                        color: program.iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${program.count}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  program.statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CCS Programmes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: programs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 140,
          ),
          itemBuilder: (context, index) => _buildCard(context, programs[index]),
        ),
      ],
    );
  }
}
