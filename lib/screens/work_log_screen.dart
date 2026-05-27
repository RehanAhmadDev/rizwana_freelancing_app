import 'package:flutter/material.dart';
import '../models/work_entry.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_state_provider.dart';
import '../widgets/responsive_layout.dart';
import 'add_entry_sheet.dart';

class WorkLogScreen extends StatefulWidget {
  const WorkLogScreen({super.key});

  @override
  State<WorkLogScreen> createState() => _WorkLogScreenState();
}

class _WorkLogScreenState extends State<WorkLogScreen> {
  TaskType? _filterType;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final months = state.allMonths;

    // Default to latest month if nothing selected
    final selMonth = state.selectedMonth.isEmpty
        ? (months.isNotEmpty ? months.last : '')
        : state.selectedMonth;

    // Entries after month + client + type filter + global search
    List<WorkEntry> entries = state.entriesForMonth(selMonth);
    if (_filterType != null) {
      entries = entries.where((e) => e.taskType == _filterType).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      entries = entries.where((e) {
        return e.clientName.toLowerCase().contains(query) ||
               e.label.toLowerCase().contains(query) ||
               (e.note != null && e.note!.toLowerCase().contains(query));
      }).toList();
    }

    final totalMins = state.totalMinutesForMonth(selMonth);
    final breakdown = state.taskBreakdownForMonth(selMonth);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_entry_fab',
        onPressed: () => _openSheet(context, state, selMonth),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                state: state,
                months: months,
                selectedMonth: selMonth,
                onMonthSelected: (m) {
                  state.selectMonth(m);
                  setState(() => _filterType = null);
                },
              ),
            ),
            if (selMonth.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SummaryCard(
                  month: selMonth,
                  totalMins: totalMins,
                  taskCount: state.entriesForMonth(selMonth).length,
                  breakdown: breakdown,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                  child: _TypeFilterRow(
                    breakdown: breakdown,
                    selected: _filterType,
                    onSelected: (t) => setState(() => _filterType = _filterType == t ? null : t),
                  ),
                ),
              ),
            ],
            entries.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(month: selMonth),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMD,
                      AppTheme.spacingXS,
                      AppTheme.spacingMD,
                      100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _EntryCard(
                          entry: entries[i],
                          onEdit: () => _openSheet(context, state, selMonth, entry: entries[i]),
                          onDelete: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await _confirmDelete(context);
                            if (ok == true) {
                              final deletedClient = entries[i].clientName;
                              state.deleteEntry(entries[i].id);
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text('Task for "$deletedClient" deleted successfully.'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.danger,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        childCount: entries.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext ctx, AppState state, String month, {WorkEntry? entry}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AddEntrySheet(
        appState: state,
        initialMonth: month,
        editEntry: entry,
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext ctx) => showDialog<bool>(
        context: ctx,
        builder: (d) => AlertDialog(
          title: const Text('Delete Entry?'),
          content: const Text('This work entry will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: title + client dropdown + month tab row
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final AppState state;
  final List<String> months;
  final String selectedMonth;
  final ValueChanged<String> onMonthSelected;

  const _Header({
    required this.state,
    required this.months,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLG, AppTheme.spacingMD, AppTheme.spacingLG, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work Log',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Track daily design tasks & hours',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Client filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedClient,
                    isDense: true,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    items: state.allClients
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) state.selectClient(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          // Month tab chips
          if (months.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: months.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final m = months[idx];
                  final selected = m == selectedMonth;
                  return GestureDetector(
                    onTap: () => onMonthSelected(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(
                          color: selected ? AppTheme.primary : theme.dividerColor,
                        ),
                      ),
                      child: Text(
                        m,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppTheme.spacingMD),
          Divider(color: theme.dividerColor, height: 1),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary gradient card showing total hours + task type breakdown
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String month;
  final int totalMins;
  final int taskCount;
  final Map<TaskType, int> breakdown;

  const _SummaryCard({
    required this.month,
    required this.totalMins,
    required this.taskCount,
    required this.breakdown,
  });

  static String _fmtMins(int m) {
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem.toString().padLeft(2, '0')}m';
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    final leftSide = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          totalMins == 0 ? '0h' : _fmtMins(totalMins),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.5,
          ),
        ),
        Text(
          'Total Hours · $taskCount Tasks',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );

    final rightSide = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: breakdown.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entry.key.icon, size: 11, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${entry.key.displayName}: ${_fmtMins(entry.value)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMD),
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(76),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftSide,
                const SizedBox(height: AppTheme.spacingMD),
                rightSide,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftSide),
                const SizedBox(width: AppTheme.spacingMD),
                rightSide,
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips: All / Carousel / Quote / Infographic / Graphic Post / Other
// ─────────────────────────────────────────────────────────────────────────────
class _TypeFilterRow extends StatelessWidget {
  final Map<TaskType, int> breakdown;
  final TaskType? selected;
  final ValueChanged<TaskType> onSelected;

  const _TypeFilterRow({
    required this.breakdown,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMD, 0, AppTheme.spacingMD, AppTheme.spacingSM,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: breakdown.keys.map((type) {
          final isSelected = selected == type;
          return GestureDetector(
            onTap: () => onSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? type.color : type.color.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isSelected ? type.color : type.color.withAlpha(51),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, size: 12, color: isSelected ? Colors.white : type.color),
                  const SizedBox(width: 4),
                  Text(
                    type.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : type.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry card: colored left bar, icon, label, time badge, swipe-to-delete
// ─────────────────────────────────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final WorkEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = entry.taskType;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // we handle deletion ourselves
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingLG),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
        decoration: BoxDecoration(
          color: AppTheme.danger.withAlpha(20),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
      ),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: theme.dividerColor),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Colored left accent bar
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: t.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLG),
                      bottomLeft: Radius.circular(AppTheme.radiusLG),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Task type icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: t.color.withAlpha(26),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          child: Icon(t.icon, color: t.color, size: 20),
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        // Label + sub-info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (entry.note != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning.withAlpha(26),
                                        borderRadius:
                                            BorderRadius.circular(AppTheme.radiusFull),
                                      ),
                                      child: Text(
                                        entry.note!.length > 14
                                            ? '${entry.note!.substring(0, 12)}…'
                                            : entry.note!,
                                        style: const TextStyle(
                                          color: AppTheme.warning,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${t.displayName} · ${entry.clientName}',
                                style: TextStyle(
                                  color: t.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Time badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: t.color.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            border: Border.all(color: t.color.withAlpha(51)),
                          ),
                          child: Text(
                            entry.formattedTime,
                            style: TextStyle(
                              color: t.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String month;
  const _EmptyState({required this.month});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline_rounded,
            size: 72,
            color: Theme.of(context).dividerColor,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          const Text(
            'No entries yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            month.isEmpty
                ? 'Add a month and start logging your work'
                : 'Tap + Add Entry to log your work for $month',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
