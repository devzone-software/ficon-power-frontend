import 'package:flutter/material.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'application/ficon_app_router.dart';
import 'application/ficon_dependencies.dart';
import 'application/ficon_repository_scope.dart';
import 'config/auth_session.dart';
import 'presentation/theme/ficon_theme.dart';

void main() {
  final session = AuthSession();
  final repository = FiconMonitoringRepository(session: session);
  runApp(FiconPowerApp(repository: repository, session: session));
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

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
    _router = FiconAppRouter(
      repository: widget.repository,
      session: widget.session,
      dependencies: FiconDependencies(widget.repository),
      navigatorKey: _navigatorKey,
    );
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
