import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_time_utils.dart';
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
        update: () => context.read<ReportProvider>().markReportFixed(
              reportId: widget.reportId,
              fixedBy: 'mock_staff',
            ),
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
        update: () => context.read<ReportProvider>().markReportUnableToFix(
              reportId: widget.reportId,
              fixedBy: 'mock_staff',
            ),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  report.category,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              StatusChip(status: report.status),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Địa điểm', value: report.location),
          _DetailRow(label: 'Mô tả', value: report.description),
          _DetailRow(label: 'Người báo tin', value: report.reporterName),
          _DetailRow(
            label: 'Thời gian báo',
            value: DateTimeUtils.formatDateTime(report.createdAt),
          ),
          _DetailRow(
            label: 'Thời gian xử lý',
            value: DateTimeUtils.formatDateTime(report.fixedAt),
          ),
          _DetailRow(label: 'Người xử lý', value: report.fixedBy ?? 'Chưa có'),
          const SizedBox(height: 24),
          if (report.isPending) ...[
            FilledButton.icon(
              onPressed: _isSaving ? null : _confirmAndMarkFixed,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('ĐÃ SỬA'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _confirmAndMarkUnableToFix,
              icon: const Icon(Icons.close),
              label: const Text('KHÔNG THỂ SỬA'),
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
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
