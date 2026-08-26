part of '../devices_page.dart';

class _EditDeviceDialog extends StatefulWidget {
  const _EditDeviceDialog({
    required this.device,
    required this.getSites,
    required this.updateDeviceDetails,
    required this.createSite,
  });

  final Device device;
  final GetSites getSites;
  final UpdateDeviceDetails updateDeviceDetails;
  final CreateSite createSite;

  @override
  State<_EditDeviceDialog> createState() => _EditDeviceDialogState();
}

class _EditDeviceDialogState extends State<_EditDeviceDialog> {
  static const _newSiteValue = '__new__';

  late final TextEditingController _nameController;
  late final TextEditingController _siteNameController;
  late final TextEditingController _districtController;
  late final TextEditingController _provinceController;
  late Future<List<Site>> _sitesFuture;
  String? _selectedSiteId;
  bool _saving = false;

  bool get _isNewSite => _selectedSiteId == _newSiteValue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _siteNameController = TextEditingController();
    _districtController = TextEditingController();
    _provinceController = TextEditingController();
    _selectedSiteId = widget.device.siteId;
    _sitesFuture = widget.getSites();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _siteNameController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('El nombre no puede estar vacío.');
      return;
    }
    if (_selectedSiteId == null) {
      _showError('Selecciona una sede.');
      return;
    }
    if (_isNewSite && _siteNameController.text.trim().isEmpty) {
      _showError('Ingresa el nombre de la nueva sede.');
      return;
    }

    setState(() => _saving = true);
    try {
      var siteId = _selectedSiteId!;
      if (_isNewSite) {
        final site = await widget.createSite(
          name: _siteNameController.text.trim(),
          district: _districtController.text.trim(),
          province: _provinceController.text.trim(),
        );
        siteId = site.id;
      }
      await widget.updateDeviceDetails(
        widget.device.id,
        name: name,
        siteId: siteId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('No se pudo guardar: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar dispositivo'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<Site>>(
          future: _sitesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('No se pudieron cargar las sedes.');
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final sites = snapshot.data!;
            final knownIds = sites.map((s) => s.id).toSet();
            final selected = knownIds.contains(_selectedSiteId)
                ? _selectedSiteId
                : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _isNewSite ? _newSiteValue : selected,
                  decoration: const InputDecoration(
                    labelText: 'Sede',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final site in sites)
                      DropdownMenuItem(
                        value: site.id,
                        child: Text(
                          site.locationLabel.isNotEmpty
                              ? '${site.name} (${site.locationLabel})'
                              : site.name,
                        ),
                      ),
                    const DropdownMenuItem(
                      value: _newSiteValue,
                      child: Text('＋ Nueva sede…'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _selectedSiteId = value),
                ),
                if (_isNewSite) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _siteNameController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la nueva sede',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _districtController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Distrito (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _provinceController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Provincia (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
