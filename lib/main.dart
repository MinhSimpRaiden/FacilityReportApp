import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/report_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/report_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();

  final notificationService = NotificationService();
  await notificationService.initialize();
  debugPrint('NotificationService initialized successfully');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(ReportService()),
        ),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const FacilityReportApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('Firebase initialized successfully');
  } catch (error) {
    debugPrint(
        'Firebase initialization failed. Using mock report data: $error');
  }
}
