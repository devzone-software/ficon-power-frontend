import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/user_error_message.dart';
import '../../domain/auth_user.dart';
import '../../domain/operations_calendar.dart';
import '../../domain/realtime_change.dart';
import '../../ports/input/get_device_detail.dart';
import '../../ports/input/get_operations_calendar.dart';
import '../../ports/input/manage_tuya_plans.dart';
import '../dashboard/dashboard_formatters.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';
import 'device_detail_page.dart';

class OperationsCalendarPage extends StatefulWidget {
  const OperationsCalendarPage({
    super.key,
    required this.getCalendar,
    required this.managePlans,
    required this.getDeviceDetail,
    required this.currentUser,
    required this.onLogout,
    this.realtimeChanges,
  });

  final GetOperationsCalendar getCalendar;
  final ManageTuyaPlans managePlans;
  final GetDeviceDetail getDeviceDetail;
  final AuthUser currentUser;
  final VoidCallback onLogout;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  State<OperationsCalendarPage> createState() => _OperationsCalendarPageState();
}

class _OperationsCalendarPageState extends State<OperationsCalendarPage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;
  late Future<OperationsCalendarData> _future;
  StreamSubscription<RealtimeChange>? _realtimeSubscription;
  Timer? _realtimeDebounce;
  bool get _canManage => widget.currentUser.canAccessAdmin;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _selectedDay = today;
    _focusedMonth = DateTime(today.year, today.month);
    _future = _fetch();
    _realtimeSubscription = widget.realtimeChanges
        ?.where(
          (change) =>
              const {'incident', 'calendar'}.contains(change.entityType),
        )
        .listen((_) {
          _realtimeDebounce?.cancel();
          _realtimeDebounce = Timer(
            const Duration(milliseconds: 350),
            () => unawaited(_refresh()),
          );
        });
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    super.dispose();
  }

  (DateTime, DateTime) get _visibleRange {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    return (
      first.subtract(Duration(days: first.weekday - DateTime.monday)),
      last.add(Duration(days: DateTime.sunday - last.weekday)),
    );
  }

  Future<OperationsCalendarData> _fetch() {
    final (from, to) = _visibleRange;
    return widget.getCalendar(from: from, to: to);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _future = _fetch());
    try {
      await _future;
    } catch (_) {
      // FutureBuilder presenta el error y permite reintentar.
    }
  }

  void _changeMonth(int offset) {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + offset);
    setState(() {
      _focusedMonth = next;
      _selectedDay = DateTime(next.year, next.month, 1);
      _future = _fetch();
    });
  }

  void _goToday() {
    final today = dateOnly(DateTime.now());
    setState(() {
      _focusedMonth = DateTime(today.year, today.month);
      _selectedDay = today;
      _future = _fetch();
    });
  }

  Future<void> _openPlanDialog(TuyaPlan plan) async {
    final request = await showDialog<_TuyaPlanFormValue>(
      context: context,
      builder: (_) => _TuyaPlanDialog(plan: plan),
    );
    if (request == null) return;
    try {
      await widget.managePlans.save(
        id: plan.id,
        projectName: request.projectName,
        planName: request.planName,
        lastRenewedOn: request.lastRenewedOn,
        nextRenewalOn: request.nextRenewalOn,
        renewalIntervalMonths: request.intervalMonths,
        reminderDays: request.reminderDays,
        notes: request.notes,
        active: request.active,
      );
      if (!mounted) return;
      _showMessage('Plan Tuya actualizado.');
      await _refresh();
    } catch (error) {
      if (mounted) _showActionError('No se pudo guardar el plan', error);
    }
  }

  Future<void> _renewPlan(TuyaPlan plan) async {
    final value = await showDialog<_RenewalFormValue>(
      context: context,
      builder: (_) => _RenewPlanDialog(plan: plan),
    );
    if (value == null) return;
    try {
      final renewed = await widget.managePlans.renew(
        plan.id,
        renewedOn: value.renewedOn,
        notes: value.notes,
      );
      if (!mounted) return;
      _showMessage(
        'Renovación registrada. Próxima fecha: ${formatCalendarDate(renewed.nextRenewalOn)}.',
      );
      await _refresh();
    } catch (error) {
      if (mounted) {
        _showActionError('No se pudo registrar la renovación', error);
      }
    }
  }

  Future<void> _deletePlan(TuyaPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar seguimiento'),
        content: Text(
          'Se eliminará “${plan.projectName}” y su historial de renovaciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.managePlans.delete(plan.id);
      if (!mounted) return;
      _showMessage('Seguimiento de Tuya eliminado.');
      await _refresh();
    } catch (error) {
      if (mounted) _showActionError('No se pudo eliminar el plan', error);
    }
  }

  void _openEntry(OperationsCalendarEntry entry) {
    if (!entry.isIncident || entry.deviceId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceDetailPage(
          deviceId: entry.deviceId!,
          initialDeviceName: entry.deviceName ?? 'Dispositivo',
          getDeviceDetail: widget.getDeviceDetail,
          currentUser: widget.currentUser,
          onLogout: widget.onLogout,
          realtimeChanges: widget.realtimeChanges,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showActionError(String action, Object error) {
    _showMessage(UserErrorMessage.forAction(action, error));
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.calendar,
      title: 'Calendario operativo',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      realtimeChanges: widget.realtimeChanges,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<OperationsCalendarData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  ErrorView(error: snapshot.error, onRetry: _refresh),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final entries = data.entries;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _CalendarHeader(
                  month: _focusedMonth,
                  data: data,
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                  onToday: _goToday,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final calendar = _MonthCalendar(
                      month: _focusedMonth,
                      selectedDay: _selectedDay,
                      entries: entries,
                      onSelect: (day) => setState(() => _selectedDay = day),
                    );
                    final agenda = _DayAgenda(
                      day: _selectedDay,
                      entries: entries
                          .where((entry) => entry.occursOn(_selectedDay))
                          .toList(),
                      plans: data.plans,
                      canManage: _canManage,
                      onOpenEntry: _openEntry,
                      onEditPlan: _openPlanDialog,
                      onRenewPlan: _renewPlan,
                    );
                    if (constraints.maxWidth >= 980) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: calendar),
                          const SizedBox(width: 16),
                          Expanded(child: agenda),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [calendar, const SizedBox(height: 16), agenda],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _TuyaPlansCard(
                  plans: data.plans,
                  canManage: _canManage,
                  onEdit: _openPlanDialog,
                  onRenew: _renewPlan,
                  onDelete: _deletePlan,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.data,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final OperationsCalendarData data;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final activePlans = data.plans.where((plan) => plan.active).toList();
    final overdue = activePlans
        .where((plan) => plan.daysUntilRenewal(now) < 0)
        .length;
    final dueSoon = activePlans
        .where((plan) => plan.status(now) == 'DUE_SOON')
        .length;
    final incidents = data.entries
        .where(
          (entry) =>
              entry.isIncident &&
              entry.date.year == month.year &&
              entry.date.month == month.month,
        )
        .length;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: compact ? constraints.maxWidth : 360,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Mes anterior',
                            onPressed: onPrevious,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text(
                              formatCalendarMonth(month),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  (compact
                                          ? Theme.of(
                                              context,
                                            ).textTheme.titleMedium
                                          : Theme.of(
                                              context,
                                            ).textTheme.titleLarge)
                                      ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Mes siguiente',
                            onPressed: onNext,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: onToday,
                      child: const Text('Hoy'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.bolt, size: 18),
                  label: Text('$incidents incidentes'),
                ),
                Chip(
                  avatar: const Icon(Icons.autorenew, size: 18),
                  label: Text('${activePlans.length} planes Tuya'),
                ),
                _SummaryChip(
                  color: FiconColors.danger,
                  label: '$overdue vencidos',
                ),
                _SummaryChip(
                  color: FiconColors.warning,
                  label: '$dueSoon próximos',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
    label: Text(label),
  );
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.selectedDay,
    required this.entries,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selectedDay;
  final List<OperationsCalendarEntry> entries;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final days = calendarGridDays(month);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                for (final label in [
                  'Lun',
                  'Mar',
                  'Mié',
                  'Jue',
                  'Vie',
                  'Sáb',
                  'Dom',
                ])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final cellHeight = compact ? 66.0 : 86.0;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: (constraints.maxWidth / 7) / cellHeight,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final dayEntries = entries
                        .where((entry) => entry.occursOn(day))
                        .toList();
                    return _CalendarDay(
                      day: day,
                      inMonth: day.month == month.month,
                      selected: sameDate(day, selectedDay),
                      entries: dayEntries,
                      onTap: () => onSelect(day),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.entries,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final List<OperationsCalendarEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = sameDate(day, DateTime.now());
    final incidentCount = entries.where((entry) => entry.isIncident).length;
    final renewalCount = entries.where((entry) => entry.isRenewal).length;
    final completedCount = entries
        .where((entry) => entry.isCompletedRenewal)
        .length;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : FiconColors.surface.withValues(alpha: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: today
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: today ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontWeight: selected || today
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: inMonth
                        ? null
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: [
                    if (incidentCount > 0)
                      _CalendarBadge(
                        color: FiconColors.danger,
                        count: incidentCount,
                      ),
                    if (renewalCount > 0)
                      _CalendarBadge(
                        color: FiconColors.warning,
                        count: renewalCount,
                      ),
                    if (completedCount > 0)
                      _CalendarBadge(
                        color: FiconColors.success,
                        count: completedCount,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge({required this.color, required this.count});

  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
    padding: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: Text(
      '$count',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 9,
      ),
    ),
  );
}

class _DayAgenda extends StatelessWidget {
  const _DayAgenda({
    required this.day,
    required this.entries,
    required this.plans,
    required this.canManage,
    required this.onOpenEntry,
    required this.onEditPlan,
    required this.onRenewPlan,
  });

  final DateTime day;
  final List<OperationsCalendarEntry> entries;
  final List<TuyaPlan> plans;
  final bool canManage;
  final ValueChanged<OperationsCalendarEntry> onOpenEntry;
  final ValueChanged<TuyaPlan> onEditPlan;
  final ValueChanged<TuyaPlan> onRenewPlan;

  @override
  Widget build(BuildContext context) {
    TuyaPlan? findPlan(int? id) {
      if (id == null) return null;
      for (final plan in plans) {
        if (plan.id == id) return plan;
      }
      return null;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              formatCalendarLongDate(day),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(Icons.event_available_outlined, size: 36),
                    SizedBox(height: 8),
                    Text('No hay actividad para este día.'),
                  ],
                ),
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AgendaEntryCard(
                    entry: entry,
                    plan: findPlan(entry.tuyaPlanId),
                    canManage: canManage,
                    onOpen: () => onOpenEntry(entry),
                    onEditPlan: onEditPlan,
                    onRenewPlan: onRenewPlan,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _AgendaEntryCard extends StatelessWidget {
  const _AgendaEntryCard({
    required this.entry,
    required this.plan,
    required this.canManage,
    required this.onOpen,
    required this.onEditPlan,
    required this.onRenewPlan,
  });

  final OperationsCalendarEntry entry;
  final TuyaPlan? plan;
  final bool canManage;
  final VoidCallback onOpen;
  final ValueChanged<TuyaPlan> onEditPlan;
  final ValueChanged<TuyaPlan> onRenewPlan;

  @override
  Widget build(BuildContext context) {
    final color = calendarEntryColor(entry);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: entry.isIncident ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(calendarEntryIcon(entry), color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (entry.isIncident) const Icon(Icons.chevron_right),
                ],
              ),
              if (entry.isIncident && entry.startAt != null) ...[
                const SizedBox(height: 5),
                Text(
                  '${formatCalendarTime(entry.startAt!)} · ${entry.siteName ?? 'Sin sede'}'
                  '${entry.endAt == null ? ' · En curso' : ' · ${formatDashboardDuration(entry.endAt!.difference(entry.startAt!).inSeconds)}'}',
                ),
              ],
              if (entry.description?.isNotEmpty == true) ...[
                const SizedBox(height: 5),
                Text(entry.description!),
              ],
              if (canManage && entry.isRenewal && plan != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => onEditPlan(plan!),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => onRenewPlan(plan!),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Registrar renovación'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TuyaPlansCard extends StatelessWidget {
  const _TuyaPlansCard({
    required this.plans,
    required this.canManage,
    required this.onEdit,
    required this.onRenew,
    required this.onDelete,
  });

  final List<TuyaPlan> plans;
  final bool canManage;
  final ValueChanged<TuyaPlan> onEdit;
  final ValueChanged<TuyaPlan> onRenew;
  final ValueChanged<TuyaPlan> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Renovaciones de Tuya IoT',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plans.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Todavía no se registró ningún plan o proyecto Tuya.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final plan in plans)
                _TuyaPlanTile(
                  plan: plan,
                  canManage: canManage,
                  onEdit: () => onEdit(plan),
                  onRenew: () => onRenew(plan),
                  onDelete: () => onDelete(plan),
                ),
          ],
        ),
      ),
    );
  }
}

class _TuyaPlanTile extends StatelessWidget {
  const _TuyaPlanTile({
    required this.plan,
    required this.canManage,
    required this.onEdit,
    required this.onRenew,
    required this.onDelete,
  });

  final TuyaPlan plan;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onRenew;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final days = plan.daysUntilRenewal();
    final status = plan.status();
    final color = switch (status) {
      'OVERDUE' => FiconColors.danger,
      'DUE_SOON' => FiconColors.warning,
      'INACTIVE' => FiconColors.cardBorder,
      _ => FiconColors.success,
    };
    final countdown = switch (days) {
      < 0 => 'Vencido hace ${-days} día${days == -1 ? '' : 's'}',
      0 => 'Vence hoy',
      1 => 'Vence mañana',
      _ => 'Faltan $days días',
    };
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        foregroundColor: color,
        child: const Icon(Icons.autorenew),
      ),
      title: Text(
        plan.projectName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${plan.planName} · ${formatCalendarDate(plan.nextRenewalOn)} · $countdown',
      ),
      trailing: canManage
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'renew') onRenew();
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'renew',
                  child: Text('Registrar renovación'),
                ),
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            )
          : null,
    );
  }
}

class _TuyaPlanDialog extends StatefulWidget {
  const _TuyaPlanDialog({required this.plan});

  final TuyaPlan plan;

  @override
  State<_TuyaPlanDialog> createState() => _TuyaPlanDialogState();
}

class _TuyaPlanDialogState extends State<_TuyaPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _project;
  late final TextEditingController _plan;
  late final TextEditingController _reminder;
  late final TextEditingController _notes;
  late DateTime _nextRenewal;
  DateTime? _lastRenewed;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final source = widget.plan;
    _project = TextEditingController(text: source.projectName);
    _plan = TextEditingController(text: source.planName);
    _reminder = TextEditingController(text: '${source.reminderDays}');
    _notes = TextEditingController(text: source.notes ?? '');
    _nextRenewal = source.nextRenewalOn;
    _lastRenewed = source.lastRenewedOn;
    _active = source.active;
  }

  @override
  void dispose() {
    _project.dispose();
    _plan.dispose();
    _reminder.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final reminder = int.parse(_reminder.text);
    if (_lastRenewed != null && _nextRenewal.isBefore(_lastRenewed!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La próxima fecha debe ser posterior a la última renovación.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _TuyaPlanFormValue(
        projectName: _project.text.trim(),
        planName: _plan.text.trim(),
        lastRenewedOn: _lastRenewed,
        nextRenewalOn: _nextRenewal,
        intervalMonths: 6,
        reminderDays: reminder,
        notes: _notes.text.trim(),
        active: _active,
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;

  String? _numberInRange(String? value, int min, int max) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < min || number > max) {
      return 'Ingresa un valor entre $min y $max';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar plan Tuya'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _project,
                  maxLength: 120,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del proyecto Tuya',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _plan,
                  maxLength: 120,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Plan o servicio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Próxima renovación (Tuya)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(formatCalendarDate(_nextRenewal)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Última renovación (Tuya)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _lastRenewed == null
                              ? 'Sin registrar'
                              : formatCalendarDate(_lastRenewed!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: const InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ciclo fijo de Tuya',
                          border: OutlineInputBorder(),
                        ),
                        child: Text('6 meses'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _reminder,
                        keyboardType: TextInputType.number,
                        validator: (value) => _numberInRange(value, 0, 365),
                        decoration: const InputDecoration(
                          labelText: 'Avisar antes (días)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Seguimiento activo'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}

class _RenewPlanDialog extends StatefulWidget {
  const _RenewPlanDialog({required this.plan});

  final TuyaPlan plan;

  @override
  State<_RenewPlanDialog> createState() => _RenewPlanDialogState();
}

class _RenewPlanDialogState extends State<_RenewPlanDialog> {
  late DateTime _renewedOn;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _renewedOn = dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _renewedOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (value != null) setState(() => _renewedOn = value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar renovación'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${widget.plan.projectName} · ${widget.plan.planName}'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_available),
            label: Text('Renovado el ${formatCalendarDate(_renewedOn)}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notas o referencia (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          Text(
            'La siguiente fecha se calculará con un ciclo de ${widget.plan.renewalIntervalMonths} meses.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _RenewalFormValue(renewedOn: _renewedOn, notes: _notes.text.trim()),
        ),
        child: const Text('Confirmar'),
      ),
    ],
  );
}

class _TuyaPlanFormValue {
  const _TuyaPlanFormValue({
    required this.projectName,
    required this.planName,
    required this.lastRenewedOn,
    required this.nextRenewalOn,
    required this.intervalMonths,
    required this.reminderDays,
    required this.notes,
    required this.active,
  });

  final String projectName;
  final String planName;
  final DateTime? lastRenewedOn;
  final DateTime nextRenewalOn;
  final int intervalMonths;
  final int reminderDays;
  final String notes;
  final bool active;
}

class _RenewalFormValue {
  const _RenewalFormValue({required this.renewedOn, required this.notes});

  final DateTime renewedOn;
  final String notes;
}

Color calendarEntryColor(OperationsCalendarEntry entry) {
  if (entry.isIncident) {
    return entry.status == 'resolved' ? FiconColors.slate : FiconColors.danger;
  }
  if (entry.isCompletedRenewal) return FiconColors.success;
  return switch (entry.status) {
    'OVERDUE' => FiconColors.danger,
    'DUE_SOON' => FiconColors.warning,
    _ => FiconColors.logoBlue,
  };
}

IconData calendarEntryIcon(OperationsCalendarEntry entry) {
  if (entry.isIncident) return Icons.bolt;
  if (entry.isCompletedRenewal) return Icons.check_circle_outline;
  return Icons.autorenew;
}

const _monthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _weekdayNames = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String formatCalendarMonth(DateTime value) {
  final month = _monthNames[value.month - 1];
  return '${month[0].toUpperCase()}${month.substring(1)} ${value.year}';
}

String formatCalendarDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String formatCalendarLongDate(DateTime value) {
  final weekday = _weekdayNames[value.weekday - 1];
  final month = _monthNames[value.month - 1];
  return '${weekday[0].toUpperCase()}${weekday.substring(1)}, ${value.day} de $month';
}

String formatCalendarTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
