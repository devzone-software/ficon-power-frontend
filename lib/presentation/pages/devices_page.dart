import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/user_error_message.dart';
import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/site.dart';
import '../../domain/realtime_change.dart';
import '../../ports/input/create_site.dart';
import '../../ports/input/get_devices.dart';
import '../../ports/input/get_device_detail.dart';
import '../../ports/input/get_sites.dart';
import '../../ports/input/update_device_details.dart';
import '../devices/devices_compact_list.dart';
import '../devices/device_location_map.dart';
import '../devices/devices_table.dart';
import '../devices/onboarding/tuya_spatial_guide.dart';
import 'device_detail_page.dart';
import '../widgets/notification_focus_banner.dart';
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
    required this.getDeviceDetail,
    required this.getSites,
    required this.updateDeviceDetails,
    required this.createSite,
    required this.currentUser,
    required this.onLogout,
    this.focusDeviceId,
    this.realtimeChanges,
  });

  final GetDevices getDevices;
  final GetDeviceDetail getDeviceDetail;
  final GetSites getSites;
  final UpdateDeviceDetails updateDeviceDetails;
  final CreateSite createSite;
  final AuthUser currentUser;
  final VoidCallback onLogout;
  final String? focusDeviceId;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  static const _autoRefreshInterval = Duration(minutes: 3);

  late Future<List<Device>> _future;
  Timer? _autoRefreshTimer;
  Timer? _realtimeDebounce;
  StreamSubscription<RealtimeChange>? _realtimeSubscription;
  bool _refreshing = false;
  final ColumnFilterState _columnFilters = ColumnFilterState();
  late String? _focusDeviceId;
  DevicesViewMode _viewMode = DevicesViewMode.list;

  @override
  void initState() {
    super.initState();
    _focusDeviceId = widget.focusDeviceId;
    _future = widget.getDevices();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _refresh());
    _realtimeSubscription = widget.realtimeChanges
        ?.where(
          (change) => const {
            'device',
            'incident',
            'event',
            'site',
          }.contains(change.entityType),
        )
        .listen(_scheduleRealtimeRefresh);
  }

  void _scheduleRealtimeRefresh(RealtimeChange _) {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_refresh()),
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
    _realtimeDebounce?.cancel();
    unawaited(_realtimeSubscription?.cancel());
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

  void _openDetail(Device device) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceDetailPage(
          deviceId: device.id,
          initialDeviceName: device.name,
          getDeviceDetail: widget.getDeviceDetail,
          currentUser: widget.currentUser,
          onLogout: widget.onLogout,
          realtimeChanges: widget.realtimeChanges,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.devices,
      title: 'Dispositivos',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      realtimeChanges: widget.realtimeChanges,
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
            devices.where(
              (device) =>
                  (_focusDeviceId == null || device.id == _focusDeviceId) &&
                  _matchesFilters(device),
            ),
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _DevicesPageContent(
              devices: filteredDevices,
              focusBanner: _focusDeviceId == null
                  ? null
                  : NotificationFocusBanner(
                      label: 'Mostrando el dispositivo de la notificación',
                      onClear: _clearNotificationFocus,
                    ),
              filters: _filters(devices),
              canEdit: widget.currentUser.canEditDevices,
              onEdit: _edit,
              onOpen: _openDetail,
              onOpenGuide: _openTuyaSpatialGuide,
              viewMode: _viewMode,
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
            ),
          );
        },
      ),
    );
  }

  void _clearNotificationFocus() {
    setState(() => _focusDeviceId = null);
  }
}
