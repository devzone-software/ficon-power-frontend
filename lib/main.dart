// DCALJ
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'offline/local_engine.dart';
import 'offline/local_console.dart';
import 'offline/local_alerts.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'application/ficon_app_router.dart';
import 'application/ficon_dependencies.dart';
import 'application/ficon_repository_scope.dart';
import 'config/auth_session.dart';
import 'presentation/theme/ficon_theme.dart';
import 'presentation/navigation/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalStartup());
}

Future<Widget> _initializeLocalApp() async {
  final directory = await getApplicationSupportDirectory();
  final engine = await LocalEngine.open(directory.path);
  final session = AuthSession();
  final repository = FiconMonitoringRepository(
    session: session,
    client: LocalClient(engine),
    baseUrl: 'http://local.ficon',
  );
  LocalConsole.engine = engine;
  LocalConsole.session = session;
  session.addListener(LocalConsole.flushNotification);
  final alerts = LocalAlerts(engine, session, LocalConsole.openNotification);
  // OS notifications are optional; the application must open even if denied.
  unawaited(alerts.start());
  return FiconPowerApp(
    repository: repository,
    session: session,
    navigatorKey: LocalConsole.navigatorKey,
  );
}

/// Render immediately, before accessing native plugins or the persistent store.
/// Initialization failures are recoverable and never erase the user's data.
class LocalStartup extends StatefulWidget {
  const LocalStartup({super.key, this.initialize});
  final Future<Widget> Function()? initialize;

  @override
  State<LocalStartup> createState() => _LocalStartupState();
}

class _LocalStartupState extends State<LocalStartup> {
  late Future<Widget> _application;

  @override
  void initState() {
    super.initState();
    _application = _initialize();
  }

  Future<Widget> _initialize() async {
    try {
      return await (widget.initialize ?? _initializeLocalApp)();
    } catch (error, stack) {
      debugPrint('FICON local startup failed: $error\n$stack');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _application,
    builder: (context, snapshot) {
      if (snapshot.hasData) return snapshot.data!;
      return MaterialApp(
        title: 'FICON Power',
        debugShowCheckedModeBanner: false,
        theme: buildFiconTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FiconBrandMark(height: 44),
                    const SizedBox(height: 24),
                    if (!snapshot.hasError) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Abriendo FICON Power…'),
                    ] else ...[
                      const Text(
                        'No se pudo iniciar FICON Power.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No se borraron tus datos. Reintenta o instala la versión actualizada.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _application = _initialize();
                        }),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class FiconPowerApp extends StatefulWidget {
  const FiconPowerApp({
    super.key,
    required this.repository,
    required this.session,
    this.navigatorKey,
    this.title = 'FICON Power',
    this.showBetaBanner = false,
  });

  final FiconMonitoringRepository repository;
  final AuthSession session;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String title;
  final bool showBetaBanner;

  @override
  State<FiconPowerApp> createState() => _FiconPowerAppState();
}

class _FiconPowerAppState extends State<FiconPowerApp> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final FiconAppRouter _router;
  late bool _wasAuthenticated;

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
    _wasAuthenticated = widget.session.isAuthenticated;
    widget.session.addListener(_handleSessionChange);
    _router = FiconAppRouter(
      repository: widget.repository,
      session: widget.session,
      dependencies: FiconDependencies(widget.repository),
      navigatorKey: _navigatorKey,
    );
  }

  void _handleSessionChange() {
    final authenticated = widget.session.isAuthenticated;
    if (_wasAuthenticated && !authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      });
    }
    _wasAuthenticated = authenticated;
  }

  @override
  void dispose() {
    widget.session.removeListener(_handleSessionChange);
    _router.dependencies.realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: widget.title,
        debugShowCheckedModeBanner: false,
        theme: buildFiconTheme(),
        themeMode: ThemeMode.light,
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          return FiconRepositoryScope(
            repository: widget.repository,
            child: !widget.showBetaBanner
                ? content
                : Banner(
                    message: 'BETA',
                    location: BannerLocation.topEnd,
                    color: FiconColors.cyan,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    child: content,
                  ),
          );
        },
        initialRoute: _router.initialRoute,
        routes: _router.routes,
        onUnknownRoute: _router.unknownRoute,
      ),
    );
  }
}
