/**
 * Deprecated.
 *
 * The app no longer uses the old Feature 1 webhook script. Use
 * google_apps_script_sheet_backend.gs instead.
 *
 * Current data flow:
 * Google Form -> CSVC_App_Database spreadsheet -> Apps Script Web App -> app.
 */

function installTrigger() {
  throw new Error('Deprecated script. Paste and use google_apps_script_sheet_backend.gs instead.');
}
