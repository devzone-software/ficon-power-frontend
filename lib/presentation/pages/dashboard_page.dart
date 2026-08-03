import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/device.dart';
import '../../domain/incident.dart';
import '../../domain/monitoring_overview.dart';
import '../../ports/input/get_monitoring_overview.dart';

/// Pantalla principal: resumen de sedes, dispositivos e incidentes.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.getOverview});

  final GetMonitoringOverview getOverview;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<MonitoringOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getOverview();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.getOverview());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FICON Power')),
      body: FutureBuilder<MonitoringOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(
              error: snapshot.error,
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _DashboardBody(data: snapshot.data!),
          );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final MonitoringOverview data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cardWidth =
                width >= 720 ? (width - 3 * 12) / 4 : (width - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard(
                  title: 'Sedes',
                  value: '${data.sites.length}',
                  width: cardWidth,
                ),
                _SummaryCard(
                  title: 'En línea',
                  value: '${data.onlineCount}',
                  valueColor: Colors.green.shade700,
                  width: cardWidth,
                ),
                _SummaryCard(
                  title: 'Fuera de línea',
                  value: '${data.offlineCount}',
                  valueColor:
                      data.offlineCount > 0 ? Colors.red.shade700 : null,
                  width: cardWidth,
                ),
                _SummaryCard(
                  title: 'Incidentes activos',
                  value: '${data.openIncidents}',
                  valueColor:
                      data.openIncidents > 0 ? Colors.red.shade700 : null,
                  width: cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _SectionTitle('Dispositivos'),
        if (data.devices.isEmpty)
          const _EmptyNote('No hay dispositivos registrados.')
        else
          ...data.devices.map(_DeviceTile.new),
        const SizedBox(height: 24),
        _SectionTitle('Incidentes recientes'),
        if (data.incidents.isEmpty)
          const _EmptyNote('No hay incidentes registrados.')
        else
          ...data.incidents.take(20).map(_IncidentTile.new),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.width,
    this.valueColor,
  });

  final String title;
  final String value;
  final double width;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                value,
                style: textTheme.headlineMedium?.copyWith(color: valueColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile(this.device);

  final Device device;

  @override
  Widget build(BuildContext context) {
    final online = device.isOnline;
    final subtitle = [
      if (device.siteName != null && device.siteName!.isNotEmpty)
        device.siteName!,
      if (device.district != null && device.district!.isNotEmpty)
        device.district!,
    ].join(' - ');
    return Card(
      child: ListTile(
        title: Text(
            device.name.isNotEmpty ? device.name : device.externalId ?? ''),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        trailing: Text(
          online ? 'En línea' : 'Fuera de línea',
          style: TextStyle(
            color: online ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile(this.incident);

  final Incident incident;

  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final start = incident.startTime;
    final subtitle = StringBuffer();
    if (incident.siteName != null && incident.siteName!.isNotEmpty) {
      subtitle.write(incident.siteName);
    }
    if (start != null) {
      if (subtitle.isNotEmpty) subtitle.write(' - ');
      subtitle.write('Inicio: ${_dateFormat.format(start.toLocal())}');
    }
    final duration = _durationLabel();
    if (duration != null) {
      if (subtitle.isNotEmpty) subtitle.write(' - ');
      subtitle.write(duration);
    }
    return Card(
      child: ListTile(
        title: Text(incident.deviceName ?? 'Dispositivo'),
        subtitle: subtitle.isNotEmpty ? Text(subtitle.toString()) : null,
        trailing: Text(
          _statusLabel(incident.status),
          style: TextStyle(
            color: incident.isOpen ? Colors.red.shade700 : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String? _durationLabel() {
    final seconds = incident.durationSeconds;
    if (seconds == null) return null;
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return 'Duración: ${duration.inHours} h ${duration.inMinutes % 60} min';
    }
    if (duration.inMinutes > 0) {
      return 'Duración: ${duration.inMinutes} min';
    }
    return 'Duración: ${duration.inSeconds} s';
  }

  static String _statusLabel(String status) => switch (status) {
        'active' => 'Activo',
        'acknowledged' => 'Atendido',
        'resolved' => 'Resuelto',
        _ => status,
      };
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se pudieron cargar los datos.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
