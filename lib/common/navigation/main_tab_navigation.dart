import 'package:flutter/material.dart';

class MainTabRoutes {
  const MainTabRoutes._();

  static const home = '/';
  static const ai = '/ai';
  static const cart = '/cart';
  static const notifications = '/notifications';
  static const profile = '/profile';
}

class MainTabNavigation {
  const MainTabNavigation._();

  static String? routeNameForIndex(int index) {
    return switch (index) {
      0 => MainTabRoutes.home,
      1 => MainTabRoutes.ai,
      2 => MainTabRoutes.cart,
      3 => MainTabRoutes.notifications,
      4 => MainTabRoutes.profile,
      _ => null,
    };
  }

  static void open(
    BuildContext context,
    int index, {
    required int currentIndex,
  }) {
    if (index == currentIndex) return;

    final routeName = routeNameForIndex(index);
    if (routeName == null) return;

    final navigator = Navigator.of(context);
    if (routeName == MainTabRoutes.home) {
      navigator.pushNamedAndRemoveUntil(MainTabRoutes.home, (route) => false);
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      routeName,
      (route) => route.settings.name == MainTabRoutes.home || route.isFirst,
    );
  }

  static void backToPreviousOrHome(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushNamedAndRemoveUntil(MainTabRoutes.home, (route) => false);
  }
}
