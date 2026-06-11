import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawly_mobile/apps/cart/page/cart_screen.dart';
import 'package:pawly_mobile/apps/home/page/home_screen.dart';
import 'package:pawly_mobile/apps/home/page/notifications_screen.dart';
import 'package:pawly_mobile/apps/product/page/product_list_screen.dart';
import 'package:pawly_mobile/apps/profile/page/my_pets_screen.dart';
import 'package:pawly_mobile/apps/profile/page/profile_screen.dart';
import 'package:pawly_mobile/common/auth/page/login_screen.dart';
import 'package:pawly_mobile/common/auth/page/register_screen.dart';
import 'package:pawly_mobile/common/navigation/main_tab_navigation.dart';
import 'package:pawly_mobile/common/store/app_state.dart';
import 'package:pawly_mobile/features/chat/screens/pet_ai_selection_screen.dart';

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
      context.read<AppState>().loadRecentlyViewedProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pawly',
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
        MainTabRoutes.home: (context) => const HomeScreen(),
        MainTabRoutes.ai: (context) => const PetAiSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/products': (context) => const ProductListScreen(),
        MainTabRoutes.cart: (context) => const CartScreen(),
        MainTabRoutes.notifications: (context) => const NotificationsScreen(),
        MainTabRoutes.profile: (context) => const ProfileScreen(),
        '/pets': (context) => const MyPetsScreen(),
        '/bookings': (context) =>
            const HomeScreen(), // TODO: Create BookingsScreen
        '/orders': (context) => const HomeScreen(), // TODO: Create OrdersScreen
      },
    );
  }
}
