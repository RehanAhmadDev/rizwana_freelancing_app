import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_state_provider.dart';
import '../widgets/responsive_layout.dart';
import '../models/work_entry.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  
  static String _fmtPKR(double val) {
    final intVal = val.toInt();
    final str = intVal.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return 'Rs. $formatted';
  }

  static String _fmtDuration(double hours) {
    final int h = hours.toInt();
    final int m = ((hours - h) * 60).toInt();
    if (h > 0) {
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final entries = state.allEntries;
    final rate = state.hourlyRate;

    // 1. Lifetime Billing metrics
    final double totalLifetimeHours = entries.fold(0.0, (s, e) => s + e.totalHours);
    final double lifetimeEarnings = totalLifetimeHours * rate;

    // 2. This Month's Billing metrics
    final currentMonth = state.latestMonth.isEmpty ? 'May 2026' : state.latestMonth;
    final thisMonthMins = state.totalMinutesForMonth(currentMonth);
    final double thisMonthEarnings = (thisMonthMins / 60.0) * rate;

    // 3. Average Monthly Earnings
    final allMonths = state.allMonths;
    final double avgMonthlyEarnings = allMonths.isEmpty 
        ? 0.0 
        : lifetimeEarnings / allMonths.length;

    // 4. Client-wise grouping
    final clientEarningsMap = <String, double>{};
    final clientHoursMap = <String, double>{};
    final clientTasksMap = <String, int>{};

    for (final e in entries) {
      final hours = e.totalHours;
      final bill = hours * rate;
      clientEarningsMap[e.clientName] = (clientEarningsMap[e.clientName] ?? 0.0) + bill;
      clientHoursMap[e.clientName] = (clientHoursMap[e.clientName] ?? 0.0) + hours;
      clientTasksMap[e.clientName] = (clientTasksMap[e.clientName] ?? 0) + 1;
    }

    final sortedClients = clientEarningsMap.keys.toList()
      ..sort((a, b) => clientEarningsMap[b]!.compareTo(clientEarningsMap[a]!));

    // 5. Month-on-Month Trends
    final monthlyStatsList = <Map<String, dynamic>>[];
    for (final m in allMonths) {
      final mMins = state.totalMinutesForMonth(m);
      final mHours = mMins / 60.0;
      final mEarn = mHours * rate;
      final mTaskCount = entries.where((e) => e.month == m).length;
      monthlyStatsList.add({
        'month': m,
        'hours': mHours,
        'earnings': mEarn,
        'tasks': mTaskCount,
      });
    }

    double maxMonthEarnings = 0.0;
    String topEarningMonth = '';
    for (final s in monthlyStatsList) {
      if (s['earnings'] > maxMonthEarnings) {
        maxMonthEarnings = s['earnings'];
        topEarningMonth = s['month'];
      }
    }

    // 6. Task Type Contributions
    final taskEarningsMap = <TaskType, double>{};
    final taskHoursMap = <TaskType, double>{};
    double totalHoursAllTasks = 0.0;

    for (final e in entries) {
      final hours = e.totalHours;
      taskEarningsMap[e.taskType] = (taskEarningsMap[e.taskType] ?? 0.0) + (hours * rate);
      taskHoursMap[e.taskType] = (taskHoursMap[e.taskType] ?? 0.0) + hours;
      totalHoursAllTasks += hours;
    }
    final sortedTasks = taskEarningsMap.keys.toList()
      ..sort((a, b) => taskEarningsMap[b]!.compareTo(taskEarningsMap[a]!));

    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isMobile ? AppTheme.spacingMD : AppTheme.spacingXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Analytics',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  Text(
                    'Detailed stats on earnings, client leaderboards, and billing trends',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLG),

              // 1. Lifetime Earnings Summary card
              _buildLifetimeSummaryCard(lifetimeEarnings, thisMonthEarnings, avgMonthlyEarnings, currentMonth),
              const SizedBox(height: AppTheme.spacingLG),

              // 2. Client Leaderboard Section
              const Text(
                '🏆 Client Leaderboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              _buildClientLeaderboard(sortedClients, clientEarningsMap, clientHoursMap, clientTasksMap),
              const SizedBox(height: AppTheme.spacingLG),

              // Responsive Columns for Trends & Task contributions
              if (ResponsiveLayout.isDesktop(context))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildMonthlyBillingTrends(monthlyStatsList, topEarningMonth, maxMonthEarnings)),
                    const SizedBox(width: AppTheme.spacingLG),
                    Expanded(flex: 4, child: _buildTaskEarningContribution(sortedTasks, taskEarningsMap, lifetimeEarnings)),
                  ],
                )
              else ...[
                _buildMonthlyBillingTrends(monthlyStatsList, topEarningMonth, maxMonthEarnings),
                const SizedBox(height: AppTheme.spacingLG),
                _buildTaskEarningContribution(sortedTasks, taskEarningsMap, lifetimeEarnings),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifetimeSummaryCard(double lifetime, double thisMonth, double avg, String currentMonth) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(76),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wallet_giftcard_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'LIFETIME REVENUE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              _fmtPKR(lifetime),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Container(
              height: 0.8,
              color: Colors.white.withAlpha(51),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Earnings This Month',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtPKR(thisMonth),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        currentMonth,
                        style: const TextStyle(fontSize: 9, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white.withAlpha(51)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Average Earning / Month',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtPKR(avg),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        'across logged months',
                        style: TextStyle(fontSize: 9, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientLeaderboard(
    List<String> clients,
    Map<String, double> earningsMap,
    Map<String, double> hoursMap,
    Map<String, int> tasksMap,
  ) {
    if (clients.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No logged client stats yet.')),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final c = clients[idx];
          final earn = earningsMap[c] ?? 0.0;
          final hrs = hoursMap[c] ?? 0.0;
          final tasks = tasksMap[c] ?? 0;
          final isTopClient = idx == 0; // The first in sorted list is Top Client!

          return Container(
            width: 180,
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(
                color: isTopClient ? AppTheme.primary : Theme.of(context).dividerColor,
                width: isTopClient ? 1.8 : 1.0,
              ),
              boxShadow: isTopClient 
                  ? [BoxShadow(color: AppTheme.primary.withAlpha(26), blurRadius: 10, spreadRadius: 1)]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTopClient)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: AppTheme.primary, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '👑 Top',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fmtPKR(earn),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isTopClient ? AppTheme.primary : AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmtDuration(hrs)} · $tasks tasks',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyBillingTrends(List<Map<String, dynamic>> monthlyStats, String topMonth, double maxEarning) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Month-on-Month Trends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (monthlyStats.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: Text('No monthly revenue logged yet')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: monthlyStats.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingMD),
                itemBuilder: (ctx, idx) {
                  final s = monthlyStats[idx];
                  final month = s['month'] as String;
                  final double earn = s['earnings'] as double;
                  final double hours = s['hours'] as double;
                  final tasks = s['tasks'] as int;
                  final double percent = maxEarning > 0 ? (earn / maxEarning).clamp(0.0, 1.0) : 0.0;
                  final isTopMonth = month == topMonth;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                month,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (isTopMonth) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              ],
                            ],
                          ),
                          Text(
                            _fmtPKR(earn),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isTopMonth ? AppTheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_fmtDuration(hours)} spent',
                            style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          Text(
                            '$tasks entries',
                            style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 8,
                          backgroundColor: isTopMonth ? AppTheme.primary.withAlpha(26) : Theme.of(context).dividerColor,
                          color: isTopMonth ? AppTheme.primary : AppTheme.success,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskEarningContribution(List<TaskType> tasks, Map<TaskType, double> taskEarnings, double lifetime) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎨 Category Revenue Contribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: Text('No task breakdown logged yet')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingMD),
                itemBuilder: (ctx, idx) {
                  final t = tasks[idx];
                  final earn = taskEarnings[t] ?? 0.0;
                  final double percent = lifetime > 0 ? (earn / lifetime).clamp(0.0, 1.0) : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(t.icon, size: 14, color: t.color),
                              const SizedBox(width: 6),
                              Text(
                                t.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            '${_fmtPKR(earn)} (${(percent * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 6,
                          backgroundColor: t.color.withAlpha(26),
                          color: t.color,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
