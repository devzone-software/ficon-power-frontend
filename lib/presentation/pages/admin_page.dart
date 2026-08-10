import 'dart:async';

import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../domain/admin_models.dart';
import '../../domain/auth_user.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onLogout,
  });

  final FiconMonitoringRepository repository;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const _liveRefreshInterval = Duration(seconds: 5);

  _AdminData? _data;
  Object? _error;
  Timer? _liveRefreshTimer;
  bool _loading = true;
  bool _refreshing = false;
  String _usersFilter = '';
  String _blockedUsersFilter = '';
  String _auditLogsFilter = '';
  String _loginAttemptsFilter = '';
  String _sessionsFilter = '';

  @override
  void initState() {
    super.initState();
    _refresh(showLoading: true);
    _liveRefreshTimer = Timer.periodic(
      _liveRefreshInterval,
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  Future<_AdminData> _load() async {
    final results = await Future.wait([
      widget.repository.fetchUsers(),
      widget.repository.fetchAuditLogs(),
      widget.repository.fetchLoginAttempts(),
      widget.repository.fetchAdminSessions(),
      widget.repository.fetchBlockedUsers(),
    ]);
    return _AdminData(
      users: results[0] as List<ManagedUser>,
      auditLogs: results[1] as List<AuditLogEntry>,
      loginAttempts: results[2] as List<LoginAttempt>,
      sessions: results[3] as List<AdminSession>,
      blockedUsers: results[4] as List<BlockedLoginUser>,
    );
  }

  Future<void> _refresh({bool showLoading = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _openUserDialog([ManagedUser? user]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _UserDialog(repository: widget.repository, user: user),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(user == null ? 'Usuario creado.' : 'Usuario actualizado.')),
      );
      await _refresh();
    }
  }

  Future<void> _unblockUser(BlockedLoginUser blockedUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desbloquear usuario'),
        content: Text(
          '¿Permitir nuevamente el inicio de sesión de '
          '${blockedUser.username} desde ${blockedUser.ipAddress ?? 'esta IP'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.unblockBlockedUser(blockedUser.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${blockedUser.username} desbloqueado.')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo desbloquear: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.admin,
      title: 'Administración',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return ErrorView(error: _error, onRetry: () => _refresh(showLoading: true));
    }

    final data = _data!;
    final users = _filterRows(data.users, _usersFilter, _userSearchValues);
    final blockedUsers = _filterRows(
      data.blockedUsers,
      _blockedUsersFilter,
      _blockedUserSearchValues,
    );
    final auditLogs = _filterRows(data.auditLogs, _auditLogsFilter, _auditLogSearchValues);
    final loginAttempts = _filterRows(
      data.loginAttempts,
      _loginAttemptsFilter,
      _loginAttemptSearchValues,
    );
    final sessions = _filterRows(data.sessions, _sessionsFilter, _sessionSearchValues);

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  labelColor: FiconColors.logoBlue,
                  unselectedLabelColor: FiconColors.deepAlt,
                  tabs: const [
                    Tab(text: 'Usuarios'),
                    Tab(text: 'Bloqueados'),
                    Tab(text: 'Audit logs'),
                    Tab(text: 'Logins'),
                    Tab(text: 'Sesiones'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _UsersTab(
                  users: users,
                  onCreate: () => _openUserDialog(),
                  onEdit: _openUserDialog,
                  onRefresh: _refresh,
                  filterValue: _usersFilter,
                  filterOptions: _uniqueOptions(data.users, _userSearchValues),
                  onFilterChanged: (value) => setState(() => _usersFilter = value),
                ),
                _BlockedUsersTab(
                  blockedUsers: blockedUsers,
                  onUnblock: _unblockUser,
                  onRefresh: _refresh,
                  filterValue: _blockedUsersFilter,
                  filterOptions: _uniqueOptions(data.blockedUsers, _blockedUserSearchValues),
                  onFilterChanged: (value) => setState(() => _blockedUsersFilter = value),
                ),
                _AuditTab(
                  logs: auditLogs,
                  onRefresh: _refresh,
                  filterValue: _auditLogsFilter,
                  filterOptions: _uniqueOptions(data.auditLogs, _auditLogSearchValues),
                  onFilterChanged: (value) => setState(() => _auditLogsFilter = value),
                ),
                _LoginAttemptsTab(
                  attempts: loginAttempts,
                  onRefresh: _refresh,
                  filterValue: _loginAttemptsFilter,
                  filterOptions: _uniqueOptions(data.loginAttempts, _loginAttemptSearchValues),
                  onFilterChanged: (value) => setState(() => _loginAttemptsFilter = value),
                ),
                _SessionsTab(
                  sessions: sessions,
                  onRefresh: _refresh,
                  filterValue: _sessionsFilter,
                  filterOptions: _uniqueOptions(data.sessions, _sessionSearchValues),
                  onFilterChanged: (value) => setState(() => _sessionsFilter = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<T> _filterRows<T>(
    List<T> rows,
    String query,
    List<String?> Function(T row) valuesForRow,
  ) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return rows;
    return [
      for (final row in rows)
        if (valuesForRow(row).any((value) => _normalize(value ?? '').contains(normalizedQuery))) row,
    ];
  }

  List<String> _uniqueOptions<T>(
    List<T> rows,
    List<String?> Function(T row) valuesForRow,
  ) {
    final byNormalizedValue = <String, String>{};
    for (final row in rows) {
      for (final value in valuesForRow(row)) {
        final cleanValue = value?.trim();
        if (cleanValue == null || cleanValue.isEmpty || cleanValue == '—') continue;
        byNormalizedValue.putIfAbsent(_normalize(cleanValue), () => cleanValue);
      }
    }
    final options = byNormalizedValue.values.toList()
      ..sort((a, b) => _normalize(a).compareTo(_normalize(b)));
    return options;
  }

  List<String?> _userSearchValues(ManagedUser user) => [
        user.username,
        user.displayName,
        user.role,
        user.active ? 'Activo' : 'Revocado',
      ];

  List<String?> _blockedUserSearchValues(BlockedLoginUser blockedUser) => [
        blockedUser.username,
        blockedUser.displayName,
        blockedUser.ipAddress,
        '${blockedUser.failedAttempts}',
        blockedUser.active ? 'Bloqueado' : 'Liberado/expirado',
        formatDateTime(blockedUser.blockedAt),
        formatDateTime(blockedUser.expiresAt),
        blockedUser.unblockedByUsername,
      ];

  List<String?> _auditLogSearchValues(AuditLogEntry log) => [
        formatDateTime(log.createdAt),
        log.actorUsername,
        log.actorRole,
        log.action,
        log.entityType,
        log.entityId,
        log.ipAddress,
        log.userAgent,
        log.metadata,
      ];

  List<String?> _loginAttemptSearchValues(LoginAttempt attempt) => [
        formatDateTime(attempt.createdAt),
        attempt.username,
        attempt.success ? 'Correcto' : 'Fallido',
        attempt.reason,
        attempt.ipAddress,
        attempt.userAgent,
      ];

  List<String?> _sessionSearchValues(AdminSession session) => [
        formatDateTime(session.createdAt),
        session.username,
        session.role,
        session.active ? 'Activa' : 'Cerrada/expirada',
        formatDateTime(session.expiresAt),
        session.ipAddress,
        session.userAgent,
      ];
}

class _AdminData {
  const _AdminData({
    required this.users,
    required this.auditLogs,
    required this.loginAttempts,
    required this.sessions,
    required this.blockedUsers,
  });

  final List<ManagedUser> users;
  final List<AuditLogEntry> auditLogs;
  final List<LoginAttempt> loginAttempts;
  final List<AdminSession> sessions;
  final List<BlockedLoginUser> blockedUsers;
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({
    required this.users,
    required this.onCreate,
    required this.onEdit,
    required this.onRefresh,
    required this.filterValue,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  final List<ManagedUser> users;
  final VoidCallback onCreate;
  final ValueChanged<ManagedUser> onEdit;
  final Future<void> Function() onRefresh;
  final String filterValue;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filterLabel: 'Filtrar usuarios',
      filterValue: filterValue,
      filterOptions: filterOptions,
      onFilterChanged: onFilterChanged,
      action: FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Crear usuario'),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Rol')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: [
          for (final user in users)
            DataRow(
              cells: [
                DataCell(Text(user.username)),
                DataCell(Text(user.displayName)),
                DataCell(StatusChip(label: user.role, color: FiconColors.logoBlue)),
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

class _BlockedUsersTab extends StatelessWidget {
  const _BlockedUsersTab({
    required this.blockedUsers,
    required this.onUnblock,
    required this.onRefresh,
    required this.filterValue,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  final List<BlockedLoginUser> blockedUsers;
  final ValueChanged<BlockedLoginUser> onUnblock;
  final Future<void> Function() onRefresh;
  final String filterValue;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filterLabel: 'Filtrar bloqueados',
      filterValue: filterValue,
      filterOptions: filterOptions,
      onFilterChanged: onFilterChanged,
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
                    color: blocked.active ? FiconColors.logoBlue : FiconColors.deepAlt,
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

class _AuditTab extends StatelessWidget {
  const _AuditTab({
    required this.logs,
    required this.onRefresh,
    required this.filterValue,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  final List<AuditLogEntry> logs;
  final Future<void> Function() onRefresh;
  final String filterValue;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filterLabel: 'Filtrar audit logs',
      filterValue: filterValue,
      filterOptions: filterOptions,
      onFilterChanged: onFilterChanged,
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
                DataCell(Text('${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}')),
                DataCell(Text(log.action)),
                DataCell(Text('${log.entityType} ${log.entityId ?? ''}')),
                DataCell(Text(log.ipAddress ?? '—')),
                DataCell(_EllipsisText(log.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _LoginAttemptsTab extends StatelessWidget {
  const _LoginAttemptsTab({
    required this.attempts,
    required this.onRefresh,
    required this.filterValue,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  final List<LoginAttempt> attempts;
  final Future<void> Function() onRefresh;
  final String filterValue;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filterLabel: 'Filtrar inicios de sesión',
      filterValue: filterValue,
      filterOptions: filterOptions,
      onFilterChanged: onFilterChanged,
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
                    color: attempt.success ? FiconColors.cyan : FiconColors.logoBlue,
                  ),
                ),
                DataCell(Text(attempt.reason ?? '—')),
                DataCell(Text(attempt.ipAddress ?? '—')),
                DataCell(_EllipsisText(attempt.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({
    required this.sessions,
    required this.onRefresh,
    required this.filterValue,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  final List<AdminSession> sessions;
  final Future<void> Function() onRefresh;
  final String filterValue;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filterLabel: 'Filtrar sesiones',
      filterValue: filterValue,
      filterOptions: filterOptions,
      onFilterChanged: onFilterChanged,
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
                    color: session.active ? FiconColors.cyan : FiconColors.deepAlt,
                  ),
                ),
                DataCell(Text(formatDateTime(session.expiresAt))),
                DataCell(Text(session.ipAddress ?? '—')),
                DataCell(_EllipsisText(session.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  const _TableShell({
    required this.child,
    required this.onRefresh,
    this.action,
    this.filterLabel,
    this.filterValue,
    this.filterOptions,
    this.onFilterChanged,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? action;
  final String? filterLabel;
  final String? filterValue;
  final List<String>? filterOptions;
  final ValueChanged<String>? onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final canFilter =
        filterLabel != null && filterValue != null && filterOptions != null && onFilterChanged != null;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canFilter || action != null) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      if (canFilter)
                        SizedBox(
                          width: 360,
                          child: _SearchableTableFilter(
                            label: filterLabel!,
                            value: filterValue!,
                            options: filterOptions!,
                            onChanged: onFilterChanged!,
                          ),
                        ),
                      if (action != null) action!,
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchableTableFilter extends StatefulWidget {
  const _SearchableTableFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchableTableFilter> createState() => _SearchableTableFilterState();
}

class _SearchableTableFilterState extends State<_SearchableTableFilter> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _SearchableTableFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        return _rankedMatches(widget.options, textEditingValue.text);
      },
      onSelected: (selected) {
        _controller.text = selected;
        _controller.selection = TextSelection.collapsed(offset: selected.length);
        widget.onChanged(selected);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: 'Escribe o selecciona un valor',
                prefixIcon: const Icon(Icons.filter_alt_outlined),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar filtro',
                        onPressed: () {
                          controller.clear();
                          widget.onChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final visibleOptions = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: visibleOptions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = visibleOptions[index];
                  return ListTile(
                    dense: true,
                    title: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

Iterable<String> _rankedMatches(List<String> options, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return options.take(30);

  final prefixMatches = <String>[];
  final start = _lowerBoundByNormalized(options, normalizedQuery);
  for (var index = start; index < options.length && prefixMatches.length < 20; index++) {
    final option = options[index];
    if (!_normalize(option).startsWith(normalizedQuery)) break;
    prefixMatches.add(option);
  }

  final seen = prefixMatches.toSet();
  final containsMatches = <String>[];
  for (final option in options) {
    if (prefixMatches.length + containsMatches.length >= 30) break;
    if (seen.contains(option)) continue;
    if (_normalize(option).contains(normalizedQuery)) containsMatches.add(option);
  }

  return [...prefixMatches, ...containsMatches];
}

int _lowerBoundByNormalized(List<String> options, String query) {
  var low = 0;
  var high = options.length;
  while (low < high) {
    final middle = low + ((high - low) >> 1);
    if (_normalize(options[middle]).compareTo(query) < 0) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low;
}

String _normalize(String value) => value.trim().toLowerCase();

class _UserDialog extends StatefulWidget {
  const _UserDialog({required this.repository, this.user});

  final FiconMonitoringRepository repository;
  final ManagedUser? user;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final TextEditingController _username;
  late final TextEditingController _displayName;
  late final TextEditingController _password;
  late String _role;
  late bool _active;
  bool _saving = false;
  bool _showPassword = false;
  String? _error;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user?.username ?? '');
    _displayName = TextEditingController(text: widget.user?.displayName ?? '');
    _password = TextEditingController();
    _role = widget.user?.role ?? 'USER';
    _active = widget.user?.active ?? true;
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await widget.repository.updateUser(
          widget.user!.id,
          role: _role,
          displayName: _displayName.text.trim(),
          active: _active,
          password: _password.text.trim(),
        );
      } else {
        await widget.repository.createUser(
          username: _username.text.trim(),
          password: _password.text.trim(),
          role: _role,
          displayName: _displayName.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar usuario' : 'Crear usuario'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _username,
                enabled: !_isEdit && !_saving,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayName,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Nombre visible'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'USER', child: Text('USER · sólo lectura')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN · edición')),
                  DropdownMenuItem(value: 'SUPERADMIN', child: Text('SUPERADMIN · control total')),
                ],
                onChanged: _saving ? null : (value) => setState(() => _role = value ?? 'USER'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acceso activo'),
                subtitle: const Text('Apágalo para revocar el acceso del usuario.'),
                value: _active,
                onChanged: _saving ? null : (value) => setState(() => _active = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_saving,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: _isEdit ? 'Nueva contraseña opcional' : 'Contraseña',
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                    onPressed: _saving
                        ? null
                        : () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: StatusColors.offline)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}

class _EllipsisText extends StatelessWidget {
  const _EllipsisText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
