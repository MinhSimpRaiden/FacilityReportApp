import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/status_chip.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isSaving = false;

  Future<void> _confirmAndMarkFixed() async {
    final confirmed = await _showConfirmDialog(
      title: 'Xác nhận đã sửa',
      message:
          'Anh/chị chắc chắn muốn chuyển báo cáo này sang trạng thái Đã sửa?',
    );

    if (confirmed) {
      await _updateStatus(
        update: () {
          final currentUser = context.read<AuthProvider>().currentUser;
          return context.read<ReportProvider>().markReportFixed(
            reportId: widget.reportId,
            fixedBy: currentUser?.fullName ?? 'Khuyết danh',
          );
        },
        successMessage: 'Đã cập nhật trạng thái thành ĐÃ SỬA',
      );
    }
  }

  Future<void> _confirmAndMarkUnableToFix() async {
    final confirmed = await _showConfirmDialog(
      title: 'Xác nhận không thể sửa',
      message:
          'Anh/chị chắc chắn muốn chuyển báo cáo này sang trạng thái Không thể sửa?',
    );

    if (confirmed) {
      await _updateStatus(
        update: () {
          final currentUser = context.read<AuthProvider>().currentUser;
          return context.read<ReportProvider>().markReportUnableToFix(
            reportId: widget.reportId,
            fixedBy: currentUser?.fullName ?? 'Khuyết danh',
          );
        },
        successMessage: 'Đã chuyển trạng thái thành Không thể sửa.',
      );
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _updateStatus({
    required Future<void> Function() update,
    required String successMessage,
  }) async {
    setState(() => _isSaving = true);

    try {
      await update();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _friendlyErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('Apps Script returned HTML') ||
        text.contains('FormatException')) {
      return 'Không thể xác nhận cập nhật. Vui lòng tải lại danh sách và kiểm tra Apps Script.';
    }
    return 'Không thể cập nhật: $text';
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>().reportById(widget.reportId);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết báo hỏng')),
        body: const Center(child: Text('Không tìm thấy báo cáo.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết báo hỏng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.category,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      StatusChip(status: report.status),
                    ],
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Địa điểm',
                    value: report.location,
                    icon: Icons.location_on_outlined,
                  ),
                  _DetailRow(
                    label: 'Mô tả',
                    value: report.description,
                    icon: Icons.description_outlined,
                  ),
                  _DetailRow(
                    label: 'Người báo tin',
                    value: report.reporterName,
                    icon: Icons.person_outline,
                  ),
                  _DetailRow(
                    label: 'Thời gian báo',
                    value: DateTimeUtils.formatDateTime(report.createdAt),
                    icon: Icons.access_time,
                  ),
                  _DetailRow(
                    label: 'Thời gian xử lý',
                    value: DateTimeUtils.formatDateTime(report.fixedAt),
                    icon: Icons.update,
                  ),
                  _DetailRow(
                    label: 'Người xử lý',
                    value: report.fixedBy ?? 'Chưa có',
                    icon: Icons.engineering_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (report.isPending) ...[
            FilledButton.icon(
              onPressed: _isSaving ? null : _confirmAndMarkFixed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('ĐÃ SỬA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _confirmAndMarkUnableToFix,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('KHÔNG THỂ SỬA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
