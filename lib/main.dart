import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:petpee_mobile/core/providers/app_state.dart';
import 'package:petpee_mobile/core/providers/auth_provider.dart';
import 'package:petpee_mobile/features/auth/screens/login_screen.dart';
import 'package:petpee_mobile/features/auth/screens/register_screen.dart';
import 'package:petpee_mobile/features/product/screens/product_list_screen.dart';
import 'package:petpee_mobile/features/cart/screens/cart_screen.dart';
import 'package:petpee_mobile/features/home/screens/notifications_screen.dart';
import 'package:petpee_mobile/features/home/screens/home_screen.dart';

import 'package:petpee_mobile/features/chat/providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

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