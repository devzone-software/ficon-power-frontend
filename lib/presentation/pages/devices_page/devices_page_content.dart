part of '../devices_page.dart';

class _DevicesPageContent extends StatelessWidget {
  const _DevicesPageContent({
    required this.devices,
    required this.filters,
    required this.canEdit,
    required this.onEdit,
  });

  final List<Device> devices;
  final List<Widget> filters;
  final bool canEdit;
  final void Function(Device device) onEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              TableFiltersBar(filters: filters),
              if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text('No hay dispositivos con esos filtros.'),
                )
              else if (compact)
                DevicesCompactList(
                  devices: devices,
                  onEdit: onEdit,
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
