import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../config/auth_session.dart';
import '../login/widgets/login_form_card.dart';
import '../login/widgets/login_support_dialog.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.repository, required this.session});

  final FiconMonitoringRepository repository;
  final AuthSession session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      widget.session.start(
        token: result.token,
        refreshToken: result.refreshToken,
        expiresAt: result.expiresAt,
        refreshExpiresAt: result.refreshExpiresAt,
        user: result.user,
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.statusCode) {
            401 => 'Usuario o contraseña incorrectos.',
            403 => e.message,
            429 => 'Demasiados intentos fallidos. Espera unos minutos.',
            _ => 'No se pudo iniciar sesión: $e',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo iniciar sesión: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FiconColors.logoBlue.withValues(alpha: 0.09),
              FiconColors.cyan.withValues(alpha: 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: LoginFormCard(
                  formKey: _formKey,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  loading: _loading,
                  showPassword: _showPassword,
                  error: _error,
                  onTogglePassword: () =>
                      setState(() => _showPassword = !_showPassword),
                  onSubmit: _login,
                  onSupport: () => showLoginSupportDialog(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
