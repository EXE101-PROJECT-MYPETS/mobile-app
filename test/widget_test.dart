import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:petpee_mobile/common/auth/page/login_screen.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDirectory = await Directory.systemTemp.createTemp('petpee_hive_test_');
    Hive.init(hiveDirectory.path);
    await Hive.openBox('auth_box');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  tearDown(() async {
    await Hive.box('auth_box').clear();
  });

  testWidgets('Shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('PETPEE'), findsOneWidget);
  });
}
