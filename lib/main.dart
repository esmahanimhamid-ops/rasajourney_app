import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/ar_screen.dart';
import 'screens/favourites_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const rasajourney_app());
}

class rasajourney_app extends StatelessWidget {
  const rasajourney_app({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastronomy Tourism Perlis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: const MainNav(),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    ExploreScreen(),
    ARScreen(),
    FavouritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.cream,
              AppTheme.warmWhite,
            ],
          ),
        ),
        child: IndexedStack(
          index: _index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'AR'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favourites'),
        ],
      ),
    );
  }
}
