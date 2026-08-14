import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../widgets/common.dart';
import 'admin_table_shell.dart';

class AuditTab extends StatelessWidget {
  const AuditTab({
    super.key,
    required this.logs,
    required this.onRefresh,
    required this.filters,
  });

  final List<AuditLogEntry> logs;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return AdminTableShell(
      onRefresh: onRefresh,
      filters: filters,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Acción')),
          DataColumn(label: Text('Entidad')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Navegador')),
        ],
        rows: [
          for (final log in logs)
            DataRow(
              cells: [
                DataCell(Text(formatDateTime(log.createdAt))),
                DataCell(
                  Text('${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}'),
                ),
                DataCell(Text(log.action)),
                DataCell(Text('${log.entityType} ${log.entityId ?? ''}')),
                DataCell(Text(log.ipAddress ?? '—')),
                DataCell(AdminEllipsisText(log.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}
