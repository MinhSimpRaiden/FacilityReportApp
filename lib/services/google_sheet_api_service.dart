import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/report_model.dart';

class GoogleSheetApiService {
  GoogleSheetApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  bool get isConfigured => AppConstants.isAppsScriptConfigured;

  Future<List<ReportModel>> fetchReports() async {
    if (!isConfigured) {
      throw StateError('Apps Script Web App URL is not configured.');
    }

    final uri = Uri.parse(AppConstants.appsScriptWebAppUrl).replace(
      queryParameters: {
        'action': 'getReports',
        'secret': AppConstants.appApiSecret,
      },
    );

    final response = await _client.get(uri);
    final body = _decodeJsonResponse(response, requestName: 'getReports');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Apps Script GET failed ${response.statusCode}: $body');
    }

    final reportsJson = _extractReports(body);
    final reports = reportsJson.map(ReportModel.fromJson).toList();
    reports.sort(_compareNewestFirst);
    return reports;
  }

  Future<void> markReportAsFixed(String reportId, String fixedBy) async {
    await updateReportStatus(reportId, 'FIXED', fixedBy: fixedBy);
  }

  Future<void> markReportAsUnableToFix(String reportId, String fixedBy) async {
    await updateReportStatus(reportId, 'UNABLE_TO_FIX', fixedBy: fixedBy);
  }

  Future<void> updateReportStatus(
    String reportId,
    String status, {
    String fixedBy = 'mock_staff',
  }) async {
    if (!isConfigured) {
      throw StateError('Apps Script Web App URL is not configured.');
    }

    final body = await _postJson(
      {
        'secret': AppConstants.appApiSecret,
        'action': 'updateReportStatus',
        'reportId': reportId,
        'status': status,
        'fixedBy': fixedBy,
      },
      requestName: 'updateReportStatus',
    );

    if (body['success'] != true) {
      throw Exception('Apps Script updateReportStatus failed: $body');
    }
  }

  Future<void> registerDeviceToken({
    required String token,
    required String role,
    required String userName,
  }) async {
    if (!isConfigured) {
      debugPrint('Apps Script API is not configured. Token was not registered.');
      return;
    }

    final body = await _postJson(
      {
        'secret': AppConstants.appApiSecret,
        'action': 'registerToken',
        'token': token,
        'role': role,
        'userName': userName,
        'platform': 'android',
      },
      requestName: 'registerToken',
    );

    if (body['success'] != true) {
      throw Exception('Apps Script registerToken failed: $body');
    }
  }

  Future<Map<String, dynamic>> testConnection() async {
    final reports = await fetchReports();
    return {
      'success': true,
      'count': reports.length,
    };
  }

  Future<Map<String, dynamic>> _postJson(
    Map<String, dynamic> payload, {
    required String requestName,
  }) async {
    final request = http.Request(
      'POST',
      Uri.parse(AppConstants.appsScriptWebAppUrl),
    )
      ..followRedirects = true
      ..maxRedirects = 5
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode(payload);

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decodeJsonResponse(response, requestName: requestName);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Apps Script POST failed ${response.statusCode}: $body');
    }

    return body;
  }

  Map<String, dynamic> _decodeJsonResponse(
    http.Response response, {
    required String requestName,
  }) {
    _logResponseDebug(response, requestName: requestName);

    final bodyText = response.body.trimLeft();
    if (bodyText.isEmpty) {
      throw FormatException(
        'Apps Script returned an empty response for $requestName.',
      );
    }

    final firstChar = bodyText[0];
    if (firstChar != '{' && firstChar != '[') {
      final looksLikeHtml = bodyText.toLowerCase().startsWith('<html') ||
          bodyText.toLowerCase().startsWith('<!doctype html');

      if (looksLikeHtml) {
        throw const AppsScriptHtmlResponseException(
          'Apps Script returned HTML instead of JSON. Check deployment access, '
          'URL, action, secret, and doPost logs.',
        );
      }

      throw FormatException(
        'Apps Script returned non-JSON response for $requestName.',
      );
    }

    final decoded = jsonDecode(bodyText);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Expected JSON object from Apps Script.');
  }

  void _logResponseDebug(
    http.Response response, {
    required String requestName,
  }) {
    final contentType = response.headers['content-type'] ?? 'unknown';
    final preview = response.body.length > 300
        ? response.body.substring(0, 300)
        : response.body;

    debugPrint('Apps Script response [$requestName] status: ${response.statusCode}');
    debugPrint('Apps Script response [$requestName] content-type: $contentType');
    debugPrint('Apps Script response [$requestName] body preview: $preview');
  }

  List<Map<String, dynamic>> _extractReports(Map<String, dynamic> body) {
    final value = body['reports'];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    throw const FormatException(
      'Apps Script response does not contain reports list.',
    );
  }

  int _compareNewestFirst(ReportModel a, ReportModel b) {
    if (a.hasValidCreatedAt != b.hasValidCreatedAt) {
      return a.hasValidCreatedAt ? -1 : 1;
    }

    return b.createdAt.compareTo(a.createdAt);
  }
}

class AppsScriptHtmlResponseException implements Exception {
  const AppsScriptHtmlResponseException(this.message);

  final String message;

  @override
  String toString() => message;
}
