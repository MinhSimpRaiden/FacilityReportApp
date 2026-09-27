import 'package:flutter/material.dart';

import '../core/constants/report_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  _StatusColors _colorsForStatus(ReportStatus status) {
    return switch (status) {
      ReportStatus.fixed => _StatusColors(
          background: Colors.green.shade100,
          foreground: Colors.green.shade900,
        ),
      ReportStatus.unableToFix => _StatusColors(
          background: Colors.red.shade100,
          foreground: Colors.red.shade900,
        ),
      ReportStatus.pending => _StatusColors(
          background: Colors.orange.shade100,
          foreground: Colors.orange.shade900,
        ),
    };
  }
}

class _StatusColors {
  const _StatusColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
