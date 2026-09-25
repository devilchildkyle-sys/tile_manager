import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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
    final current = _parseVersion(currentVersion);
    final latest  = _parseVersion(latestVersion);
    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    final clean = v.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) parts.add(0);
    return parts;
  }
}

class UpdateService {
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag  = (data['tag_name'] as String? ?? '').replaceAll('v', '');
      final body = data['body'] as String? ?? '';

      final assets = (data['assets'] as List? ?? []);
      final apkAsset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );
      final downloadUrl = apkAsset != null
          ? apkAsset['browser_download_url'] as String
          : 'https://github.com/$_owner/$_repo/releases/latest';

      return UpdateInfo(
        latestVersion: tag,
        currentVersion: current,
        downloadUrl: downloadUrl,
        releaseNotes: body,
      );
    } catch (_) {
      return null;
    }
  }
}
