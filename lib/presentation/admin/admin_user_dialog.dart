part of '../pages/admin_page.dart';

class _UserDialog extends StatefulWidget {
  const _UserDialog({
    required this.repository,
    required this.currentUser,
    this.user,
  });

  final FiconMonitoringRepository repository;
  final AuthUser currentUser;
  final ManagedUser? user;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final TextEditingController _username;
  late final TextEditingController _displayName;
  late final TextEditingController _email;
  late final TextEditingController _whatsappPhone;
  late final TextEditingController _password;
  late String _role;
  late bool _active;
  late bool _whatsappEnabled;
  bool _saving = false;
  bool _showPassword = false;
  String? _error;

  bool get _isEdit => widget.user != null;
  bool get _editingSuperadmin => widget.user?.role == 'SUPERADMIN';
  bool get _canAssignAdmin => widget.currentUser.role == 'SUPERADMIN';
  bool get _canEditActive => !_editingSuperadmin;
  List<String> get _assignableRoles =>
      _canAssignAdmin ? const ['USER', 'ADMIN'] : const ['USER'];

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user?.username ?? '');
    _displayName = TextEditingController(text: widget.user?.displayName ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _whatsappPhone = TextEditingController(
      text: widget.user?.whatsappPhone == null
          ? ''
          : formatPeruMobilePhone(
              widget.user!.whatsappPhone!,
              includeCountryCode: false,
            ),
    )..addListener(_phoneChanged);
    _password = TextEditingController();
    final initialRole = widget.user?.role ?? 'USER';
    _role = _assignableRoles.contains(initialRole)
        ? initialRole
        : _assignableRoles.first;
    _active = widget.user?.active ?? true;
    _whatsappEnabled = widget.user?.whatsappEnabled ?? false;
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _email.dispose();
    _whatsappPhone
      ..removeListener(_phoneChanged)
      ..dispose();
    _password.dispose();
    super.dispose();
  }

  void _phoneChanged() {
    if (normalizePeruMobilePhone(_whatsappPhone.text) == null &&
        _whatsappEnabled) {
      setState(() => _whatsappEnabled = false);
    }
  }

  Future<void> _save() async {
    if (_whatsappPhone.text.trim().isNotEmpty &&
        normalizePeruMobilePhone(_whatsappPhone.text) == null) {
      setState(() {
        _error = 'Ingresa un celular peruano válido de 9 dígitos.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final roleToSave = _editingSuperadmin ? widget.user!.role : _role;
      if (_isEdit) {
        await widget.repository.updateUser(
          widget.user!.id,
          role: roleToSave,
          displayName: _displayName.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          whatsappPhone: normalizePeruMobilePhone(_whatsappPhone.text),
          whatsappEnabled: _whatsappEnabled,
          active: _active,
          password: _password.text.trim(),
        );
      } else {
        await widget.repository.createUser(
          username: _username.text.trim(),
          password: _password.text.trim(),
          role: _role,
          displayName: _displayName.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          whatsappPhone: normalizePeruMobilePhone(_whatsappPhone.text),
          whatsappEnabled: _whatsappEnabled,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = UserErrorMessage.from(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar usuario' : 'Crear usuario'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _username,
                enabled: !_isEdit && !_saving,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayName,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Nombre visible'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_saving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo opcional',
                  hintText: 'usuario@ejemplo.com',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _whatsappPhone,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular WhatsApp opcional',
                  hintText: '987 654 321',
                  prefixText: '+51 ',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recibir alertas por WhatsApp'),
                subtitle: const Text(
                  'Recibirá avisos de cortes y restablecimientos.',
                ),
                value: _whatsappEnabled,
                onChanged:
                    _saving ||
                        normalizePeruMobilePhone(_whatsappPhone.text) == null
                    ? null
                    : (value) => setState(() => _whatsappEnabled = value),
              ),
              const SizedBox(height: 12),
              if (_editingSuperadmin)
                TextFormField(
                  initialValue: 'SUPERADMIN',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    helperText:
                        'Los superadmins no se reasignan desde el dashboard.',
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    helperText:
                        'SUPERADMIN no es un rol asignable desde esta pantalla.',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'USER',
                      child: Text('USER · sólo lectura'),
                    ),
                    if (_canAssignAdmin)
                      const DropdownMenuItem(
                        value: 'ADMIN',
                        child: Text('ADMIN · edición'),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                          () => _role = value ?? _assignableRoles.first,
                        ),
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acceso activo'),
                subtitle: Text(
                  _editingSuperadmin
                      ? 'El acceso superadmin no se revoca desde esta pantalla.'
                      : 'Apágalo para revocar el acceso del usuario.',
                ),
                value: _active,
                onChanged: _saving || !_canEditActive
                    ? null
                    : (value) => setState(() => _active = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_saving,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: _isEdit
                      ? 'Nueva contraseña opcional'
                      : 'Contraseña',
                  suffixIcon: IconButton(
                    tooltip: _showPassword
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    onPressed: _saving
                        ? null
                        : () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: StatusColors.offline)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
