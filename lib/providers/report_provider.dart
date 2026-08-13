import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/report_status.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider(this._reportService) {
    _listenToReports();
  }

  static const String allCategoriesLabel = 'Tất cả hạng mục';
  static const String allStatusesLabel = 'Tất cả trạng thái';

  final ReportService _reportService;
  StreamSubscription<List<ReportModel>>? _reportsSubscription;

  List<ReportModel> _allReports = [];
  String _selectedCategory = allCategoriesLabel;
  String _selectedStatus = allStatusesLabel;
  Set<String> _knownReportIds = {};
  bool _hasCompletedFirstLoad = false;
  int _newReportNotificationVersion = 0;

  bool isLoading = true;
  String? errorMessage;
  ReportModel? latestNewReport;

  List<ReportModel> get reports => List.unmodifiable(_allReports);

  List<ReportModel> get filteredReports {
    return List.unmodifiable(
      _allReports.where((report) {
        final categoryMatches = _selectedCategory == allCategoriesLabel ||
            report.category == _selectedCategory;
        final statusMatches = _selectedStatus == allStatusesLabel ||
            report.status.label == _selectedStatus;
        return categoryMatches && statusMatches;
      }),
    );
  }

  List<String> get categories {
    final categories = _allReports
        .map((report) => report.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return [allCategoriesLabel, ...categories];
  }

  List<String> get statuses {
    return [
      allStatusesLabel,
      ReportStatus.pending.label,
      ReportStatus.fixed.label,
      ReportStatus.unableToFix.label,
    ];
  }

  String get selectedCategory => _selectedCategory;

  String get selectedStatus => _selectedStatus;

  int get newReportNotificationVersion => _newReportNotificationVersion;

  void setSelectedCategory(String value) {
    if (_selectedCategory == value) {
      return;
    }

    _selectedCategory = value;
    notifyListeners();
  }

  void setSelectedStatus(String value) {
    if (_selectedStatus == value) {
      return;
    }

    _selectedStatus = value;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = allCategoriesLabel;
    _selectedStatus = allStatusesLabel;
    notifyListeners();
  }

  void refreshReports() {
    _listenToReports(resetFirstLoad: true);
  }

  ReportModel? reportById(String reportId) {
    for (final report in _allReports) {
      if (report.id == reportId) {
        return report;
      }
    }
    return null;
  }

  Future<void> markReportFixed({
    required String reportId,
    required String fixedBy,
  }) async {
    final reports = await _reportService.markReportFixed(
      reportId: reportId,
      fixedBy: fixedBy,
    );
    _applyUpdatedReports(reports);
  }

  Future<void> markReportUnableToFix({
    required String reportId,
    required String fixedBy,
  }) async {
    final reports = await _reportService.markReportUnableToFix(
      reportId: reportId,
      fixedBy: fixedBy,
    );
    _applyUpdatedReports(reports);
  }

  int get totalCount => _allReports.length;

  int get pendingCount {
    return _allReports
        .where((report) => report.status == ReportStatus.pending)
        .length;
  }

  int get fixedCount {
    return _allReports
        .where((report) => report.status == ReportStatus.fixed)
        .length;
  }

  int get unableToFixCount {
    return _allReports
        .where((report) => report.status == ReportStatus.unableToFix)
        .length;
  }

  void _applyUpdatedReports(List<ReportModel> reports) {
    _setReports(reports);
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  void _listenToReports({bool resetFirstLoad = false}) {
    isLoading = true;
    errorMessage = null;

    if (resetFirstLoad) {
      _hasCompletedFirstLoad = false;
      latestNewReport = null;
    }

    notifyListeners();

    _reportsSubscription?.cancel();
    _reportsSubscription = _reportService.watchReports().listen(
      (reports) {
        _detectNewReports(reports);
        _setReports(reports);
        _hasCompletedFirstLoad = true;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        errorMessage = error.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void _setReports(List<ReportModel> reports) {
    final sortedReports = [...reports]..sort(_compareNewestFirst);
    _allReports = sortedReports;
    _knownReportIds = sortedReports.map((report) => report.id).toSet();

    final categoryStillExists =
        _selectedCategory == allCategoriesLabel ||
            _allReports.any((report) => report.category == _selectedCategory);
    if (!categoryStillExists) {
      _selectedCategory = allCategoriesLabel;
    }

    final statusStillExists = statuses.contains(_selectedStatus);
    if (!statusStillExists) {
      _selectedStatus = allStatusesLabel;
    }
  }

  int _compareNewestFirst(ReportModel a, ReportModel b) {
    if (a.hasValidCreatedAt != b.hasValidCreatedAt) {
      return a.hasValidCreatedAt ? -1 : 1;
    }

    return b.createdAt.compareTo(a.createdAt);
  }

  void _detectNewReports(List<ReportModel> reports) {
    if (!_hasCompletedFirstLoad) {
      return;
    }

    final addedReports = reports
        .where((report) => !_knownReportIds.contains(report.id))
        .toList();

    if (addedReports.isEmpty) {
      return;
    }

    addedReports.sort(_compareNewestFirst);
    latestNewReport = addedReports.first;
    _newReportNotificationVersion += 1;
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }
}
