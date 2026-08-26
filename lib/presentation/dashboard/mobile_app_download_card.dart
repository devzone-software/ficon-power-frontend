import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/ficon_theme.dart';
import 'dashboard_section_header.dart';

class MobileAppDownloadCard extends StatelessWidget {
  const MobileAppDownloadCard({super.key});

  static final Uri _apkUri = Uri(path: '/mobile/ficon-power.apk');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final header = const DashboardSectionHeader(
              icon: Icons.phone_android_outlined,
              color: FiconColors.cyanSoft,
              title: 'App móvil',
              subtitle: 'Descarga la versión Android publicada en este VPS',
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
                children: [header, const SizedBox(height: 16), button],
              );
            }
            return Row(
              children: [
                Expanded(child: header),
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
