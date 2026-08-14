import 'package:flutter/material.dart';

class AdminTableShell extends StatelessWidget {
  const AdminTableShell({
    super.key,
    required this.child,
    required this.onRefresh,
    this.action,
    this.filters = const [],
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? action;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Card(
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
