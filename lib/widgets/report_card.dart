import 'package:flutter/material.dart';

import '../core/utils/date_time_utils.dart';
import '../models/report_model.dart';
import 'status_chip.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  final ReportModel report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          report.category,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Địa điểm: ${report.location}'),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text('Thời gian: ${DateTimeUtils.formatDateTime(report.createdAt)}'),
          ],
        ),
        trailing: StatusChip(status: report.status),
      ),
    );
  }
}
