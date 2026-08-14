import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'admin_table_shell.dart';

class SessionsTab extends StatelessWidget {
  const SessionsTab({
    super.key,
    required this.sessions,
    required this.onRefresh,
    required this.filters,
  });

  final List<AdminSession> sessions;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return AdminTableShell(
      onRefresh: onRefresh,
      filters: filters,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Creada')),
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Rol')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Expira')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Navegador')),
        ],
        rows: [
          for (final session in sessions)
            DataRow(
              cells: [
                DataCell(Text(formatDateTime(session.createdAt))),
                DataCell(Text(session.username)),
                DataCell(Text(session.role)),
                DataCell(
                  StatusChip(
                    label: session.active ? 'Activa' : 'Cerrada/expirada',
                    color: session.active
                        ? FiconColors.cyan
                        : FiconColors.deepAlt,
                  ),
                ),
                DataCell(Text(formatDateTime(session.expiresAt))),
                DataCell(Text(session.ipAddress ?? '—')),
                DataCell(AdminEllipsisText(session.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}
