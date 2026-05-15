import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/apps/cart/page/cart_screen.dart';
import 'package:petpee_mobile/apps/home/page/home_screen.dart';
import 'package:petpee_mobile/apps/home/page/notifications_screen.dart';
import 'package:petpee_mobile/apps/product/page/product_list_screen.dart';
import 'package:petpee_mobile/apps/profile/page/my_pets_screen.dart';
import 'package:petpee_mobile/common/auth/page/login_screen.dart';
import 'package:petpee_mobile/common/auth/page/register_screen.dart';
import 'package:petpee_mobile/common/store/app_state.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Load recently viewed products from local storage on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.maybeOf<AppState>(context, listen: false);
      appState?.loadRecentlyViewedProducts();
    });
  }

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
        '/pets': (context) => const MyPetsScreen(),
        '/bookings': (context) =>
            const HomeScreen(), // TODO: Create BookingsScreen
        '/orders': (context) => const HomeScreen(), // TODO: Create OrdersScreen
      },
    );
  }
}
