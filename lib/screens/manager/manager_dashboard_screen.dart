import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/report_provider.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê quản lý')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatTile(
              label: 'Tổng báo cáo',
              value: reportProvider.totalCount.toString(),
              color: Colors.blue,
            ),
            _StatTile(
              label: 'Đang chờ',
              value: reportProvider.pendingCount.toString(),
              color: Colors.orange,
            ),
            _StatTile(
              label: 'Đã sửa',
              value: reportProvider.fixedCount.toString(),
              color: Colors.green,
            ),
            _StatTile(
              label: 'Không thể sửa',
              value: reportProvider.unableToFixCount.toString(),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(label),
      ),
    );
  }
}
