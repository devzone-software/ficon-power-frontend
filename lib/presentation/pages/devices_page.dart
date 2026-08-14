import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/site.dart';
import '../../ports/input/create_site.dart';
import '../../ports/input/get_devices.dart';
import '../../ports/input/get_sites.dart';
import '../../ports/input/update_device_details.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/table_filters.dart';

part '../devices/device_views.dart';
part '../devices/edit_device_dialog.dart';

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
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _refresh());
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dispositivo actualizado.')));
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
      onChanged: (value) =>
          setState(() => _dateFilters['lastStatusChange'] = value),
    ),
    _textFilter(
      keyName: 'incidents',
      label: 'Incidentes',
      options: uniqueColumnOptions(
        devices,
        (device) => '${device.incidentCount}',
      ),
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
        matchesTextFilter(
          device.externalId,
          _textFilters['externalId'] ?? '',
        ) &&
        matchesTextFilter(device.siteName, _textFilters['site'] ?? '') &&
        matchesTextFilter(device.district, _textFilters['district'] ?? '') &&
        matchesTextFilter(
          device.isOnline ? 'En línea' : 'Fuera de línea',
          _textFilters['status'] ?? '',
        ) &&
        matchesDateFilter(
          device.lastStatusChange,
          _dateFilters['lastStatusChange'],
        ) &&
        matchesTextFilter(
          '${device.incidentCount}',
          _textFilters['incidents'] ?? '',
        );
  }
}
