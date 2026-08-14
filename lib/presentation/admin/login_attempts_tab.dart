import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'admin_table_shell.dart';

class LoginAttemptsTab extends StatelessWidget {
  const LoginAttemptsTab({
    super.key,
    required this.attempts,
    required this.onRefresh,
    required this.filters,
  });

  final List<LoginAttempt> attempts;
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
          DataColumn(label: Text('Resultado')),
          DataColumn(label: Text('Motivo')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Navegador')),
        ],
        rows: [
          for (final attempt in attempts)
            DataRow(
              cells: [
                DataCell(Text(formatDateTime(attempt.createdAt))),
                DataCell(Text(attempt.username ?? '—')),
                DataCell(
                  StatusChip(
                    label: attempt.success ? 'Correcto' : 'Fallido',
                    color: attempt.success
                        ? FiconColors.cyan
                        : FiconColors.logoBlue,
                  ),
                ),
                DataCell(Text(attempt.reason ?? '—')),
                DataCell(Text(attempt.ipAddress ?? '—')),
                DataCell(AdminEllipsisText(attempt.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}
