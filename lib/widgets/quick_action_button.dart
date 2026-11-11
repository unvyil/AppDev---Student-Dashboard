import 'package:flutter/material.dart';

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF800000),
    this.statusDotColor,
    this.statusText,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color? statusDotColor;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                    if (statusDotColor != null)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusDotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                if (statusText != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    statusText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      color: statusDotColor ?? Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
