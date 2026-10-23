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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(
    FiconPowerApp(
      repository: repository,
      session: session,
      navigatorKey: LocalConsole.navigatorKey,
    ),
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
