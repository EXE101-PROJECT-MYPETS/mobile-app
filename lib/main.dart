import 'package:flutter/material.dart';
import 'package:petpee_mobile/views/login_screen.dart';
import 'package:petpee_mobile/views/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetPeese',
      // Bạn có thể dùng routes để quản lý chuyển màn hình dễ hơn
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}