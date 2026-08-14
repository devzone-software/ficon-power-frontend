import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'admin_table_shell.dart';

class BlockedUsersTab extends StatelessWidget {
  const BlockedUsersTab({
    super.key,
    required this.blockedUsers,
    required this.onUnblock,
    required this.onRefresh,
    required this.filters,
  });

  final List<BlockedLoginUser> blockedUsers;
  final ValueChanged<BlockedLoginUser> onUnblock;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return AdminTableShell(
      onRefresh: onRefresh,
      filters: filters,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Fallos'), numeric: true),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Bloqueado')),
          DataColumn(label: Text('Expira')),
          DataColumn(label: Text('Desbloqueado por')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: [
          for (final blocked in blockedUsers)
            DataRow(
              cells: [
                DataCell(Text(blocked.username)),
                DataCell(Text(blocked.displayName ?? '—')),
                DataCell(Text(blocked.ipAddress ?? '—')),
                DataCell(Text('${blocked.failedAttempts}')),
                DataCell(
                  StatusChip(
                    label: blocked.active ? 'Bloqueado' : 'Liberado/expirado',
                    color: blocked.active
                        ? FiconColors.logoBlue
                        : FiconColors.deepAlt,
                  ),
                ),
                DataCell(Text(formatDateTime(blocked.blockedAt))),
                DataCell(Text(formatDateTime(blocked.expiresAt))),
                DataCell(Text(blocked.unblockedByUsername ?? '—')),
                DataCell(
                  FilledButton.tonalIcon(
                    onPressed: blocked.active ? () => onUnblock(blocked) : null,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Desbloquear'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
