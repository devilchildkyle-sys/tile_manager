import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/financials_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
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
    home: const SplashScreen(child: MainScaffold()),
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
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(info: info),
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

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _download() async {
    setState(() { _downloading = true; _progress = 0; _error = null; });
    await UpdateService.downloadAndInstall(
      widget.info.downloadUrl,
      onProgress: (p) { if (mounted) setState(() => _progress = p); },
      onError: (e) { if (mounted) setState(() { _error = e; _downloading = false; }); },
    );
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1D27),
      title: const Text('Update Available',
          style: TextStyle(color: Color(0xFFFFB547), fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('v${widget.info.latestVersion} is available  (you have ${widget.info.currentVersion})',
            style: const TextStyle(color: Color(0xFFE8E8F0), fontSize: 13)),
        if (_downloading) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF222537),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB547)),
            ),
          ),
          const SizedBox(height: 6),
          Text('Downloading… ${(_progress * 100).toInt()}%',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
        ],
      ]),
      actions: _downloading ? [] : [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Color(0xFF6B7280)))),
        ElevatedButton(
          onPressed: _download,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB547), foregroundColor: Colors.black),
          child: const Text('Download & Install'),
        ),
      ],
    );
  }
}
