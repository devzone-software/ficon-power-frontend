import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/device.dart';
import '../theme/ficon_theme.dart';

enum DevicesViewMode { list, map }

class DeviceLocationMap extends StatefulWidget {
  const DeviceLocationMap({
    super.key,
    required this.devices,
    required this.onOpenDevice,
  });

  final List<Device> devices;
  final ValueChanged<Device> onOpenDevice;

  @override
  State<DeviceLocationMap> createState() => _DeviceLocationMapState();
}

class _DeviceLocationMapState extends State<DeviceLocationMap> {
  static const _punoCenter = LatLng(-15.25, -69.9);
  static final _punoBounds = LatLngBounds(
    const LatLng(-17.5, -71.5),
    const LatLng(-13.5, -68.5),
  );
  Device? _selectedDevice;

  @override
  Widget build(BuildContext context) {
    final punoDevices = widget.devices
        .where((device) => device.isInPuno)
        .toList();
    final locatedDevices = punoDevices.where((device) {
      final location = device.punoMapLocation;
      return location != null &&
          _punoBounds.contains(LatLng(location.latitude, location.longitude));
    }).toList();
    final missingLocation = punoDevices.length - locatedDevices.length;
    final outsidePuno = widget.devices.length - punoDevices.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MapSummary(
          visibleDevices: locatedDevices.length,
          missingLocation: missingLocation,
          outsidePuno: outsidePuno,
        ),
        const SizedBox(height: 10),
        if (locatedDevices.isEmpty)
          const _EmptyPunoMap()
        else
          SizedBox(
            height: MediaQuery.sizeOf(context).width < 760 ? 440 : 560,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: locatedDevices.length == 1
                          ? _pointFor(locatedDevices.first)
                          : _punoCenter,
                      initialZoom: 12,
                      initialCameraFit: locatedDevices.length > 1
                          ? CameraFit.coordinates(
                              coordinates: locatedDevices
                                  .map(_pointFor)
                                  .toList(growable: false),
                              padding: const EdgeInsets.all(56),
                              minZoom: 8,
                              maxZoom: 15,
                            )
                          : null,
                      minZoom: 8,
                      maxZoom: 18,
                      cameraConstraint: CameraConstraint.containCenter(
                        bounds: _punoBounds,
                      ),
                      onTap: (_, _) => setState(() => _selectedDevice = null),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.devzonesoft.ficon_power_frontend',
                      ),
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 55,
                          spiderfyCluster: true,
                          size: const Size(46, 46),
                          padding: const EdgeInsets.all(48),
                          maxZoom: 18,
                          markers: [
                            for (final device in locatedDevices)
                              Marker(
                                key: ValueKey(device.id),
                                point: _pointFor(device),
                                width: 48,
                                height: 48,
                                child: _DeviceMarker(
                                  device: device,
                                  selected: _selectedDevice?.id == device.id,
                                  onTap: () =>
                                      setState(() => _selectedDevice = device),
                                ),
                              ),
                          ],
                          builder: (context, markers) =>
                              _ClusterMarker(count: markers.length),
                        ),
                      ),
                      SimpleAttributionWidget(
                        source: const Text('OpenStreetMap contributors'),
                        onTap: () => unawaited(
                          launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Positioned(left: 12, bottom: 34, child: _MapLegend()),
                  if (_selectedDevice case final selected?)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: _SelectedDeviceCard(
                        device: selected,
                        onClose: () => setState(() => _selectedDevice = null),
                        onOpen: () => widget.onOpenDevice(selected),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  LatLng _pointFor(Device device) {
    final location = device.punoMapLocation!;
    return LatLng(location.latitude, location.longitude);
  }
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({
    required this.visibleDevices,
    required this.missingLocation,
    required this.outsidePuno,
  });

  final int visibleDevices;
  final int missingLocation;
  final int outsidePuno;

  @override
  Widget build(BuildContext context) {
    final hidden = <String>[
      if (missingLocation > 0) '$missingLocation sin ubicación válida',
      if (outsidePuno > 0) '$outsidePuno fuera de la región Puno',
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mapa de la región Puno · $visibleDevices dispositivo${visibleDevices == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    hidden.isEmpty
                        ? 'Todas las ubicaciones filtradas están visibles.'
                        : 'No se muestran: ${hidden.join(' · ')}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPunoMap extends StatelessWidget {
  const _EmptyPunoMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, size: 42),
            SizedBox(height: 12),
            Text(
              'No hay dispositivos de la región Puno con una ubicación reconocida.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceMarker extends StatelessWidget {
  const _DeviceMarker({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final Device device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(device);
    return Tooltip(
      message: device.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: FiconColors.surface,
              width: selected ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: FiconColors.ink.withValues(alpha: 0.26),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            device.hasActiveIncident
                ? Icons.warning_amber_rounded
                : Icons.electrical_services_rounded,
            color: FiconColors.surface,
            size: selected ? 25 : 22,
          ),
        ),
      ),
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: FiconColors.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: FiconColors.ink.withValues(alpha: 0.26),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: FiconColors.surface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SelectedDeviceCard extends StatelessWidget {
  const _SelectedDeviceCard({
    required this.device,
    required this.onClose,
    required this.onOpen,
  });

  final Device device;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _statusColor(device),
              foregroundColor: FiconColors.surface,
              child: const Icon(Icons.electrical_services_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${device.district ?? 'Puno'} · ${_statusLabel(device)} · ${device.incidentCount} incidentes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onOpen, child: const Text('Ver ficha')),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _LegendItem(color: FiconColors.success, label: 'En línea'),
            _LegendItem(color: FiconColors.warning, label: 'Sin conexión'),
            _LegendItem(color: FiconColors.danger, label: 'Incidente'),
            _LegendItem(color: FiconColors.slate, label: 'Inactivo'),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

Color _statusColor(Device device) {
  if (!device.active) return FiconColors.slate;
  if (device.hasActiveIncident) return FiconColors.danger;
  return device.isOnline ? FiconColors.success : FiconColors.warning;
}

String _statusLabel(Device device) {
  if (!device.active) return 'Inactivo';
  if (device.hasActiveIncident) return 'Incidente activo';
  return device.isOnline ? 'En línea' : 'Sin conexión';
}
