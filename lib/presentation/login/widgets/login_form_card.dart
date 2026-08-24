import 'package:flutter/material.dart';

import '../../theme/ficon_theme.dart';
import '../../widgets/common.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.loading,
    required this.showPassword,
    required this.error,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onSupport,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool loading;
  final bool showPassword;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: FiconColors.logoBlue.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: FiconBrandMark(height: 52)),
              const SizedBox(height: 24),
              Text(
                'Bienvenido',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ingresa para supervisar la continuidad eléctrica',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: FiconColors.deepAlt),
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: usernameController,
                enabled: !loading,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa el usuario.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: passwordController,
                enabled: !loading,
                obscureText: !showPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: showPassword
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    onPressed: loading ? null : onTogglePassword,
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingresa la contraseña.'
                    : null,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: StatusColors.offline.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(color: StatusColors.offline),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: loading ? null : onSubmit,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(loading ? 'Ingresando…' : 'Ingresar'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: loading ? null : onSupport,
                icon: const Icon(Icons.help_outline),
                label: const Text('¿Problemas para ingresar?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
