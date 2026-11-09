import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.bytes,
    required this.initials,
    this.radius = 22,
    this.backgroundColor = const Color(0xFF800000),
    this.foregroundColor = Colors.white,
  });

  final Uint8List? bytes;
  final String initials;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final image = bytes;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: image == null
          ? Text(
              initials.isEmpty ? 'NT' : initials,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : ClipOval(
              child: Image.memory(
                image,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initials.isEmpty ? 'NT' : initials,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
