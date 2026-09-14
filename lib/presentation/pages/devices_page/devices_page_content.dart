part of '../devices_page.dart';

class _DevicesPageContent extends StatelessWidget {
  const _DevicesPageContent({
    required this.devices,
    this.focusBanner,
    required this.filters,
    required this.canEdit,
    required this.onEdit,
    required this.onOpen,
    required this.onOpenGuide,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final List<Device> devices;
  final Widget? focusBanner;
  final List<Widget> filters;
  final bool canEdit;
  final void Function(Device device) onEdit;
  final void Function(Device device) onOpen;
  final VoidCallback onOpenGuide;
  final DevicesViewMode viewMode;
  final ValueChanged<DevicesViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ?focusBanner,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${devices.length} medidor${devices.length == 1 ? '' : 'es'}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenGuide,
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(compact ? 'Guía' : 'Cómo agregar un medidor'),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<DevicesViewMode>(
                      segments: compact
                          ? const [
                              ButtonSegment(
                                value: DevicesViewMode.list,
                                icon: Icon(Icons.view_list_outlined),
                                tooltip: 'Lista',
                              ),
                              ButtonSegment(
                                value: DevicesViewMode.map,
                                icon: Icon(Icons.map_outlined),
                                tooltip: 'Mapa de Puno',
                              ),
                            ]
                          : const [
                              ButtonSegment(
                                value: DevicesViewMode.list,
                                icon: Icon(Icons.view_list_outlined),
                                label: Text('Lista'),
                              ),
                              ButtonSegment(
                                value: DevicesViewMode.map,
                                icon: Icon(Icons.map_outlined),
                                label: Text('Mapa'),
                              ),
                            ],
                      selected: {viewMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          onViewModeChanged(selection.first),
                    ),
                  ],
                ),
              ),
              TableFiltersBar(filters: filters),
              if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text('No hay dispositivos con esos filtros.'),
                )
              else if (viewMode == DevicesViewMode.map)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: DeviceLocationMap(
                    devices: devices,
                    onOpenDevice: onOpen,
                  ),
                )
              else if (compact)
                DevicesCompactList(
                  devices: devices,
                  onEdit: onEdit,
                  onOpen: onOpen,
                  canEdit: canEdit,
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DevicesTable(
                      devices: devices,
                      onEdit: onEdit,
                      onOpen: onOpen,
                      canEdit: canEdit,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
