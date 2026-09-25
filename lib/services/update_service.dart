import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const _owner = 'devilchildkyle-sys';
const _repo  = 'tile_manager';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  bool get hasUpdate {
    final current = _parse(currentVersion);
    final latest  = _parse(latestVersion);
    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String v) {
    final parts = v.replaceAll(RegExp(r'[^0-9.]'), '').split('.')
        .map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) parts.add(0);
    return parts;
  }
}

class UpdateService {
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data   = jsonDecode(response.body) as Map<String, dynamic>;
      final tag    = (data['tag_name'] as String? ?? '').replaceAll('v', '');
      final body   = data['body'] as String? ?? '';
      final assets = (data['assets'] as List? ?? []);
      final apk    = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'), orElse: () => null);

      return UpdateInfo(
        latestVersion: tag,
        currentVersion: info.version,
        downloadUrl: apk != null
            ? apk['browser_download_url'] as String
            : 'https://github.com/$_owner/$_repo/releases/latest',
        releaseNotes: body,
      );
    } catch (_) {
      return null;
    }
  }

  // Downloads APK to cache dir and triggers install. Reports progress 0.0–1.0.
  static Future<void> downloadAndInstall(
    String url, {
    required void Function(double) onProgress,
    required void Function(String) onError,
  }) async {
    try {
      // Request install-unknown-apps permission (Android 8+).
      final perm = await Permission.requestInstallPackages.request();
      if (!perm.isGranted) {
        onError('Install permission denied — go to Settings > Special app access > Install unknown apps and enable Elegant Tile.');
        return;
      }

      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/tile_manager_update.apk');

      final req      = http.Request('GET', Uri.parse(url));
      final response = await req.send().timeout(const Duration(minutes: 5));
      final total    = response.contentLength ?? 0;
      int received   = 0;

      final sink = file.openWrite();
      await response.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }).asFuture();
      await sink.flush();
      await sink.close();

      onProgress(1.0);
      await OpenFilex.open(file.path);
    } catch (e) {
      onError('Download failed: $e');
    }
  }
}
