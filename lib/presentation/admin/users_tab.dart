import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'admin_table_shell.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({
    super.key,
    required this.users,
    required this.onCreate,
    required this.onEdit,
    required this.onOpen,
    required this.onRefresh,
    required this.filters,
  });

  final List<ManagedUser> users;
  final VoidCallback onCreate;
  final ValueChanged<ManagedUser> onEdit;
  final ValueChanged<ManagedUser> onOpen;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return AdminTableShell(
      onRefresh: onRefresh,
      filters: filters,
      action: FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Crear usuario'),
      ),
      mobileChild: Column(
        children: [
          for (final user in users)
            _UserCompactCard(user: user, onOpen: onOpen),
        ],
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('WhatsApp')),
          DataColumn(label: Text('Rol')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: [
          for (final user in users)
            DataRow(
              onSelectChanged: (_) => onOpen(user),
              cells: [
                DataCell(Text(user.username)),
                DataCell(Text(user.displayName)),
                DataCell(_WhatsAppAssignment(user: user)),
                DataCell(
                  StatusChip(label: user.role, color: FiconColors.logoBlue),
                ),
                DataCell(
                  StatusChip(
                    label: user.active ? 'Activo' : 'Revocado',
                    color: user.active ? FiconColors.cyan : FiconColors.deepAlt,
                  ),
                ),
                DataCell(
                  IconButton(
                    tooltip: 'Editar rol, estado o contraseña',
                    onPressed: () => onEdit(user),
                    icon: const Icon(Icons.manage_accounts_outlined),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UserCompactCard extends StatelessWidget {
  const _UserCompactCard({required this.user, required this.onOpen});

  final ManagedUser user;
  final ValueChanged<ManagedUser> onOpen;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => onOpen(user),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FiconColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: FiconColors.slate),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusChip(
                        label: user.active ? 'Activo' : 'Revocado',
                        color: user.active
                            ? FiconColors.cyan
                            : FiconColors.deepAlt,
                      ),
                      _WhatsAppAssignment(user: user),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FiconColors.logoBlue),
          ],
        ),
      ),
    ),
  );
}

class _WhatsAppAssignment extends StatelessWidget {
  const _WhatsAppAssignment({required this.user});

  final ManagedUser user;

  @override
  Widget build(BuildContext context) {
    final enabled = user.active && user.hasWhatsapp && user.whatsappEnabled;
    return Tooltip(
      message: !user.hasWhatsapp
          ? 'Sin número de WhatsApp'
          : !user.active && user.whatsappEnabled
          ? 'Alertas configuradas, pero el acceso está revocado'
          : enabled
          ? 'Alertas de WhatsApp habilitadas'
          : 'Número asignado, alertas deshabilitadas',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 20,
            color: enabled ? FiconColors.logoBlue : FiconColors.slate,
          ),
          const SizedBox(width: 2),
          Icon(
            enabled ? Icons.check_box : Icons.check_box_outline_blank,
            size: 19,
            color: enabled ? FiconColors.logoBlue : FiconColors.slate,
          ),
        ],
      ),
    );
  }
}
