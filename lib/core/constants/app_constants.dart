class AppConstants {
  static const String appName = 'Facility Reports';

  static const String reportsCollection = 'reports';
  static const String usersCollection = 'users';
  static const String deviceTokensCollection = 'deviceTokens';

  static const String appsScriptWebAppUrl =
      'https://script.google.com/macros/s/AKfycbyM03dZDh4Ms5aeyAyiWQBXK4vkt6-Spts-b9qLDpEFnX3v3qMnrfxZ-4nV0afLzM6B/exec';
  static const String appApiSecret = 'csvc_test_secret_2026_minh_123456';

  static bool get isAppsScriptConfigured {
    return appsScriptWebAppUrl.startsWith('https://') &&
        appApiSecret != 'APP_API_SECRET';
  }
}
