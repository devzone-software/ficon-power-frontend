// Consulta y validación del manifiesto de actualización móvil.
import 'dart:convert';

import 'package:http/http.dart' as http;

class MobileUpdateManifest {
  const MobileUpdateManifest({
    required this.versionCode,
    required this.versionName,
    required this.apkUri,
    required this.notes,
    required this.required,
    this.architecture = '',
  });

  final int versionCode;
  final String versionName;
  final Uri apkUri;
  final String notes;
  final bool required;
  final String architecture;

  factory MobileUpdateManifest.fromJson(Map<String, dynamic> json) {
    return MobileUpdateManifest(
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      versionName: json['versionName'] as String? ?? '',
      apkUri: Uri.parse(json['apkUrl'] as String? ?? ''),
      notes: json['notes'] as String? ?? '',
      required: json['required'] as bool? ?? false,
      architecture: json['architecture'] as String? ?? '',
    );
  }
}

class MobileUpdateService {
  MobileUpdateService({
    required this.manifestUri,
    required this.installedVersionCode,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final Uri manifestUri;
  final int installedVersionCode;
  final http.Client _client;
  final bool _ownsClient;

  Future<MobileUpdateManifest?> findAvailableUpdate() async {
    final manifest = await fetchManifest();
    if (manifest == null) return null;
    return manifest.versionCode > installedVersionCode ? manifest : null;
  }

  Future<MobileUpdateManifest?> fetchManifest() async {
    final response = await _client
        .get(manifestUri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final manifest = MobileUpdateManifest.fromJson(
      (jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>)
          .cast<String, dynamic>(),
    );
    if (manifest.versionCode <= 0 || manifest.versionName.trim().isEmpty) {
      return null;
    }
    return manifest;
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  static Uri resolveManifestUri({
    required String configuredUrl,
    required String apiBaseUrl,
  }) {
    final configured = configuredUrl.trim();
    if (configured.isNotEmpty) return Uri.parse(configured);
    final base = apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return Uri.parse('$base/mobile/version.json');
  }
}
