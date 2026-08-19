part of '../devices_page.dart';

extension _DevicesPageFilters on _DevicesPageState {
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
      value: _columnFilters.date('lastStatusChange'),
      onChanged: (value) => _setDateFilter('lastStatusChange', value),
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
      value: _columnFilters.text(keyName),
      options: options,
      width: width,
      onChanged: (value) => _setTextFilter(keyName, value),
    );
  }

  bool _matchesFilters(Device device) {
    return _columnFilters.matchesText(
          'name',
          device.name.isNotEmpty ? device.name : device.externalId,
        ) &&
        _columnFilters.matchesText('externalId', device.externalId) &&
        _columnFilters.matchesText('site', device.siteName) &&
        _columnFilters.matchesText('district', device.district) &&
        _columnFilters.matchesText(
          'status',
          device.isOnline ? 'En línea' : 'Fuera de línea',
        ) &&
        _columnFilters.matchesDate(
          'lastStatusChange',
          device.lastStatusChange,
        ) &&
        _columnFilters.matchesText('incidents', '${device.incidentCount}');
  }
}
