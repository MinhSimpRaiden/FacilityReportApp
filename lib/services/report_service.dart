import 'package:flutter/foundation.dart';

import '../core/constants/report_status.dart';
import '../models/report_model.dart';
import 'google_sheet_api_service.dart';

class ReportService {
  ReportService({GoogleSheetApiService? apiService})
      : _apiService = apiService ?? GoogleSheetApiService();

  final GoogleSheetApiService _apiService;

  final List<ReportModel> _mockReports = [
    ReportModel(
      id: 'sample-1',
      rowNumber: null,
      category: 'Máy lạnh trước',
      location: 'Phòng 10A1',
      description: 'Máy lạnh không lạnh',
      reporterName: 'Nguyễn Văn A',
      status: ReportStatus.pending,
      createdAt: DateTime(2026, 6, 10, 8, 0),
    ),
    ReportModel(
      id: 'sample-2',
      rowNumber: null,
      category: 'Đèn',
      location: 'Phòng 11A2',
      description: 'Đèn cuối lớp không sáng',
      reporterName: 'Trần Văn B',
      status: ReportStatus.pending,
      createdAt: DateTime(2026, 6, 10, 8, 15),
    ),
    ReportModel(
      id: 'sample-3',
      rowNumber: null,
      category: 'Bàn ghế',
      location: 'Phòng 12A3',
      description: 'Một bàn học bị gãy chân',
      reporterName: 'Lê Văn C',
      status: ReportStatus.unableToFix,
      createdAt: DateTime(2026, 6, 10, 8, 30),
      fixedAt: DateTime(2026, 6, 10, 9, 0),
      fixedBy: 'mock_staff',
    ),
  ];

  bool get isApiConfigured => _apiService.isConfigured;

  Stream<List<ReportModel>> watchReports() async* {
    yield await fetchReports();
  }

  Future<List<ReportModel>> fetchReports() async {
    if (!isApiConfigured) {
      debugPrint('Apps Script API not configured. Using mock reports.');
      return _sortedMockReports();
    }

    try {
      final reports = await _apiService.fetchReports();
      return reports.isEmpty ? _sortedMockReports() : reports;
    } catch (error) {
      debugPrint('Apps Script fetchReports failed. Using mock reports: $error');
      return _sortedMockReports();
    }
  }

  Future<List<ReportModel>> markReportFixed({
    required String reportId,
    required String fixedBy,
  }) {
    return updateReportStatus(
      reportId: reportId,
      status: ReportStatus.fixed,
      fixedBy: fixedBy,
    );
  }

  Future<List<ReportModel>> markReportUnableToFix({
    required String reportId,
    required String fixedBy,
  }) {
    return updateReportStatus(
      reportId: reportId,
      status: ReportStatus.unableToFix,
      fixedBy: fixedBy,
    );
  }

  Future<List<ReportModel>> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    required String fixedBy,
  }) async {
    const fixedByValue = 'mock_staff';
    debugPrint('Updating report $reportId to ${status.value} via Apps Script');

    if (!isApiConfigured) {
      debugPrint('Apps Script API not configured. Updating mock report.');
      _updateMockReportStatus(
        reportId: reportId,
        status: status,
        fixedBy: fixedByValue,
      );
      debugPrint('Update success');
      return _sortedMockReports();
    }

    Object? postError;

    try {
      await _apiService.updateReportStatus(
        reportId,
        status.value,
        fixedBy: fixedByValue,
      );
      debugPrint('Update success');
    } catch (error) {
      postError = error;
      debugPrint('updateReportStatus POST returned an error, verifying with refresh: $error');
    }

    final refreshedReports = await _apiService.fetchReports();
    final refreshedReport = _findReport(refreshedReports, reportId);

    if (refreshedReport?.status == status) {
      debugPrint(
        'Report $reportId is ${status.value} after refresh. Treating update as success.',
      );
      return refreshedReports;
    }

    if (postError != null) {
      throw Exception(
        'Không thể xác nhận cập nhật trạng thái. Yêu cầu lỗi và báo cáo chưa đổi sau khi tải lại.',
      );
    }

    throw Exception(
      'Apps Script báo thành công nhưng báo cáo chưa chuyển trạng thái.',
    );
  }

  List<ReportModel> _sortedMockReports() {
    final sortedReports = [..._mockReports];
    sortedReports.sort((a, b) {
      if (a.hasValidCreatedAt != b.hasValidCreatedAt) {
        return a.hasValidCreatedAt ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sortedReports;
  }

  void _updateMockReportStatus({
    required String reportId,
    required ReportStatus status,
    required String fixedBy,
  }) {
    final index = _mockReports.indexWhere((report) => report.id == reportId);
    if (index == -1) {
      return;
    }

    _mockReports[index] = _mockReports[index].copyWith(
      status: status,
      fixedAt: DateTime.now(),
      fixedBy: fixedBy,
    );
  }

  ReportModel? _findReport(List<ReportModel> reports, String reportId) {
    for (final report in reports) {
      if (report.id == reportId) {
        return report;
      }
    }
    return null;
  }
}
