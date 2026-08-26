part of '../devices_page.dart';

extension _DevicesPageFilters on _DevicesPageState {
  List<Widget> _filters(List<Device> devices) {
    if (MediaQuery.sizeOf(context).width < 720) {
      return [
        TextColumnFilter(
          label: 'Buscar medidor',
          hint: 'Nombre, ID, sede o distrito',
          value: _columnFilters.text('query'),
          options: mergeFilterOptions([
            uniqueColumnOptions(devices, (device) => device.name),
            uniqueColumnOptions(devices, (device) => device.externalId),
            uniqueColumnOptions(devices, (device) => device.siteName),
            uniqueColumnOptions(devices, (device) => device.district),
          ]),
          wideOnMobile: true,
          onChanged: (value) => _setTextFilter('query', value),
        ),
        _statusFilter(),
        OptionsChipFilter(
          label: 'Sede',
          value: _columnFilters.text('site'),
          options: uniqueColumnOptions(devices, (device) => device.siteName),
          onChanged: (value) => _setTextFilter('site', value),
        ),
        OptionsChipFilter(
          label: 'Distrito',
          value: _columnFilters.text('district'),
          options: uniqueColumnOptions(devices, (device) => device.district),
          onChanged: (value) => _setTextFilter('district', value),
        ),
        DateColumnFilter(
          label: 'Último cambio',
          value: _columnFilters.date('lastStatusChange'),
          wideOnMobile: true,
          onChanged: (value) => _setDateFilter('lastStatusChange', value),
        ),
        SortColumnControl(
          label: 'Ordenar por incidentes',
          value: _columnFilters.sort('incidents'),
          onChanged: (value) => _setSortFilter('incidents', value),
        ),
      ];
    }
    return [
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
      _selectFilter(
        keyName: 'site',
        label: 'Sede',
        options: uniqueColumnOptions(devices, (device) => device.siteName),
      ),
      _selectFilter(
        keyName: 'district',
        label: 'Distrito',
        options: uniqueColumnOptions(devices, (device) => device.district),
      ),
      _statusFilter(),
      DateColumnFilter(
        label: 'Último cambio',
        value: _columnFilters.date('lastStatusChange'),
        onChanged: (value) => _setDateFilter('lastStatusChange', value),
      ),
      SortColumnControl(
        label: 'Ordenar por incidentes',
        value: _columnFilters.sort('incidents'),
        onChanged: (value) => _setSortFilter('incidents', value),
      ),
    ];
  }

  Widget _statusFilter() => ChoiceColumnFilter(
    label: 'Estado',
    value: _columnFilters.text('status'),
    options: const ['En línea', 'Fuera de línea'],
    labels: const {'En línea': 'Online', 'Fuera de línea': 'Offline'},
    onChanged: (value) => _setTextFilter('status', value),
  );

  Widget _textFilter({
    required String keyName,
    required String label,
    required List<String> options,
    double width = 220,
  }) {
    return TextColumnFilter(
      label: label,
      value: _columnFilters.text(keyName),
      options: options,
      width: width,
      onChanged: (value) => _setTextFilter(keyName, value),
    );
  }

  Widget _selectFilter({
    required String keyName,
    required String label,
    required List<String> options,
    double width = 220,
  }) {
    return SelectColumnFilter(
      label: label,
      value: _columnFilters.text(keyName),
      options: options,
      width: width,
      onChanged: (value) => _setTextFilter(keyName, value),
    );
  }

  bool _matchesFilters(Device device) {
    return _columnFilters.matchesAnyText('query', [
          device.name,
          device.externalId,
          device.siteName,
          device.district,
        ]) &&
        _columnFilters.matchesText(
          'name',
          device.name.isNotEmpty ? device.name : device.externalId,
        ) &&
        _columnFilters.matchesText('externalId', device.externalId) &&
        _columnFilters.matchesChoice('site', device.siteName) &&
        _columnFilters.matchesChoice('district', device.district) &&
        _columnFilters.matchesChoice(
          'status',
          device.isOnline ? 'En línea' : 'Fuera de línea',
        ) &&
        _columnFilters.matchesDate('lastStatusChange', device.lastStatusChange);
  }

  List<Device> _sortedDevices(Iterable<Device> devices) => _columnFilters
      .sortedNumeric('incidents', devices, (device) => device.incidentCount);
}
