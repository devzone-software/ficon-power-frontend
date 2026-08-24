import 'package:flutter/material.dart';

class AdminTableShell extends StatelessWidget {
  const AdminTableShell({
    super.key,
    required this.child,
    required this.onRefresh,
    this.action,
    this.filters = const [],
    this.mobileChild,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? action;
  final List<Widget> filters;
  final Widget? mobileChild;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (action != null) ...[action!, const SizedBox(height: 8)],
                  if (filters.isNotEmpty)
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.filter_alt_outlined),
                        title: const Text('Filtros'),
                        subtitle: Text('${filters.length} disponibles'),
                        childrenPadding: const EdgeInsets.all(12),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: filters,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  mobileChild ??
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: child,
                      ),
                ],
              )
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (filters.isNotEmpty || action != null) ...[
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [...filters, ?action],
                        ),
                        const SizedBox(height: 12),
                      ],
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: child,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class AdminEllipsisText extends StatelessWidget {
  const AdminEllipsisText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
