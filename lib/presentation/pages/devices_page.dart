import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/site.dart';
import '../../ports/input/create_site.dart';
import '../../ports/input/get_devices.dart';
import '../../ports/input/get_sites.dart';
import '../../ports/input/update_device_details.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/table_filters.dart';

/// Tabla de dispositivos monitoreados (vista de la tabla `devices`).
/// Permite editar el nombre y la sede de cada dispositivo.
class DevicesPage extends StatefulWidget {
  const DevicesPage({
    super.key,
    required this.getDevices,
    required this.getSites,
    required this.updateDeviceDetails,
    required this.createSite,
    required this.currentUser,
    required this.onLogout,
  });

  final GetDevices getDevices;
  final GetSites getSites;
  final UpdateDeviceDetails updateDeviceDetails;
  final CreateSite createSite;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  static const _autoRefreshInterval = Duration(seconds: 10);

  late Future<List<Device>> _future;
  Timer? _autoRefreshTimer;
  bool _refreshing = false;
  final Map<String, String> _textFilters = {};
  final Map<String, DateTime?> _dateFilters = {};

  @override
  void initState() {
    super.initState();
    _future = widget.getDevices();
    _autoRefreshTimer = Timer.periodic(
      _autoRefreshInterval,
      (_) => _refresh(),
    );
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    setState(() => _future = widget.getDevices());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _edit(Device device) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditDeviceDialog(
        device: device,
        getSites: widget.getSites,
        updateDeviceDetails: widget.updateDeviceDetails,
        createSite: widget.createSite,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispositivo actualizado.')),
      );
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.devices,
      title: 'Dispositivos',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      body: FutureBuilder<List<Device>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final devices = snapshot.data!;
          final filteredDevices = devices.where(_matchesFilters).toList();
          if (devices.isEmpty) {
            return const Center(
              child: Text('No hay dispositivos registrados.'),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      TableFiltersBar(filters: _filters(devices)),
                      if (filteredDevices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Text('No hay dispositivos con esos filtros.'),
                        )
                      else if (compact)
                        _DevicesCompactList(
                          devices: filteredDevices,
                          onEdit: _edit,
                          canEdit: widget.currentUser.canEditDevices,
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: _DevicesTable(
                              devices: filteredDevices,
                              onEdit: _edit,
                              canEdit: widget.currentUser.canEditDevices,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Widget> _filters(List<Device> devices) => [
        _textFilter(
          keyName: 'name',
          label: 'Nombre',
          options: uniqueColumnOptions(
            devices,
            (device) => device.name.isNotEmpty ? device.name : device.externalId,
          ),
        ),
        _textFilter(
          keyName: 'externalId',
          label: 'ID externo',
          options: uniqueColumnOptions(devices, (device) => device.externalId),
        ),
        _textFilter(
          keyName: 'site',
          label: 'Sede',
          options: uniqueColumnOptions(devices, (device) => device.siteName),
        ),
        _textFilter(
          keyName: 'district',
          label: 'Distrito',
          options: uniqueColumnOptions(devices, (device) => device.district),
        ),
        _textFilter(
          keyName: 'status',
          label: 'Estado',
          options: uniqueColumnOptions(
            devices,
            (device) => device.isOnline ? 'En línea' : 'Fuera de línea',
          ),
        ),
        DateColumnFilter(
          label: 'Último cambio',
          value: _dateFilters['lastStatusChange'],
          onChanged: (value) => setState(() => _dateFilters['lastStatusChange'] = value),
        ),
        _textFilter(
          keyName: 'incidents',
          label: 'Incidentes',
          options: uniqueColumnOptions(devices, (device) => '${device.incidentCount}'),
          width: 160,
        ),
      ];

  Widget _textFilter({
    required String keyName,
    required String label,
    required List<String> options,
    double width = 220,
  }) {
    return TextColumnFilter(
      label: label,
      value: _textFilters[keyName] ?? '',
      options: options,
      width: width,
      onChanged: (value) => setState(() => _textFilters[keyName] = value),
    );
  }

  bool _matchesFilters(Device device) {
    return matchesTextFilter(
          device.name.isNotEmpty ? device.name : device.externalId,
          _textFilters['name'] ?? '',
        ) &&
        matchesTextFilter(device.externalId, _textFilters['externalId'] ?? '') &&
        matchesTextFilter(device.siteName, _textFilters['site'] ?? '') &&
        matchesTextFilter(device.district, _textFilters['district'] ?? '') &&
        matchesTextFilter(
          device.isOnline ? 'En línea' : 'Fuera de línea',
          _textFilters['status'] ?? '',
        ) &&
        matchesDateFilter(device.lastStatusChange, _dateFilters['lastStatusChange']) &&
        matchesTextFilter('${device.incidentCount}', _textFilters['incidents'] ?? '');
  }
}

class _DevicesTable extends StatelessWidget {
  const _DevicesTable({
    required this.devices,
    required this.onEdit,
    required this.canEdit,
  });

  final List<Device> devices;
  final ValueChanged<Device> onEdit;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('ID externo')),
        DataColumn(label: Text('Sede')),
        DataColumn(label: Text('Distrito')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Último cambio')),
        DataColumn(label: Text('Incidentes'), numeric: true),
        DataColumn(label: Text('Indisponibilidad'), numeric: true),
        DataColumn(label: Text('Acciones')),
      ],
      rows: [
        for (final device in devices)
          DataRow(
            cells: [
              DataCell(Text(device.name.isNotEmpty
                  ? device.name
                  : device.externalId ?? '')),
              DataCell(Text(device.externalId ?? '')),
              DataCell(Text(device.siteName ?? '')),
              DataCell(Text(device.district ?? '')),
              DataCell(DeviceStatusChip(online: device.isOnline)),
              DataCell(Text(formatDateTime(device.lastStatusChange))),
              DataCell(Text('${device.incidentCount}')),
              DataCell(
                Text(formatDurationSeconds(device.totalDowntimeSeconds)),
              ),
              DataCell(
                IconButton(
                  onPressed: canEdit ? () => onEdit(device) : null,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: canEdit
                      ? 'Editar dispositivo'
                      : 'Solo admin o superadmin pueden editar',
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DevicesCompactList extends StatelessWidget {
  const _DevicesCompactList({
    required this.devices,
    required this.onEdit,
    required this.canEdit,
  });

  final List<Device> devices;
  final ValueChanged<Device> onEdit;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: Column(
        children: [
          for (final device in devices) ...[
            _DeviceCompactCard(
              device: device,
              onEdit: onEdit,
              canEdit: canEdit,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DeviceCompactCard extends StatelessWidget {
  const _DeviceCompactCard({
    required this.device,
    required this.onEdit,
    required this.canEdit,
  });

  final Device device;
  final ValueChanged<Device> onEdit;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = device.name.isNotEmpty
        ? device.name
        : device.externalId ?? 'Sin nombre';
    final externalId = device.externalId?.trim().isNotEmpty == true
        ? device.externalId!
        : 'Sin ID externo';
    final site = device.siteName?.trim().isNotEmpty == true
        ? device.siteName!
        : 'Sin sede';
    final district = device.district?.trim().isNotEmpty == true
        ? device.district!
        : 'Sin distrito';
    final unavailable = formatDurationSeconds(device.totalDowntimeSeconds);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (device.isOnline
                            ? StatusColors.online
                            : StatusColors.offline)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.electric_meter_outlined,
                    color: device.isOnline
                        ? StatusColors.online
                        : StatusColors.offline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: FiconColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        externalId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: FiconColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: canEdit ? () => onEdit(device) : null,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: canEdit
                      ? 'Editar dispositivo'
                      : 'Solo admin o superadmin pueden editar',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DeviceStatusChip(online: device.isOnline),
                _DeviceMiniChip(
                  icon: Icons.location_on_outlined,
                  label: site,
                ),
                _DeviceMiniChip(
                  icon: Icons.map_outlined,
                  label: district,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DeviceStatTile(
                    label: 'Último cambio',
                    value: formatDateTime(device.lastStatusChange),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DeviceStatTile(
                    label: 'Incidentes',
                    value: '${device.incidentCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DeviceStatTile(
              label: 'Indisponibilidad',
              value: unavailable,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceMiniChip extends StatelessWidget {
  const _DeviceMiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FiconColors.cyan.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FiconColors.cyan.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: FiconColors.logoBlue),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceStatTile extends StatelessWidget {
  const _DeviceStatTile({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: FiconColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FiconColors.cardBorderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FiconColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: fullWidth ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FiconColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return child;
  }
}

/// Diálogo para editar el nombre y la sede de un dispositivo.
/// Permite crear una sede nueva al vuelo. Devuelve `true` al
/// cerrarse si el guardado fue exitoso.
class _EditDeviceDialog extends StatefulWidget {
  const _EditDeviceDialog({
    required this.device,
    required this.getSites,
    required this.updateDeviceDetails,
    required this.createSite,
  });

  final Device device;
  final GetSites getSites;
  final UpdateDeviceDetails updateDeviceDetails;
  final CreateSite createSite;

  @override
  State<_EditDeviceDialog> createState() => _EditDeviceDialogState();
}

class _EditDeviceDialogState extends State<_EditDeviceDialog> {
  static const _newSiteValue = '__new__';

  late final TextEditingController _nameController;
  late final TextEditingController _siteNameController;
  late final TextEditingController _districtController;
  late final TextEditingController _provinceController;
  late Future<List<Site>> _sitesFuture;
  String? _selectedSiteId;
  bool _saving = false;

  bool get _isNewSite => _selectedSiteId == _newSiteValue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _siteNameController = TextEditingController();
    _districtController = TextEditingController();
    _provinceController = TextEditingController();
    _selectedSiteId = widget.device.siteId;
    _sitesFuture = widget.getSites();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _siteNameController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('El nombre no puede estar vacío.');
      return;
    }
    if (_selectedSiteId == null) {
      _showError('Selecciona una sede.');
      return;
    }
    if (_isNewSite && _siteNameController.text.trim().isEmpty) {
      _showError('Ingresa el nombre de la nueva sede.');
      return;
    }

    setState(() => _saving = true);
    try {
      var siteId = _selectedSiteId!;
      if (_isNewSite) {
        final site = await widget.createSite(
          name: _siteNameController.text.trim(),
          district: _districtController.text.trim(),
          province: _provinceController.text.trim(),
        );
        siteId = site.id;
      }
      await widget.updateDeviceDetails(
        widget.device.id,
        name: name,
        siteId: siteId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('No se pudo guardar: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar dispositivo'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<Site>>(
          future: _sitesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('No se pudieron cargar las sedes.');
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final sites = snapshot.data!;
            final knownIds = sites.map((s) => s.id).toSet();
            final selected = knownIds.contains(_selectedSiteId)
                ? _selectedSiteId
                : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _isNewSite ? _newSiteValue : selected,
                  decoration: const InputDecoration(
                    labelText: 'Sede',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final site in sites)
                      DropdownMenuItem(
                        value: site.id,
                        child: Text(
                          site.locationLabel.isNotEmpty
                              ? '${site.name} (${site.locationLabel})'
                              : site.name,
                        ),
                      ),
                    const DropdownMenuItem(
                      value: _newSiteValue,
                      child: Text('＋ Nueva sede…'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) =>
                          setState(() => _selectedSiteId = value),
                ),
                if (_isNewSite) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _siteNameController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la nueva sede',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _districtController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Distrito (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _provinceController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Provincia (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
