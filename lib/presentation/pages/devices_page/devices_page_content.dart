part of '../devices_page.dart';

class _DevicesPageContent extends StatelessWidget {
  const _DevicesPageContent({
    required this.devices,
    required this.filters,
    required this.canEdit,
    required this.onEdit,
    required this.onOpenGuide,
  });

  final List<Device> devices;
  final List<Widget> filters;
  final bool canEdit;
  final void Function(Device device) onEdit;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onOpenGuide,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Cómo agregar un medidor'),
                  ),
                ),
              ),
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
