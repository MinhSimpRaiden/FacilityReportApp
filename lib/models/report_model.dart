import '../core/constants/report_status.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.rowNumber,
    required this.category,
    required this.location,
    required this.description,
    required this.reporterName,
    required this.status,
    required this.createdAt,
    this.fixedAt,
    this.fixedBy,
  });

  final String id;
  final int? rowNumber;
  final String category;
  final String location;
  final String description;
  final String reporterName;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? fixedAt;
  final String? fixedBy;

  bool get isPending => status == ReportStatus.pending;

  bool get isFixed => status == ReportStatus.fixed;

  bool get isUnableToFix => status == ReportStatus.unableToFix;

  String get statusText => status.label;

  bool get hasValidCreatedAt => createdAt.millisecondsSinceEpoch > 0;

  ReportModel copyWith({
    String? id,
    int? rowNumber,
    String? category,
    String? location,
    String? description,
    String? reporterName,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? fixedAt,
    String? fixedBy,
  }) {
    return ReportModel(
      id: id ?? this.id,
      rowNumber: rowNumber ?? this.rowNumber,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,
      reporterName: reporterName ?? this.reporterName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fixedAt: fixedAt ?? this.fixedAt,
      fixedBy: fixedBy ?? this.fixedBy,
    );
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: _stringValue(json['id'] ?? json['reportId']),
      rowNumber: _intValue(json['rowNumber']),
      category: _stringValue(json['category']),
      location: _stringValue(json['location']),
      description: _stringValue(json['description']),
      reporterName: _stringValue(json['reporterName']),
      status: ReportStatus.fromString(
        _stringValue(json['status']).isEmpty
            ? 'PENDING'
            : _stringValue(json['status']),
      ),
      createdAt: _dateTimeValue(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fixedAt: _dateTimeValue(json['fixedAt']),
      fixedBy: _nullableStringValue(json['fixedBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rowNumber': rowNumber,
      'category': category,
      'location': location,
      'description': description,
      'reporterName': reporterName,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'fixedAt': fixedAt?.toIso8601String(),
      'fixedBy': fixedBy,
    };
  }

  static String _stringValue(Object? value) {
    return value == null ? '' : value.toString();
  }

  static String? _nullableStringValue(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _dateTimeValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
