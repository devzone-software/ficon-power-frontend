import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/auth_session.dart';
import 'mobile_update_service.dart';

class MobileUpdateChecker extends StatefulWidget {
  const MobileUpdateChecker({
    super.key,
    required this.session,
    required this.navigatorKey,
    required this.child,
    this.checkInterval = const Duration(minutes: 30),
  });

  final AuthSession session;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final Duration checkInterval;

  @override
  State<MobileUpdateChecker> createState() => _MobileUpdateCheckerState();
}

class _MobileUpdateCheckerState extends State<MobileUpdateChecker> {
  Timer? _timer;
  late final MobileUpdateService _updateService;
  bool _checking = false;
  int? _lastPromptedVersionCode;

  @override
  void initState() {
    super.initState();
    _updateService = MobileUpdateService(
      manifestUri: MobileUpdateService.resolveManifestUri(
        configuredUrl: AppConfig.mobileUpdateManifestUrl,
        apiBaseUrl: AppConfig.apiBaseUrl,
      ),
      installedVersionCode: AppConfig.appVersionCode,
    );
    widget.session.addListener(_handleSessionChange);
    _handleSessionChange();
  }

  @override
  void dispose() {
    widget.session.removeListener(_handleSessionChange);
    _timer?.cancel();
    _updateService.close();
    super.dispose();
  }

  void _handleSessionChange() {
    if (!mounted) return;
    if (widget.session.isAuthenticated) {
      _timer ??= Timer.periodic(widget.checkInterval, (_) => _check());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_check());
      });
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
      final manifest = await _updateService.findAvailableUpdate();
      if (manifest == null || !mounted) return;
      if (_lastPromptedVersionCode == manifest.versionCode) return;

      final prompted = await _showUpdateDialog(manifest);
      if (prompted) _lastPromptedVersionCode = manifest.versionCode;
    } catch (_) {
      // Si el manifest no existe o no hay red, no bloquea la app.
    } finally {
      _checking = false;
    }
  }

  Future<bool> _showUpdateDialog(MobileUpdateManifest manifest) async {
    final context =
        widget.navigatorKey.currentContext ??
        widget.navigatorKey.currentState?.overlay?.context;
    if (context == null) return false;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
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
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
