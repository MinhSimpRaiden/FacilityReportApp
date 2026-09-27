import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/google_sheet_api_service.dart';
import '../../widgets/report_card.dart';
import '../manager/manager_dashboard_screen.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  int _lastNotificationVersion = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<ReportProvider>().removeListener(_showNewReportSnackBar);
    context.read<ReportProvider>().addListener(_showNewReportSnackBar);
  }

  @override
  void dispose() {
    context.read<ReportProvider>().removeListener(_showNewReportSnackBar);
    super.dispose();
  }

  void _showNewReportSnackBar() {
    final reportProvider = context.read<ReportProvider>();
    final newReport = reportProvider.latestNewReport;
    final version = reportProvider.newReportNotificationVersion;

    if (!mounted || newReport == null || version == _lastNotificationVersion) {
      return;
    }

    _lastNotificationVersion = version;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Có báo cáo mới',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${newReport.category} - ${newReport.location}'),
          ],
        ),
      ),
    );
  }

  Future<void> _testAppsScriptConnection() async {
    try {
      final result = await GoogleSheetApiService().testConnection();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kết nối Apps Script OK: ${result['count']} báo cáo.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi Apps Script: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final reportProvider = context.watch<ReportProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách báo hỏng'),
        actions: [
          IconButton(
            tooltip: 'Test Apps Script Connection',
            onPressed: _testAppsScriptConnection,
            icon: const Icon(Icons.bug_report),
          ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: reportProvider.refreshReports,
            icon: const Icon(Icons.refresh),
          ),
          if (user?.role == UserRole.manager)
            IconButton(
              tooltip: 'Thống kê',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart),
            ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: authProvider.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _ReportListBody(reportProvider: reportProvider),
    );
  }
}

class _ReportListBody extends StatelessWidget {
  const _ReportListBody({required this.reportProvider});

  final ReportProvider reportProvider;

  @override
  Widget build(BuildContext context) {
    if (reportProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reportProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Không thể tải báo cáo: ${reportProvider.errorMessage}'),
        ),
      );
    }

    if (reportProvider.reports.isEmpty) {
      return const Center(child: Text('Chưa có báo cáo nào.'));
    }

    final filteredReports = reportProvider.filteredReports;

    return Column(
      children: [
        _FilterDropdowns(reportProvider: reportProvider),
        Expanded(
          child: filteredReports.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có dữ liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không có báo cáo nào phù hợp với bộ lọc hiện tại.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => reportProvider.refreshReports(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return ReportCard(
                        report: report,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportDetailScreen(
                                reportId: report.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterDropdowns extends StatelessWidget {
  const _FilterDropdowns({required this.reportProvider});

  final ReportProvider reportProvider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: reportProvider.selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Hạng mục',
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                icon: Icon(Icons.category_outlined, color: Colors.blue.shade700, size: 20),
                items: reportProvider.categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    reportProvider.setSelectedCategory(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: reportProvider.selectedStatus,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                icon: Icon(Icons.filter_list, color: Colors.blue.shade700, size: 20),
                items: reportProvider.statuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    reportProvider.setSelectedStatus(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
