import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../mobile/updates/mobile_update_service.dart';
import '../theme/ficon_theme.dart';
import 'dashboard_section_header.dart';

class MobileAppDownloadCard extends StatefulWidget {
  const MobileAppDownloadCard({super.key});

  @override
  State<MobileAppDownloadCard> createState() => _MobileAppDownloadCardState();
}

class _MobileAppDownloadCardState extends State<MobileAppDownloadCard> {
  late final MobileUpdateService _versions;
  late Future<MobileUpdateManifest?> _manifest;

  static final Uri _apkUri = Uri(path: '/mobile/ficon-power.apk');

  @override
  void initState() {
    super.initState();
    _versions = MobileUpdateService(
      manifestUri: Uri.base.resolve('/mobile/version.json'),
      installedVersionCode: 0,
    );
    _manifest = _versions.fetchManifest();
  }

  @override
  void dispose() {
    _versions.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const header = DashboardSectionHeader(
              icon: Icons.phone_android_outlined,
              color: FiconColors.cyanSoft,
              title: 'App móvil',
              subtitle: 'Versión Android publicada en este VPS',
            );
            final version = _PublishedVersion(
              manifest: _manifest,
              onRetry: () => setState(
                () => _manifest = _versions.fetchManifest(),
              ),
            );
            final button = FilledButton.icon(
              onPressed: () =>
                  launchUrl(_apkUri, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Descargar APK'),
            );
            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: version),
                  const SizedBox(height: 16),
                  button,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                version,
                const SizedBox(width: 16),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PublishedVersion extends StatelessWidget {
  const _PublishedVersion({required this.manifest, required this.onRetry});

  final Future<MobileUpdateManifest?> manifest;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MobileUpdateManifest?>(
      future: manifest,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final version = snapshot.data;
        if (snapshot.hasError || version == null) {
          return Tooltip(
            message: 'No se pudo consultar /mobile/version.json',
            child: ActionChip(
              avatar: const Icon(Icons.refresh, size: 17),
              label: const Text('Versión no disponible'),
              onPressed: onRetry,
            ),
          );
        }
        final architecture = version.architecture.trim();
        return Chip(
          avatar: const Icon(Icons.android, size: 17),
          label: Text(
            architecture.isEmpty
                ? 'v${version.versionName} · build ${version.versionCode}'
                : 'v${version.versionName} · build '
                      '${version.versionCode} · $architecture',
          ),
        );
      },
    );
  }
}
