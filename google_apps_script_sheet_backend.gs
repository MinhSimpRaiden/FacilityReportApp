/**
 * Apps Script backend for the free CSVC app architecture.
 *
 * Data source:
 * - Spreadsheet: CSVC_App_Database
 * - Main sheet: Database
 * - Device token sheet: DeviceTokens
 *
 * The app reads/writes this database spreadsheet only.
 */

const DATABASE_SPREADSHEET_ID = '1G0BYtNflf7npVSbYbwD1wMqJmVEtXdVE6cfkWV7oJ24';
const DATABASE_SHEET_NAME = 'Database';
const DEVICE_TOKENS_SHEET_NAME = 'DeviceTokens';

const FORM_HEADERS = {
  timestamp: 'Timestamp',
  category: 'Hạng mục',
  location: 'Địa điểm (Tại lớp nào hoặc nơi nào trong trường)',
  description: 'Mô tả tình trạng hư hỏng',
  reporterName: 'Họ tên người báo tin',
};

const APP_HEADERS = {
  reportId: 'Report ID',
  status: 'Trạng thái',
  handledBy: 'Người xử lý',
  updatedAt: 'Thời gian cập nhật',
  note: 'Ghi chú xử lý',
};

const DATABASE_REQUIRED_HEADERS = [
  FORM_HEADERS.timestamp,
  FORM_HEADERS.category,
  FORM_HEADERS.location,
  FORM_HEADERS.description,
  FORM_HEADERS.reporterName,
  APP_HEADERS.reportId,
  APP_HEADERS.status,
  APP_HEADERS.handledBy,
  APP_HEADERS.updatedAt,
  APP_HEADERS.note,
];

const HEADER_ALIASES = {
  timestamp: ['Timestamp', 'Dấu thời gian'],
  category: ['Hạng mục'],
  location: [
    'Địa điểm (Tại lớp nào hoặc nơi nào trong trường)',
    'Địa điểm',
  ],
  description: ['Mô tả tình trạng hư hỏng'],
  reporterName: ['Họ tên người báo tin'],
  reportId: ['Report ID', 'ReportID', 'ID'],
  status: ['Trạng thái', 'Status'],
  handledBy: ['Người xử lý', 'Fixed By', 'FixedBy'],
  updatedAt: ['Thời gian cập nhật', 'Fixed At', 'FixedAt'],
  note: ['Ghi chú xử lý'],
};

const DEVICE_TOKEN_HEADERS = [
  'token',
  'role',
  'userName',
  'platform',
  'createdAt',
  'updatedAt',
];

const PROPERTY_NAMES = {
  appApiSecret: 'APP_API_SECRET',
  firebaseProjectId: 'FIREBASE_PROJECT_ID',
  firebaseClientEmail: 'FIREBASE_CLIENT_EMAIL',
  firebasePrivateKey: 'FIREBASE_PRIVATE_KEY',
};

const STATUS_VALUES = {
  pending: 'PENDING',
  fixed: 'FIXED',
  unableToFix: 'UNABLE_TO_FIX',
};

const ALLOWED_STATUSES = [
  STATUS_VALUES.pending,
  STATUS_VALUES.fixed,
  STATUS_VALUES.unableToFix,
];

function doGet(e) {
  try {
    const params = e && e.parameter ? e.parameter : {};
    assertSecret_(params.secret);

    if (params.action === 'getReports') {
      return jsonResponse_({
        success: true,
        reports: getReports(params.status),
      });
    }

    return jsonResponse_({
      success: false,
      error: 'Unknown GET action.',
    });
  } catch (error) {
    return errorResponse_(error);
  }
}

function doPost(e) {
  try {
    const data = parsePostBody_(e);
    assertSecret_(data.secret);

    if (data.action === 'registerToken') {
      registerDeviceToken(data);
      return jsonResponse_({success: true});
    }

    if (data.action === 'updateReportStatus') {
      return jsonResponse_(updateReportStatus(data));
    }

    if (data.action === 'markFixed') {
      return jsonResponse_(updateReportStatus({
        reportId: data.reportId,
        status: STATUS_VALUES.fixed,
        fixedBy: data.fixedBy,
        note: data.note,
      }));
    }

    if (data.action === 'markUnableToFix') {
      return jsonResponse_(updateReportStatus({
        reportId: data.reportId,
        status: STATUS_VALUES.unableToFix,
        fixedBy: data.fixedBy,
        note: data.note,
      }));
    }

    return jsonResponse_({
      success: false,
      error: 'Unknown POST action.',
    });
  } catch (error) {
    return errorResponse_(error);
  }
}

function onFormSubmit(e) {
  const sheet = getDatabaseSheet_();
  ensureDatabaseHeaders_();

  const rowNumber = e && e.range && e.range.getSheet().getName() === DATABASE_SHEET_NAME
    ? e.range.getRow()
    : sheet.getLastRow();
  const headerMap = getDatabaseHeaderMap_();
  const row = getReportRowObject_(sheet, rowNumber, headerMap);

  if (!row.reportId) {
    setReportCell_(sheet, rowNumber, headerMap, 'reportId', createReportId_());
  }
  if (!row.status) {
    setReportCell_(sheet, rowNumber, headerMap, 'status', STATUS_VALUES.pending);
  }

  const report = reportFromRow_(sheet, rowNumber);
  Logger.log('New report in database:');
  Logger.log(JSON.stringify(report, null, 2));

  sendFcmNotification(report);
}

function installTrigger() {
  const ss = getDatabaseSpreadsheet_();
  const triggers = ScriptApp.getProjectTriggers();

  triggers.forEach((trigger) => {
    if (trigger.getHandlerFunction() === 'onFormSubmit') {
      ScriptApp.deleteTrigger(trigger);
    }
  });

  ScriptApp.newTrigger('onFormSubmit')
    .forSpreadsheet(ss)
    .onFormSubmit()
    .create();

  ensureDatabaseHeaders_();
  ensureDeviceTokenSheet_();
  Logger.log('Installed onFormSubmit trigger for CSVC_App_Database.');
}

function getReports(statusFilter) {
  const sheet = getDatabaseSheet_();
  ensureDatabaseHeaders_();
  const normalizedStatusFilter = normalizeStatus_(statusFilter);

  const lastRow = sheet.getLastRow();
  if (lastRow < 2) {
    return [];
  }

  const reports = [];
  for (let rowNumber = 2; rowNumber <= lastRow; rowNumber += 1) {
    const report = reportFromRow_(sheet, rowNumber);
    const hasReportData =
      report.category || report.location || report.description || report.reporterName;
    const statusMatches =
      !normalizedStatusFilter || report.status === normalizedStatusFilter;

    if (hasReportData && statusMatches) {
      reports.push(report);
    }
  }

  return reports;
}

function getReportsByStatus(status) {
  return getReports(status);
}

function updateReportStatus(data) {
  const reportId = String(data.reportId || '').trim();
  const status = normalizeStatus_(data.status);
  const handledBy = String(data.fixedBy || data.handledBy || 'mock_staff').trim() || 'mock_staff';
  const note = data.note === undefined ? null : String(data.note || '');

  if (!reportId) {
    throw new Error('Missing reportId.');
  }
  if (ALLOWED_STATUSES.indexOf(status) === -1) {
    throw new Error('Invalid status: ' + status);
  }

  const sheet = getDatabaseSheet_();
  ensureDatabaseHeaders_();
  const headerMap = getDatabaseHeaderMap_();
  const lastRow = sheet.getLastRow();

  for (let rowNumber = 2; rowNumber <= lastRow; rowNumber += 1) {
    const row = getReportRowObject_(sheet, rowNumber, headerMap);

    if (row.reportId === reportId) {
      // Only update app-managed columns. Never modify original form answer columns.
      setReportCell_(sheet, rowNumber, headerMap, 'status', status);
      setReportCell_(sheet, rowNumber, headerMap, 'updatedAt', new Date());
      setReportCell_(sheet, rowNumber, headerMap, 'handledBy', handledBy);
      if (note !== null) {
        setReportCell_(sheet, rowNumber, headerMap, 'note', note);
      }

      return {
        success: true,
        reportId: reportId,
        rowNumber: rowNumber,
        status: status,
        report: reportFromRow_(sheet, rowNumber),
      };
    }
  }

  throw new Error('Report not found: ' + reportId);
}

function markReportAsFixed(data) {
  return updateReportStatus({
    reportId: data.reportId,
    status: STATUS_VALUES.fixed,
    fixedBy: data.fixedBy,
    note: data.note,
  });
}

function markReportAsUnableToFix(data) {
  return updateReportStatus({
    reportId: data.reportId,
    status: STATUS_VALUES.unableToFix,
    fixedBy: data.fixedBy,
    note: data.note,
  });
}

function registerDeviceToken(data) {
  const token = String(data.token || '').trim();
  if (!token) {
    throw new Error('Missing device token.');
  }

  const sheet = ensureDeviceTokenSheet_();
  const headerMap = getHeaderMap_(sheet);
  const lastRow = sheet.getLastRow();
  const now = new Date();

  for (let rowNumber = 2; rowNumber <= lastRow; rowNumber += 1) {
    const currentToken = String(sheet.getRange(rowNumber, headerMap.token).getValue()).trim();

    if (currentToken === token) {
      setCellByHeader_(sheet, rowNumber, headerMap, 'role', data.role || 'STAFF');
      setCellByHeader_(sheet, rowNumber, headerMap, 'userName', data.userName || '');
      setCellByHeader_(sheet, rowNumber, headerMap, 'platform', data.platform || 'android');
      setCellByHeader_(sheet, rowNumber, headerMap, 'updatedAt', now);
      return;
    }
  }

  sheet.appendRow([
    token,
    data.role || 'STAFF',
    data.userName || '',
    data.platform || 'android',
    now,
    now,
  ]);
}

function sendFcmNotification(report) {
  const tokens = getRegisteredTokens_();
  if (tokens.length === 0) {
    Logger.log('No device tokens found. Skipping FCM notification.');
    return;
  }

  const accessToken = getFirebaseAccessToken_();
  if (!accessToken) {
    Logger.log('Firebase service account properties are not configured. Skipping FCM notification.');
    return;
  }

  const projectId = getScriptProperty_(PROPERTY_NAMES.firebaseProjectId);
  const url = 'https://fcm.googleapis.com/v1/projects/' + projectId + '/messages:send';

  tokens.forEach((token) => {
    const payload = {
      message: {
        token: token,
        notification: {
          title: 'Có báo cáo CSVC mới',
          body: report.category + ' - ' + report.location,
        },
        data: {
          type: 'new_report',
          reportId: report.id,
        },
        android: {
          priority: 'HIGH',
          notification: {
            channel_id: 'facility_reports',
          },
        },
      },
    };

    const response = UrlFetchApp.fetch(url, {
      method: 'post',
      contentType: 'application/json',
      headers: {
        Authorization: 'Bearer ' + accessToken,
      },
      payload: JSON.stringify(payload),
      muteHttpExceptions: true,
    });

    Logger.log('FCM response ' + response.getResponseCode() + ': ' + response.getContentText());
  });
}

function backfillMissingStatus() {
  const sheet = getDatabaseSheet_();
  ensureDatabaseHeaders_();
  const headerMap = getDatabaseHeaderMap_();
  const lastRow = sheet.getLastRow();
  let updatedCount = 0;

  for (let rowNumber = 2; rowNumber <= lastRow; rowNumber += 1) {
    const row = getReportRowObject_(sheet, rowNumber, headerMap);
    const hasReportData = row.category || row.location || row.description || row.reporterName;

    if (!hasReportData) {
      continue;
    }

    if (!row.reportId) {
      setReportCell_(sheet, rowNumber, headerMap, 'reportId', createReportId_());
      updatedCount += 1;
    }
    if (!row.status) {
      setReportCell_(sheet, rowNumber, headerMap, 'status', STATUS_VALUES.pending);
      updatedCount += 1;
    }
  }

  Logger.log('Backfill complete. Updated cells: ' + updatedCount);
}

function getDatabaseSpreadsheet_() {
  return SpreadsheetApp.openById(DATABASE_SPREADSHEET_ID);
}

function getDatabaseSheet_() {
  const ss = SpreadsheetApp.openById(DATABASE_SPREADSHEET_ID);
  const sheet = ss.getSheetByName(DATABASE_SHEET_NAME);
  if (!sheet) {
    throw new Error('Missing sheet: ' + DATABASE_SHEET_NAME);
  }
  return sheet;
}

function ensureDeviceTokenSheet_() {
  const ss = SpreadsheetApp.openById(DATABASE_SPREADSHEET_ID);
  let sheet = ss.getSheetByName(DEVICE_TOKENS_SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(DEVICE_TOKENS_SHEET_NAME);
  }
  ensureHeaders_(sheet, DEVICE_TOKEN_HEADERS);
  return sheet;
}

function ensureDatabaseHeaders_() {
  ensureHeaders_(getDatabaseSheet_(), DATABASE_REQUIRED_HEADERS);
}

function ensureHeaders_(sheet, requiredHeaders) {
  const lastColumn = Math.max(sheet.getLastColumn(), 1);
  const currentHeaders = sheet.getRange(1, 1, 1, lastColumn).getValues()[0]
    .map((value) => String(value || '').trim());

  requiredHeaders.forEach((header) => {
    if (currentHeaders.indexOf(header) === -1) {
      sheet.getRange(1, sheet.getLastColumn() + 1).setValue(header);
      currentHeaders.push(header);
    }
  });
}

function getDatabaseHeaderMap_() {
  const rawMap = getHeaderMap_(getDatabaseSheet_());
  const reportMap = {};

  Object.keys(HEADER_ALIASES).forEach((field) => {
    const aliases = HEADER_ALIASES[field];
    for (let index = 0; index < aliases.length; index += 1) {
      const alias = aliases[index];
      if (rawMap[alias]) {
        reportMap[field] = rawMap[alias];
        return;
      }
    }
  });

  Object.keys(HEADER_ALIASES).forEach((field) => {
    if (!reportMap[field]) {
      throw new Error('Missing required database column for field: ' + field);
    }
  });

  return reportMap;
}

function getHeaderMap_(sheet) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const map = {};
  headers.forEach((header, index) => {
    map[String(header).trim()] = index + 1;
  });
  return map;
}

function getReportRowObject_(sheet, rowNumber, headerMap) {
  return {
    reportId: stringCell_(sheet, rowNumber, headerMap.reportId),
    timestamp: sheet.getRange(rowNumber, headerMap.timestamp).getValue(),
    category: stringCell_(sheet, rowNumber, headerMap.category),
    location: stringCell_(sheet, rowNumber, headerMap.location),
    description: stringCell_(sheet, rowNumber, headerMap.description),
    reporterName: stringCell_(sheet, rowNumber, headerMap.reporterName),
    status: normalizeStatus_(stringCell_(sheet, rowNumber, headerMap.status)),
    handledBy: stringCell_(sheet, rowNumber, headerMap.handledBy),
    updatedAt: sheet.getRange(rowNumber, headerMap.updatedAt).getValue(),
    note: stringCell_(sheet, rowNumber, headerMap.note),
  };
}

function reportFromRow_(sheet, rowNumber) {
  const headerMap = getDatabaseHeaderMap_();
  const row = getReportRowObject_(sheet, rowNumber, headerMap);
  const reportId = row.reportId || createReportId_();

  if (!row.reportId) {
    setReportCell_(sheet, rowNumber, headerMap, 'reportId', reportId);
  }
  if (!row.status) {
    setReportCell_(sheet, rowNumber, headerMap, 'status', STATUS_VALUES.pending);
  }

  return {
    id: String(reportId),
    rowNumber: rowNumber,
    category: row.category,
    location: row.location,
    description: row.description,
    reporterName: row.reporterName,
    status: row.status || STATUS_VALUES.pending,
    createdAt: dateToJsonValue_(row.timestamp),
    fixedAt: dateToJsonValue_(row.updatedAt),
    fixedBy: row.handledBy,
    note: row.note,
  };
}

function setReportCell_(sheet, rowNumber, headerMap, field, value) {
  sheet.getRange(rowNumber, headerMap[field]).setValue(value);
}

function setCellByHeader_(sheet, rowNumber, headerMap, header, value) {
  sheet.getRange(rowNumber, headerMap[header]).setValue(value);
}

function stringCell_(sheet, rowNumber, columnNumber) {
  return String(sheet.getRange(rowNumber, columnNumber).getValue() || '').trim();
}

function normalizeStatus_(value) {
  const text = String(value || '').trim().toUpperCase();
  if (!text) {
    return '';
  }
  if (text === 'ĐANG CHỜ' || text === 'DANG CHO') {
    return STATUS_VALUES.pending;
  }
  if (text === 'ĐÃ SỬA' || text === 'DA SUA') {
    return STATUS_VALUES.fixed;
  }
  if (text === 'KHÔNG THỂ SỬA' || text === 'KHONG THE SUA') {
    return STATUS_VALUES.unableToFix;
  }
  return text;
}

function parsePostBody_(e) {
  if (!e || !e.postData || !e.postData.contents) {
    throw new Error('Missing JSON body.');
  }
  return JSON.parse(e.postData.contents);
}

function assertSecret_(receivedSecret) {
  const expectedSecret = getScriptProperty_(PROPERTY_NAMES.appApiSecret);
  if (!expectedSecret) {
    throw new Error('APP_API_SECRET Script Property is not configured.');
  }
  if (!receivedSecret || receivedSecret !== expectedSecret) {
    throw new Error('Unauthorized.');
  }
}

function getRegisteredTokens_() {
  const sheet = ensureDeviceTokenSheet_();
  const headerMap = getHeaderMap_(sheet);
  const lastRow = sheet.getLastRow();
  const tokens = [];

  for (let rowNumber = 2; rowNumber <= lastRow; rowNumber += 1) {
    const token = String(sheet.getRange(rowNumber, headerMap.token).getValue()).trim();
    if (token) {
      tokens.push(token);
    }
  }

  return tokens;
}

function getFirebaseAccessToken_() {
  const projectId = getScriptProperty_(PROPERTY_NAMES.firebaseProjectId);
  const clientEmail = getScriptProperty_(PROPERTY_NAMES.firebaseClientEmail);
  const privateKey = getScriptProperty_(PROPERTY_NAMES.firebasePrivateKey);

  if (!projectId || !clientEmail || !privateKey) {
    return null;
  }

  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };
  const claimSet = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  const unsignedJwt = base64UrlEncode_(JSON.stringify(header)) + '.' +
    base64UrlEncode_(JSON.stringify(claimSet));
  const normalizedPrivateKey = privateKey.replace(/\\n/g, '\n');
  const signature = Utilities.computeRsaSha256Signature(unsignedJwt, normalizedPrivateKey);
  const signedJwt = unsignedJwt + '.' + base64UrlEncodeBytes_(signature);

  const response = UrlFetchApp.fetch('https://oauth2.googleapis.com/token', {
    method: 'post',
    payload: {
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: signedJwt,
    },
    muteHttpExceptions: true,
  });

  if (response.getResponseCode() < 200 || response.getResponseCode() >= 300) {
    Logger.log('Failed to get Firebase access token: ' + response.getContentText());
    return null;
  }

  const body = JSON.parse(response.getContentText());
  return body.access_token;
}

function createReportId_() {
  return 'RPT-' + Utilities.getUuid();
}

function dateToJsonValue_(value) {
  if (!value) {
    return null;
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  return String(value);
}

function getScriptProperty_(name) {
  return PropertiesService.getScriptProperties().getProperty(name);
}

function jsonResponse_(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function errorResponse_(error) {
  const message = error && error.message ? error.message : String(error);
  const status = message === 'Unauthorized.' ? 401 : 400;
  return jsonResponse_({
    success: false,
    status: status,
    error: message,
  });
}

function base64UrlEncode_(text) {
  return base64UrlEncodeBytes_(Utilities.newBlob(text).getBytes());
}

function base64UrlEncodeBytes_(bytes) {
  return Utilities.base64EncodeWebSafe(bytes).replace(/=+$/, '');
}
