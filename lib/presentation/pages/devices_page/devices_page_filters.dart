part of '../devices_page.dart';

extension _DevicesPageFilters on _DevicesPageState {
  List<Widget> _filters(List<Device> devices) {
    return [
      TextColumnFilter(
        label: 'Buscar medidor',
        hint: 'Nombre, ID o distrito',
        value: _columnFilters.text('query'),
        options: mergeFilterOptions([
          uniqueColumnOptions(devices, (device) => device.name),
          uniqueColumnOptions(devices, (device) => device.externalId),
          uniqueColumnOptions(devices, (device) => device.district),
        ]),
        wideOnMobile: true,
        onChanged: (value) => _setTextFilter('query', value),
      ),
      OptionsChipFilter(
        label: 'Distrito',
        value: _columnFilters.text('district'),
        options: uniqueColumnOptions(devices, (device) => device.district),
        onChanged: (value) => _setTextFilter('district', value),
      ),
      _statusFilter(),
    ];
  }

  Widget _statusFilter() => ChoiceColumnFilter(
    label: 'Estado',
    value: _columnFilters.text('status'),
    options: const ['En línea', 'Fuera de línea'],
    labels: const {'En línea': 'Online', 'Fuera de línea': 'Offline'},
    onChanged: (value) => _setTextFilter('status', value),
  );

  bool _matchesFilters(Device device) {
    return _columnFilters.matchesAnyText('query', [
          device.name,
          device.externalId,
          device.district,
        ]) &&
        _columnFilters.matchesChoice('district', device.district) &&
        _columnFilters.matchesChoice(
          'status',
          device.isOnline ? 'En línea' : 'Fuera de línea',
        );
  }
}
