import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:petpee_mobile/app.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/store/app_state.dart';

import 'package:petpee_mobile/features/chat/providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth_box');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}
