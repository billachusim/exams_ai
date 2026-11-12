import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  static const _tabs = [
    ('/home', Icons.home_outlined, Icons.home, 'Home'),
    ('/tutor', Icons.chat_bubble_outline, Icons.chat_bubble, 'Tutor'),
    ('/practice', Icons.fact_check_outlined, Icons.fact_check, 'Practice'),
    ('/progress', Icons.insights_outlined, Icons.insights, 'Progress'),
    ('/profile', Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final t in _tabs) NavigationDestination(icon: Icon(t.$2), selectedIcon: Icon(t.$3), label: t.$4),
        ],
      ),
    );
  }
}
