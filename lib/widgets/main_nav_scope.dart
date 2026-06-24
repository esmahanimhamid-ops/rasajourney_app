import 'package:flutter/material.dart';

class MainNavScope extends InheritedWidget {
  const MainNavScope({
    required this.goHome,
    required super.child,
    super.key,
  });

  final VoidCallback goHome;

  static MainNavScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainNavScope>();
  }

  @override
  bool updateShouldNotify(MainNavScope oldWidget) => false;
}
