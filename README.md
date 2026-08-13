# Facility Report App

Flutter Android app for tracking school facility damage reports.

## Current Architecture

```text
Google Form
  -> CSVC_App_Database Google Sheet
  -> Apps Script Web App
  -> Flutter Android app
  -> Firebase Cloud Messaging
```

Google Sheet is the report database. Apps Script is the backend API. Firebase is currently used for Android FCM notifications.

Do not create a new Google Form, change the QR code, or change the form link for this app.

The `functions/` folder is from the older Cloud Functions architecture. It is not used by the current Google Sheet database flow.

## Google Sheet Database

Database spreadsheet:

```text
Name: CSVC_App_Database
ID: 1G0BYtNflf7npVSbYbwD1wMqJmVEtXdVE6cfkWV7oJ24
Main sheet: Database
Device token sheet: DeviceTokens
```

The Apps Script backend must use:

```js
const DATABASE_SPREADSHEET_ID = '1G0BYtNflf7npVSbYbwD1wMqJmVEtXdVE6cfkWV7oJ24';
const DATABASE_SHEET_NAME = 'Database';
const DEVICE_TOKENS_SHEET_NAME = 'DeviceTokens';
```

Report data is always loaded with:

```js
const ss = SpreadsheetApp.openById(DATABASE_SPREADSHEET_ID);
const sheet = ss.getSheetByName(DATABASE_SHEET_NAME);
```

Device tokens are always loaded with:

```js
const ss = SpreadsheetApp.openById(DATABASE_SPREADSHEET_ID);
const tokenSheet = ss.getSheetByName(DEVICE_TOKENS_SHEET_NAME);
```

The app backend must not read from old response sheets such as `Form Responses 1`, `Form_Responses3`, or `Câu trả lời biểu mẫu 1`.

## Database Headers

The `Database` sheet must contain the original form columns:

- `Timestamp`
- `Hạng mục`
- `Địa điểm (Tại lớp nào hoặc nơi nào trong trường)`
- `Mô tả tình trạng hư hỏng`
- `Họ tên người báo tin`

Apps Script automatically checks/creates these app-managed columns if they are missing:

- `Report ID`
- `Trạng thái`
- `Người xử lý`
- `Thời gian cập nhật`
- `Ghi chú xử lý`

Status updates must only edit app-managed columns. They must not overwrite original Google Form answer columns.

## Statuses And Filters

Supported report statuses:

- `PENDING` = `Đang chờ`
- `FIXED` = `Đã sửa`
- `UNABLE_TO_FIX` = `Không thể sửa`

The Flutter report list supports:

- category filter
- status filter
- newest report first sorting by `createdAt`

The status filter has:

- `Tất cả trạng thái`
- `Đang chờ`
- `Đã sửa`
- `Không thể sửa`

## Flutter Setup

Flutter SDK on this machine:

```text
C:\Users\ADMIN\develop\flutter
```

Run:

```powershell
cd C:\Users\ADMIN\Downloads\AppTheoDoiCSVC\facility_report_app
& 'C:\Users\ADMIN\develop\flutter\bin\flutter.bat' pub get
& 'C:\Users\ADMIN\develop\flutter\bin\flutter.bat' analyze
& 'C:\Users\ADMIN\develop\flutter\bin\flutter.bat' run -d <device-id>
```

Build APK:

```powershell
& 'C:\Users\ADMIN\develop\flutter\bin\flutter.bat' clean
& 'C:\Users\ADMIN\develop\flutter\bin\flutter.bat' pub get
& 'C:\Users\ADMIN\develop\flutter\bin\flutter.bat' analyze
& 'C:\Users\ADMIN\develop\flutter\bin\flutter.bat' build apk --release
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Flutter Constants

Open:

```text
lib/core/constants/app_constants.dart
```

Check:

- `appsScriptWebAppUrl`: deployed Apps Script Web App `/exec` URL
- `appApiSecret`: same value as Apps Script `APP_API_SECRET` Script Property

Do not commit or share real secrets, tokens, private keys, or service account JSON files.

## Apps Script Backend

Paste this file into the Apps Script project that belongs to the database spreadsheet:

```text
google_apps_script_sheet_backend.gs
```

After editing Apps Script, redeploy the Web App as a new version.

Required Script Property:

| Property | Purpose |
| --- | --- |
| `APP_API_SECRET` | Shared secret used by Flutter and Apps Script |

Optional Script Properties for automatic FCM from Apps Script:

| Property | Purpose |
| --- | --- |
| `FIREBASE_PROJECT_ID` | Firebase project id, for example `facility-report-test` |
| `FIREBASE_CLIENT_EMAIL` | Service account client email |
| `FIREBASE_PRIVATE_KEY` | Service account private key value |

Store these values only in Apps Script Properties. Do not paste service account JSON into code.

## Deploy Apps Script Web App

1. Open `CSVC_App_Database`.
2. Go to `Extensions > Apps Script`.
3. Paste `google_apps_script_sheet_backend.gs`.
4. Set `APP_API_SECRET` in Script Properties.
5. Run `installTrigger`.
6. Approve permissions.
7. Go to `Deploy > New deployment`.
8. Select `Web app`.
9. Execute as: `Me`.
10. Choose access mode that allows the Android app to call the URL.
11. Deploy and copy the `/exec` Web App URL.
12. Put the URL and secret into `AppConstants`.

## Apps Script API

GET all reports:

```text
WEB_APP_URL?action=getReports&secret=APP_API_SECRET
```

GET reports by status:

```text
WEB_APP_URL?action=getReports&status=PENDING&secret=APP_API_SECRET
```

POST update status:

```json
{
  "secret": "APP_API_SECRET",
  "action": "updateReportStatus",
  "reportId": "...",
  "status": "FIXED",
  "fixedBy": "mock_staff"
}
```

POST register token:

```json
{
  "secret": "APP_API_SECRET",
  "action": "registerToken",
  "token": "...",
  "role": "STAFF",
  "userName": "Bảo vệ 1",
  "platform": "android"
}
```

## Test End To End

1. Open `CSVC_App_Database` and confirm the `Database` and `DeviceTokens` sheets exist.
2. Confirm the Google Form submits rows into the `Database` sheet.
3. In Apps Script, run `backfillMissingStatus` once if old rows are missing `Report ID` or `Trạng thái`.
4. Deploy the Apps Script Web App.
5. Update the Flutter Web App URL in `AppConstants`.
6. Run the Android app.
7. Confirm the terminal prints an FCM token.
8. Confirm that token appears in the `DeviceTokens` sheet.
9. Submit one Google Form test response.
10. Confirm Apps Script logs show a new report.
11. Confirm the app shows the new report after refresh.
12. Open the report and press `ĐÃ SỬA`.
13. Confirm only these columns changed in `Database`: `Trạng thái`, `Người xử lý`, `Thời gian cập nhật`, `Ghi chú xử lý`.
14. Repeat with `KHÔNG THỂ SỬA`.

## FCM Notification

When `onFormSubmit(e)` runs, Apps Script reads tokens from the `DeviceTokens` sheet in `CSVC_App_Database`.

If Firebase service account Script Properties are missing, Apps Script logs the issue and skips FCM safely.

Notification content:

- title: `Có báo cáo CSVC mới`
- body: `<category> - <location>`

## Troubleshooting

If Android receives HTML instead of JSON, check:

- the Web App URL is the deployed `/exec` URL
- Apps Script Web App access allows Android calls
- `APP_API_SECRET` matches
- the Web App was redeployed after editing code
- Apps Script `Executions` logs for `doGet`, `doPost`, or `onFormSubmit`

The Flutter HTTP client logs:

- status code
- response `content-type`
- first 300 characters of response body

## Security Notes

- Do not commit or share `google-services.json`.
- Do not commit or share Firebase service account JSON files.
- Do not hardcode service account private keys in Apps Script or Flutter.
- Keep Firebase private values in Apps Script Properties only.
