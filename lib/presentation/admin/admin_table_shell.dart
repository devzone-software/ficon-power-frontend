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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          Icons.tune_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text(
                          'Filtrar y ordenar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          10,
                          0,
                          10,
                          10,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
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
