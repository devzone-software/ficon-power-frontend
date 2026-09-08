import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/user_error_message.dart';
import '../theme/ficon_theme.dart';

/// Formato de fecha/hora compartido por las vistas.
final DateFormat appDateFormat = DateFormat('dd/MM/yyyy HH:mm');

String formatDateTime(DateTime? value) =>
    value == null ? '—' : appDateFormat.format(value.toLocal());

String formatDurationSeconds(int? seconds) {
  if (seconds == null) return '—';
  final duration = Duration(seconds: seconds);
  if (duration.inDays > 0) {
    return '${duration.inDays} d ${duration.inHours % 24} h';
  }
  if (duration.inHours > 0) {
    return '${duration.inHours} h ${duration.inMinutes % 60} min';
  }
  if (duration.inMinutes > 0) return '${duration.inMinutes} min';
  return '${duration.inSeconds} s';
}

/// Colores de estado usados en toda la app.
class StatusColors {
  StatusColors._();

  static const Color online = FiconColors.success;
  static const Color offline = FiconColors.danger;
  static const Color acknowledged = FiconColors.warning;
  static const Color resolved = FiconColors.slate;
}

/// Etiqueta compacta con punto de color para estados.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de estado de un dispositivo (en línea / fuera de línea).
class DeviceStatusChip extends StatelessWidget {
  const DeviceStatusChip({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: online ? 'En línea' : 'Fuera de línea',
      color: online ? StatusColors.online : StatusColors.offline,
    );
  }
}

/// Chip de estado de un incidente (activo / atendido / resuelto).
class IncidentStatusChip extends StatelessWidget {
  const IncidentStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Activo', StatusColors.offline),
      'acknowledged' => ('Atendido', StatusColors.acknowledged),
      'resolved' => ('Resuelto', StatusColors.resolved),
      _ => (status, StatusColors.resolved),
    };
    return StatusChip(label: label, color: color);
  }
}

/// Vista de error con botón de reintento.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

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
            Icon(Icons.cloud_off,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los datos.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              UserErrorMessage.from(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje para listas vacías.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
