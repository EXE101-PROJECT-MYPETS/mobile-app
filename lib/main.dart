import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pawly_mobile/app.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/config/api_config.dart';
import 'package:pawly_mobile/common/config/firebase_notification_service.dart';
import 'package:pawly_mobile/common/notification/store/notification_provider.dart';
import 'package:pawly_mobile/common/store/app_state.dart';
import 'package:pawly_mobile/features/chat/providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth_box');
  await ApiConfig.initialize();
  await FirebaseNotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AppState>(
          create: (context) => AppState(),
          update: (context, auth, previous) {
            final appState = previous ?? AppState();
            final currentUserId = auth.currentUser?.id;
            if (appState.currentUserId != currentUserId) {
              appState.loadUserCart(currentUserId);
            }
            return appState;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}
