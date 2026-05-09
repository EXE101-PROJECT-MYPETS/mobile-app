import 'package:flutter/material.dart';
import 'package:petpee_mobile/apps/cart/page/cart_screen.dart';
import 'package:petpee_mobile/apps/home/page/home_screen.dart';
import 'package:petpee_mobile/apps/home/page/notifications_screen.dart';
import 'package:petpee_mobile/apps/product/page/product_list_screen.dart';
import 'package:petpee_mobile/common/auth/page/login_screen.dart';
import 'package:petpee_mobile/common/auth/page/register_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetPeese',
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/products': (context) => const ProductListScreen(),
        '/cart': (context) => const CartScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
