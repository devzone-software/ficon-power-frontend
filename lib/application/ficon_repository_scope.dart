import 'package:flutter/widgets.dart';

import '../adapters/http/ficon_monitoring_repository.dart';

class FiconRepositoryScope extends InheritedWidget {
  const FiconRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final FiconMonitoringRepository repository;

  static FiconMonitoringRepository of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FiconRepositoryScope>();
    assert(scope != null, 'FiconRepositoryScope no disponible');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(FiconRepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
