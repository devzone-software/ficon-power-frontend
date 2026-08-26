import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/site.dart';
import '../../ports/input/create_site.dart';
import '../../ports/input/get_devices.dart';
import '../../ports/input/get_sites.dart';
import '../../ports/input/update_device_details.dart';
import '../devices/devices_compact_list.dart';
import '../devices/devices_table.dart';
import '../devices/onboarding/tuya_spatial_guide.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/table_filters.dart';

part 'devices_page/devices_page_content.dart';
part 'devices_page/devices_page_filters.dart';
part 'devices_page/edit_device_dialog.dart';

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
  final ColumnFilterState _columnFilters = ColumnFilterState();

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

  void _setTextFilter(String keyName, String value) {
    setState(() => _columnFilters.setText(keyName, value));
  }

  void _setDateFilter(String keyName, DateTime? value) {
    setState(() => _columnFilters.setDate(keyName, value));
  }

  void _setSortFilter(String keyName, ColumnSortDirection? value) {
    setState(() => _columnFilters.setSort(keyName, value));
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

  void _openTuyaSpatialGuide() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TuyaSpatialGuidePage()),
    );
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
          final filteredDevices = _sortedDevices(
            devices.where(_matchesFilters),
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _DevicesPageContent(
              devices: filteredDevices,
              filters: _filters(devices),
              canEdit: widget.currentUser.canEditDevices,
              onEdit: _edit,
              onOpenGuide: _openTuyaSpatialGuide,
            ),
          );
        },
      ),
    );
  }
}
