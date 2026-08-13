enum ReportStatus {
  pending('PENDING', 'Đang chờ'),
  fixed('FIXED', 'Đã sửa'),
  unableToFix('UNABLE_TO_FIX', 'Không thể sửa');

  const ReportStatus(this.value, this.label);

  final String value;
  final String label;

  static ReportStatus fromString(String value) {
    final normalizedValue = value.trim().toUpperCase();
    return ReportStatus.values.firstWhere(
      (status) => status.value == normalizedValue,
      orElse: () => ReportStatus.pending,
    );
  }
}
