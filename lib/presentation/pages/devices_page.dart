import 'package:flutter/material.dart';

import '../../domain/device.dart';
import '../../domain/site.dart';
import '../../ports/input/create_site.dart';
import '../../ports/input/get_devices.dart';
import '../../ports/input/get_sites.dart';
import '../../ports/input/update_device_details.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

/// Tabla de dispositivos monitoreados (vista de la tabla `devices`).
/// Permite editar el nombre y la sede de cada dispositivo.
class DevicesPage extends StatefulWidget {
  const DevicesPage({
    super.key,
    required this.getDevices,
    required this.getSites,
    required this.updateDeviceDetails,
    required this.createSite,
  });

  final GetDevices getDevices;
  final GetSites getSites;
  final UpdateDeviceDetails updateDeviceDetails;
  final CreateSite createSite;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late Future<List<Device>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getDevices();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.getDevices());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    }
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
          if (devices.isEmpty) {
            return const Center(
              child: Text('No hay dispositivos registrados.'),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: _DevicesTable(devices: devices, onEdit: _edit),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DevicesTable extends StatelessWidget {
  const _DevicesTable({required this.devices, required this.onEdit});

  final List<Device> devices;
  final ValueChanged<Device> onEdit;

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
                  onPressed: () => onEdit(device),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar dispositivo',
                ),
              ),
            ],
          ),
      ],
    );
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
