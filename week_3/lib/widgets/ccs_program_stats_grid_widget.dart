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
      count: 100,
      icon: Icons.storage_rounded,
      iconColor: Color(0xFFE85D04),
      iconBackgroundColor: Color(0xFFFFEEE5),
    ),
    CcsProgramData(
      code: 'BSCS-SE',
      name: 'Software Engineering',
      count: 90,
      icon: Icons.code_rounded,
      iconColor: Color(0xFF2563EB),
      iconBackgroundColor: Color(0xFFEAF0FF),
    ),
    CcsProgramData(
      code: 'BSIT-NS',
      name: 'Network & Security',
      count: 120,
      icon: Icons.shield_outlined,
      iconColor: Color(0xFF0096C7),
      iconBackgroundColor: Color(0xFFE5F7FC),
    ),
    CcsProgramData(
      code: 'BSIT-WM',
      name: 'Web & Mobile Development',
      count: 150,
      icon: Icons.public_rounded,
      iconColor: Color(0xFF7B2CBF),
      iconBackgroundColor: Color(0xFFF3EAFE),
    ),
  ];

  Widget _buildCard(BuildContext context, CcsProgramData program) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF262626) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFFAFDEA)
        : const Color(0xFF171717);
    final secondaryTextColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isDark
            ? null
            : [
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      program.name,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 9,
                        color: secondaryTextColor,
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
                        color: isDark
                            ? const Color(0xFF333333)
                            : program.iconBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        program.icon,
                        color: isDark
                            ? const Color(0xFFE0B0B0)
                            : program.iconColor,
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
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textColor,
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
                    color: secondaryTextColor,
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
        Text(
          'CCS Programmes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: programs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: constraints.maxWidth < 360 ? 156 : 148,
            ),
            itemBuilder: (context, index) =>
                _buildCard(context, programs[index]),
          ),
        ),
      ],
    );
  }
}
