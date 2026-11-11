import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'profile_avatar.dart';

class OverviewCardWidget extends StatelessWidget {
  const OverviewCardWidget({
    super.key,
    this.name = 'Novy Chariz Tablac',
    this.studentId = '2024-2-02204',
    this.program = 'BSIT-WM',
    this.yearLevel = '3rd Year',
    this.email = '2024-2-02204@lpunetwork.edu.ph',
    this.profilePhotoBytes,
    this.onEditProfile,
    this.onViewFullProfile,
  });

  final String name;
  final String studentId;
  final String program;
  final String yearLevel;
  final String email;
  final Uint8List? profilePhotoBytes;
  final VoidCallback? onEditProfile;
  final VoidCallback? onViewFullProfile;

  static const Color maroonColor = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                bytes: profilePhotoBytes,
                initials: 'N',
                radius: 22,
                backgroundColor: maroonColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                        if (onViewFullProfile != null)
                          GestureDetector(
                            onTap: onViewFullProfile,
                            child: const Text(
                              'View Full Profile',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: maroonColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$studentId • $program • $yearLevel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Email: $email',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: maroonColor,
                side: const BorderSide(color: maroonColor, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
