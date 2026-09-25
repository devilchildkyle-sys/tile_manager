import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/financials_screen.dart';
import 'screens/settings_screen.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init();
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const TileManagerApp(),
    ),
  );
}

class TileManagerApp extends StatelessWidget {
  const TileManagerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tile Manager',
    theme: AppTheme.dark(),
    debugShowCheckedModeBanner: false,
    home: const MainScaffold(),
  );
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (!mounted || info == null || !info.hasUpdate) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D27),
        title: const Text('Update Available',
            style: TextStyle(color: Color(0xFFFFB547), fontWeight: FontWeight.w800)),
        content: Text(
          'Version ${info.latestVersion} is available.\nYou have ${info.currentVersion}.',
          style: const TextStyle(color: Color(0xFFE8E8F0)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Later', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse(info.downloadUrl), mode: LaunchMode.externalApplication);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB547), foregroundColor: Colors.black),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _tab,
      children: const [HomeScreen(), FinancialsScreen(), SettingsScreen()],
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) { if (i != 1) setState(() => _tab = i); },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), label: 'PROJECTS'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined, color: Color(0xFF3A3D4E)),
            activeIcon: Icon(Icons.bar_chart_outlined, color: Color(0xFF3A3D4E)),
            label: 'FINANCIALS'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings), label: 'SETTINGS'),
      ],
    ),
  );
}
