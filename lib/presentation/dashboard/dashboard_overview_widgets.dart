part of '../pages/dashboard_page.dart';

class _FiconOverviewHeader extends StatelessWidget {
  const _FiconOverviewHeader({
    required this.online,
    required this.total,
    required this.openIncidents,
  });

  final int online;
  final int total;
  final int openIncidents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onlineText = total == 0
        ? 'Sin dispositivos'
        : '$online/$total online';
    final incidentText = openIncidents == 0
        ? 'Operación estable'
        : '$openIncidents incidentes';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FiconColors.cardBorderSoft),
        boxShadow: [
          BoxShadow(
            color: FiconColors.logoBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: FiconColors.logoBlue),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FiconBrandMark(
                            height: 36,
                            showPowerLabel: false,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Panel de continuidad FICON',
                              style: textTheme.titleLarge?.copyWith(
                                color: FiconColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Monitoreo eléctrico para mantener tu red estable, veloz y conectada.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: FiconColors.slate,
                        ),
                      ),
                    ],
                  );
                  final chips = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeaderChip(
                        icon: Icons.wifi_tethering,
                        label: onlineText,
                        accent: FiconColors.cyan,
                      ),
                      _HeaderChip(
                        icon: openIncidents == 0
                            ? Icons.verified_outlined
                            : Icons.bolt_outlined,
                        label: incidentText,
                        accent: openIncidents == 0
                            ? FiconColors.cyan
                            : FiconColors.warning,
                      ),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [intro, const SizedBox(height: 18), chips],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: intro),
                      const SizedBox(width: 16),
                      chips,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip compacto para el encabezado de resumen.
class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: FiconColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.getNotificationTemplates,
    required this.currentUser,
  });

  final MonitoringOverview data;
  final GetNotificationTemplates getNotificationTemplates;
  final AuthUser currentUser;

  @override
  Widget build(BuildContext context) {
    final offlineDevices = data.devices
        .where((d) => !d.isOnline && d.active)
        .toList();
    final recentIncidents = data.incidents.take(6).toList();
    final stats = _DashboardStats.from(data);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                _FiconOverviewHeader(
                  online: data.onlineCount,
                  total: data.devices.length,
                  openIncidents: data.openIncidents,
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final spacing = width >= 560 ? 16.0 : 10.0;
                    final compactCards = width < 560;
                    final cardWidth = width >= 900
                        ? (width - 3 * spacing) / 4
                        : (width - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _KpiCard(
                          title: 'Sedes',
                          value: '${data.sites.length}',
                          icon: Icons.business,
                          color: FiconColors.logoBlue,
                          width: cardWidth,
                          compact: compactCards,
                        ),
                        _KpiCard(
                          title: 'Dispositivos',
                          value: '${data.devices.length}',
                          icon: Icons.electrical_services,
                          color: FiconColors.cyanSoft,
                          width: cardWidth,
                          compact: compactCards,
                        ),
                        _KpiCard(
                          title: 'En línea',
                          value: '${data.onlineCount}',
                          icon: Icons.check_circle_outline,
                          color: StatusColors.online,
                          width: cardWidth,
                          compact: compactCards,
                        ),
                        _KpiCard(
                          title: 'Incidentes activos',
                          value: '${data.openIncidents}',
                          icon: Icons.warning_amber,
                          color: data.openIncidents > 0
                              ? StatusColors.offline
                              : StatusColors.online,
                          width: cardWidth,
                          compact: compactCards,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _FleetHealthCard(
                  online: data.onlineCount,
                  total: data.devices.length,
                ),
                const SizedBox(height: 24),
                _DashboardAnalyticsSection(stats: stats),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final lists = [
                      _OfflineDevicesCard(devices: offlineDevices),
                      _RecentIncidentsCard(incidents: recentIncidents),
                    ];
                    if (!wide) {
                      return Column(
                        children: [
                          lists[0],
                          const SizedBox(height: 24),
                          lists[1],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: lists[0]),
                        const SizedBox(width: 24),
                        Expanded(child: lists[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _NotificationTemplatesCard(
                  getNotificationTemplates: getNotificationTemplates,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 24),
                  const _MobileAppDownloadCard(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileAppDownloadCard extends StatelessWidget {
  const _MobileAppDownloadCard();

  static final Uri _apkUri = Uri(path: '/mobile/ficon-power.apk');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final header = const _SectionHeader(
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

            if (compact) {
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

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
    this.compact = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: compact ? 20 : 24),
              ),
              SizedBox(height: compact ? 10 : 16),
              Text(
                value,
                style: textTheme.headlineMedium?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 24 : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: FiconColors.slate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetHealthCard extends StatelessWidget {
  const _FleetHealthCard({required this.online, required this.total});

  final int online;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ratio = total == 0
        ? 0.0
        : (online / total).clamp(0.0, 1.0).toDouble();
    final percent = (ratio * 100).round();
    final offline = total > online ? total - online : 0;
    final color = ratio >= 0.9
        ? StatusColors.online
        : ratio >= 0.5
        ? StatusColors.acknowledged
        : StatusColors.offline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SectionHeader(
                    icon: Icons.monitor_heart_outlined,
                    color: FiconColors.logoBlue,
                    title: 'Disponibilidad de dispositivos',
                    subtitle: 'Señal estable para la red monitoreada',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percent %',
                  style: textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Stack(
                  children: [
                    Container(color: FiconColors.cardBorderSoft),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(color: color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendDot(
                  color: StatusColors.online,
                  label: '$online en línea',
                ),
                _LegendDot(
                  color: StatusColors.offline,
                  label: '$offline fuera de línea',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
