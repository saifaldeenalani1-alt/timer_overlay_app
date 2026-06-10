import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/day_counters_screen.dart';
import 'widgets/overlay_widget.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWidget(),
  ));
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Floating Timer',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      DayCountersScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Timers'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Days'),
        ],
      ),
    );
  }
}
