import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/auth_session.dart';

class MobileUpdateChecker extends StatefulWidget {
  const MobileUpdateChecker({
    super.key,
    required this.session,
    required this.child,
    this.checkInterval = const Duration(minutes: 30),
  });

  final AuthSession session;
  final Widget child;
  final Duration checkInterval;

  @override
  State<MobileUpdateChecker> createState() => _MobileUpdateCheckerState();
}

class _MobileUpdateCheckerState extends State<MobileUpdateChecker> {
  Timer? _timer;
  bool _checking = false;
  int? _lastPromptedVersionCode;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_handleSessionChange);
    _handleSessionChange();
  }

  @override
  void dispose() {
    widget.session.removeListener(_handleSessionChange);
    _timer?.cancel();
    super.dispose();
  }

  void _handleSessionChange() {
    if (!mounted) return;
    if (widget.session.isAuthenticated) {
      _timer ??= Timer.periodic(widget.checkInterval, (_) => _check());
      unawaited(_check());
    } else {
      _timer?.cancel();
      _timer = null;
      _lastPromptedVersionCode = null;
    }
  }

  Future<void> _check() async {
    if (_checking || !widget.session.isAuthenticated) return;
    _checking = true;
    try {
      final manifest = await _fetchManifest();
      if (manifest == null || !mounted) return;
      if (manifest.versionCode <= AppConfig.appVersionCode) return;
      if (_lastPromptedVersionCode == manifest.versionCode) return;

      _lastPromptedVersionCode = manifest.versionCode;
      await _showUpdateDialog(manifest);
    } catch (_) {
      // Si el manifest no existe o no hay red, no bloquea la app.
    } finally {
      _checking = false;
    }
  }

  Future<_MobileUpdateManifest?> _fetchManifest() async {
    final response = await http
        .get(_manifestUri(), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    return _MobileUpdateManifest.fromJson(
      (jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>)
          .cast<String, dynamic>(),
    );
  }

  Uri _manifestUri() {
    final configured = AppConfig.mobileUpdateManifestUrl.trim();
    if (configured.isNotEmpty) return Uri.parse(configured);

    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return Uri.parse('$base/mobile/version.json');
  }

  Future<void> _showUpdateDialog(_MobileUpdateManifest manifest) async {
    final context = this.context;
    return showDialog<void>(
      context: context,
      barrierDismissible: !manifest.required,
      builder: (context) => AlertDialog(
        title: const Text('Actualización disponible'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versión ${manifest.versionName} disponible. '
              'Tu versión actual es ${AppConfig.appVersionName}.',
            ),
            if (manifest.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(manifest.notes),
            ],
          ],
        ),
        actions: [
          if (!manifest.required)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Después'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(
                launchUrl(
                  manifest.apkUri,
                  mode: LaunchMode.externalApplication,
                ),
              );
            },
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MobileUpdateManifest {
  const _MobileUpdateManifest({
    required this.versionCode,
    required this.versionName,
    required this.apkUri,
    required this.notes,
    required this.required,
  });

  final int versionCode;
  final String versionName;
  final Uri apkUri;
  final String notes;
  final bool required;

  factory _MobileUpdateManifest.fromJson(Map<String, dynamic> json) {
    return _MobileUpdateManifest(
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      versionName: json['versionName'] as String? ?? '',
      apkUri: Uri.parse(json['apkUrl'] as String? ?? ''),
      notes: json['notes'] as String? ?? '',
      required: json['required'] as bool? ?? false,
    );
  }
}
