import 'package:flutter/material.dart';
import '../models/work_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/app_state_provider.dart';
import '../widgets/responsive_layout.dart';
import '../state/app_state.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  static String _fmtMins(int m) {
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  static String _fmtPKR(double val) {
    final intVal = val.toInt();
    final str = intVal.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return 'Rs. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);
    
    // Extract clients, filter out 'All' and apply search query
    final clients = state.allClients
        .where((c) => c != 'All')
        .where((c) => state.searchQuery.isEmpty || c.toLowerCase().contains(state.searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClientDialog(context, state),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Client', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveLayout.isMobile(context) ? AppTheme.spacingMD : AppTheme.spacingXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clients Directory',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      Text(
                        'Analyze work distributions and billing per client',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '${clients.length} Clients',
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
              const SizedBox(height: AppTheme.spacingLG),

              // Empty State
              if (clients.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 72, color: theme.dividerColor),
                        const SizedBox(height: AppTheme.spacingMD),
                        const Text(
                          'No Clients Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        const Text(
                          'Add work entries to populate your clients directory.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else if (ResponsiveLayout.isMobile(context))
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    
                    // Filter entries for this client
                    final clientEntries = state.allEntries.where((e) => e.clientName == client).toList();
                    final int totalMins = clientEntries.fold(0, (sum, e) => sum + e.totalMinutes);
                    final double earnings = (totalMins / 60.0) * state.hourlyRate;

                    // Breakdown of task types
                    final Map<TaskType, int> breakdown = {};
                    for (final e in clientEntries) {
                      breakdown[e.taskType] = (breakdown[e.taskType] ?? 0) + 1;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showClientDetails(context, client, state),
                          child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Client Name + Earnings
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      client,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withAlpha(26),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                      border: Border.all(color: AppTheme.success.withAlpha(51)),
                                    ),
                                    child: Text(
                                      _fmtPKR(earnings),
                                      style: const TextStyle(
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              // Time and Entry counts
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 13, color: theme.textTheme.bodySmall?.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    _fmtMins(totalMins),
                                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMD),
                                  Icon(Icons.task_alt_rounded, size: 13, color: theme.textTheme.bodySmall?.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${clientEntries.length} entries',
                                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                  ),
                                ],
                              ),
                              const Divider(height: AppTheme.spacingLG),
                              const Text(
                                'Task Distribution',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              
                              // Horizontal Wrap of task breakdown tags (Adaptive Height)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: breakdown.entries.map((b) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: b.key.color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                      border: Border.all(color: b.key.color.withAlpha(51)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(b.key.icon, size: 10, color: b.key.color),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${b.key.displayName}: ${b.value}',
                                          style: TextStyle(
                                            color: b.key.color,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                )
              else
                // Responsive Grid of Clients for Tablet/Desktop
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // For tablets it can be changed but GridView is used here for non-mobile
                    crossAxisSpacing: AppTheme.spacingMD,
                    mainAxisSpacing: AppTheme.spacingMD,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    
                    // Filter entries for this client
                    final clientEntries = state.allEntries.where((e) => e.clientName == client).toList();
                    final int totalMins = clientEntries.fold(0, (sum, e) => sum + e.totalMinutes);
                    final double earnings = (totalMins / 60.0) * state.hourlyRate;

                    // Breakdown of task types
                    final Map<TaskType, int> breakdown = {};
                    for (final e in clientEntries) {
                      breakdown[e.taskType] = (breakdown[e.taskType] ?? 0) + 1;
                    }

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showClientDetails(context, client, state),
                        child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Client Name + Earnings
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    client,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withAlpha(26),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                    border: Border.all(color: AppTheme.success.withAlpha(51)),
                                  ),
                                  child: Text(
                                    _fmtPKR(earnings),
                                    style: const TextStyle(
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            // Time and Entry counts
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 13, color: theme.textTheme.bodySmall?.color),
                                const SizedBox(width: 4),
                                Text(
                                  _fmtMins(totalMins),
                                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                ),
                                const SizedBox(width: AppTheme.spacingMD),
                                Icon(Icons.task_alt_rounded, size: 13, color: theme.textTheme.bodySmall?.color),
                                const SizedBox(width: 4),
                                Text(
                                  '${clientEntries.length} entries',
                                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                ),
                              ],
                            ),
                            const Divider(height: AppTheme.spacingLG),
                            const Text(
                              'Task Distribution',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            
                            // Horizontal Wrap of task breakdown tags (With Expandable scroll on Desktop Grid)
                            Expanded(
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: breakdown.entries.map((b) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: b.key.color.withAlpha(20),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                        border: Border.all(color: b.key.color.withAlpha(51)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(b.key.icon, size: 10, color: b.key.color),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${b.key.displayName}: ${b.value}',
                                            style: TextStyle(
                                              color: b.key.color,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientDetails(BuildContext context, String clientName, AppState state) {
    final theme = Theme.of(context);
    final clientEntries = state.allEntries.where((e) => e.clientName == clientName).toList();
    final int totalMins = clientEntries.fold(0, (sum, e) => sum + e.totalMinutes);
    final double earnings = (totalMins / 60.0) * state.hourlyRate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Icon(Icons.person_outline_rounded, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Total Earnings: ${_fmtPKR(earnings)} • ${_fmtMins(totalMins)}',
                            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: AppTheme.primary),
                      tooltip: 'Edit Client Name',
                      onPressed: () {
                        _showEditClientDialog(context, clientName, state, () {
                          Navigator.pop(context); // close bottom sheet
                        });
                      },
                    ),
                    if (state.customClients.contains(clientName))
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                        tooltip: 'Delete Client',
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Client?'),
                              content: Text('Are you sure you want to remove "$clientName" from the directory?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            state.deleteCustomClient(clientName);
                            if (context.mounted) {
                              Navigator.pop(context); // close bottom sheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Client "$clientName" removed successfully.')),
                              );
                            }
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: AppTheme.spacingLG),
              Expanded(
                child: clientEntries.isEmpty
                    ? const Center(child: Text('No entries for this client'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG, vertical: AppTheme.spacingSM),
                        itemCount: clientEntries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingMD),
                        itemBuilder: (context, idx) {
                          final e = clientEntries[idx];
                          return Card(
                            margin: EdgeInsets.zero,
                            color: theme.cardColor.withAlpha(128),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: e.taskType.color.withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(e.taskType.icon, color: e.taskType.color, size: 18),
                              ),
                              title: Text(
                                e.label,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (e.note != null && e.note!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      e.note!,
                                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${e.month} • ${e.hours}h ${e.minutes}m',
                                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                _fmtPKR((e.totalMinutes / 60.0) * state.hourlyRate),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddClientDialog(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Add New Client'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Client or Company Name',
              hintText: 'e.g. Heart of Gold, TechCorp',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Client name is required';
              }
              if (state.allClients.contains(val.trim())) {
                return 'This client name already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final name = ctrl.text.trim();
                state.addCustomClient(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Client "$name" added successfully!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Add Client'),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, String currentName, AppState state, VoidCallback onDone) {
    final ctrl = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Edit Client Name'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Client or Company Name',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Client name is required';
              }
              final trimmed = val.trim();
              if (trimmed != currentName && state.allClients.contains(trimmed)) {
                return 'This client name already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newName = ctrl.text.trim();
                state.updateCustomClient(currentName, newName);
                Navigator.pop(ctx);
                onDone();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Client name updated from "$currentName" to "$newName" successfully!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
