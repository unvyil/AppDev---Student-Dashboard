import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/ccs_program_stats_grid_widget.dart';

class ProgramStatsPage extends StatelessWidget {
  const ProgramStatsPage({super.key, this.onProgramSelected});

  final ValueChanged<String>? onProgramSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('CCS Program Statistics'),
        backgroundColor: AppTokens.maroonPrimary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CcsProgramStatsGridWidget(
                onProgramSelected: onProgramSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
