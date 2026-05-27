import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_state_provider.dart';
import '../widgets/responsive_layout.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _rateCtrl;
  final ScrollController _colorScrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final state = AppStateProvider.of(context);
      _nameCtrl = TextEditingController(text: state.userName);
      _emailCtrl = TextEditingController(text: state.userEmail);
      _rateCtrl = TextEditingController(text: state.hourlyRate.toStringAsFixed(0));
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _rateCtrl.dispose();
    _colorScrollController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppStateProvider.of(context);
    state.updateProfile(_nameCtrl.text.trim(), _emailCtrl.text.trim());
    final newRate = double.tryParse(_rateCtrl.text) ?? state.hourlyRate;
    state.updateHourlyRate(newRate);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _confirmWipe(BuildContext context, dynamic state) async {
    final messenger = ScaffoldMessenger.of(context);
    final wipe = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Wipe All Work Logs?'),
        content: const Text('This will permanently delete all logged work entries and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Wipe Everything', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (wipe == true) {
      state.clearAllData();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('All work log entries wiped.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveLayout.isMobile(context) ? AppTheme.spacingMD : AppTheme.spacingXL,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Settings',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      Text(
                        'Configure developer credentials, billing rates, and theme modes',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLG),

                  // ── Section 1: Profile & Billing ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.badge_outlined, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text('Developer Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: AppTheme.spacingLG),
                          
                          // Name Input
                          const Text('Developer Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Rizwana',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                          ),
                          const SizedBox(height: AppTheme.spacingMD),

                          // Email Input
                          const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'e.g. rizwana@freelancing.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                          ),
                          const SizedBox(height: AppTheme.spacingLG),

                          // Billing Rate
                          const Text('Hourly Billing Rate (Rs. / hr)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _rateCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 1500',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Hourly rate is required';
                              if (double.tryParse(v) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMD),

                          // Save Profile Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saveProfile,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Save Profile & Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),

                  // ── Section 2: Display & Accessibility ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette_outlined, color: AppTheme.accent, size: 20),
                              const SizedBox(width: 8),
                              const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: AppTheme.spacingLG),
                          SwitchListTile.adaptive(
                            value: widget.isDarkMode,
                            onChanged: (_) => widget.onToggleTheme(),
                            title: const Text('Dark Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Reduces eye strain in low-light environments', style: TextStyle(fontSize: 11)),
                            secondary: Icon(widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppTheme.accent),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(),
                          const SizedBox(height: AppTheme.spacingSM),
                          const Text('Premium Color Accents', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppTheme.spacingSM),
                          ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: Scrollbar(
                              controller: _colorScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: SizedBox(
                                  height: 52,
                                  child: ListView.separated(
                                    controller: _colorScrollController,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: AppThemeColors.themes.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemBuilder: (ctx, idx) {
                                      final themeColors = AppThemeColors.themes[idx];
                                      final isSelected = state.selectedTheme == themeColors.name;
                                      return GestureDetector(
                                        onTap: () => state.updateTheme(themeColors.name),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? themeColors.primary.withAlpha(26) 
                                                : theme.cardColor,
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                            border: Border.all(
                                              color: isSelected 
                                                  ? themeColors.primary 
                                                  : theme.dividerColor,
                                              width: isSelected ? 2.0 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Color circle
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: themeColors.primary,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 1.5),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                themeColors.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected 
                                                      ? themeColors.primary 
                                                      : theme.textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),

                  // ── Section 2.5: Custom Task Types ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category_outlined, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text('Custom Task Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: AppTheme.spacingLG),
                          state.customTaskTypes.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    'No custom task types created yet. Create them when adding log entries!',
                                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.customTaskTypes.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSM),
                                  itemBuilder: (context, index) {
                                    final type = state.customTaskTypes[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: type.color.withAlpha(26),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(type.icon, color: type.color, size: 18),
                                      ),
                                      title: Text(
                                        type.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                                        onPressed: () {
                                          state.deleteCustomTaskType(type.name);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Custom task type "${type.displayName}" deleted!'),
                                              backgroundColor: AppTheme.success,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),

                  // ── Section 3: Data Management (Danger Zone) ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.storage_rounded, color: AppTheme.danger, size: 20),
                              SizedBox(width: 8),
                              Text('Data Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: AppTheme.spacingLG),
                          
                          // Reload sample data
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Reload Default Sample Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Restores default April and May work log entries.', style: TextStyle(fontSize: 11)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                state.loadSampleData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sample April & May logs restored!'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface,
                                foregroundColor: AppTheme.primary,
                                side: BorderSide(color: AppTheme.primary),
                              ),
                              child: const Text('Reload'),
                            ),
                          ),
                          const Divider(),
                          
                          // Wipe database
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Clear All Logged Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.danger)),
                            subtitle: const Text('Permanently wipes out all entries to start fresh.', style: TextStyle(fontSize: 11)),
                            trailing: ElevatedButton(
                              onPressed: () => _confirmWipe(context, state),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
                              child: const Text('Wipe Data'),
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
      ),
    );
  }
}
