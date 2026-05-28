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
  late final TextEditingController _targetCtrl;
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
      _targetCtrl = TextEditingController(text: state.monthlyTargetGoal.toStringAsFixed(0));
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _rateCtrl.dispose();
    _targetCtrl.dispose();
    _colorScrollController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppStateProvider.of(context);
    state.updateProfile(_nameCtrl.text.trim(), _emailCtrl.text.trim());
    final newRate = double.tryParse(_rateCtrl.text) ?? state.hourlyRate;
    state.updateHourlyRate(newRate);
    final newTarget = double.tryParse(_targetCtrl.text) ?? state.monthlyTargetGoal;
    state.updateTargetGoal(newTarget);

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
          child: Center(
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

                    // Premium Profile Banner & Metrics card
                    _buildProfileBanner(context),
                    const SizedBox(height: AppTheme.spacingMD),

                    // ── Section 1: Collapsible Developer Profile & Billing ──
                    SettingsCollapsibleTile(
                      icon: Icons.badge_outlined,
                      iconColor: AppTheme.primary,
                      title: 'Developer Profile',
                      subtitle: 'Configure credentials and billing rate',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: AppTheme.spacingMD),

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

                          const Text('Monthly Target Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _targetCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 1000',
                              prefixIcon: Icon(Icons.ads_click_rounded),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Monthly target goal is required';
                              if (double.tryParse(v) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingLG),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saveProfile,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Save Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),

                    // ── Section 2: Collapsible Appearance customizer ──
                    SettingsCollapsibleTile(
                      icon: Icons.palette_outlined,
                      iconColor: AppTheme.accent,
                      title: 'Appearance',
                      subtitle: 'Dark mode and dynamic color accents',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          if (state.selectedTheme == 'Custom Gradient') ...[
                            const Divider(height: AppTheme.spacingLG),
                            const Text('Custom Gradient: Start Color (Primary)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: AppTheme.spacingSM),
                            _buildColorGrid(
                              context,
                              selectedColor: state.customPrimaryColor,
                              onColorSelected: (c) {
                                state.updateCustomColors(c, state.customAccentColor);
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            const Text('Custom Gradient: End Color (Accent)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: AppTheme.spacingSM),
                            _buildColorGrid(
                              context,
                              selectedColor: state.customAccentColor,
                              onColorSelected: (c) {
                                state.updateCustomColors(state.customPrimaryColor, c);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),

                    // ── Section 3: Collapsible Custom Task Types ──
                    SettingsCollapsibleTile(
                      icon: Icons.category_outlined,
                      iconColor: AppTheme.primary,
                      title: 'Custom Task Types',
                      subtitle: 'Add or remove task categories',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                    const SizedBox(height: AppTheme.spacingXS),

                    // ── Section 4: Collapsible Data Management (Danger Zone) ──
                    SettingsCollapsibleTile(
                      icon: Icons.storage_rounded,
                      iconColor: AppTheme.danger,
                      title: 'Data Management',
                      subtitle: 'Clear all logged work or restore default samples',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBanner(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);

    final List<IconData> avatars = [
      Icons.brush_rounded,             // Creative / Illustrator
      Icons.code_rounded,              // Tech Developer
      Icons.design_services_rounded,   // UI / UX Designer
      Icons.edit_note_rounded,         // Writer
      Icons.emoji_objects_rounded,     // Idea / Consultant
      Icons.pets_rounded,              // Animal Lover
    ];
    final selectedIcon = avatars[state.selectedAvatarIndex % avatars.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarPickerSheet(context, avatars),
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(76),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: theme.scaffoldBackgroundColor,
                          child: Icon(selectedIcon, color: AppTheme.primary, size: 36),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${state.userName}! 👋',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        state.userEmail,
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Cloud Synchronized',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppTheme.spacingLG),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCol(
                    context,
                    title: 'Logged Entries',
                    value: '${state.allEntries.length}',
                  ),
                ),
                Container(width: 1, height: 32, color: theme.dividerColor),
                Expanded(
                  child: _buildMetricCol(
                    context,
                    title: 'Active Clients',
                    value: '${state.allClients.length - 1}',
                  ),
                ),
                Container(width: 1, height: 32, color: theme.dividerColor),
                Expanded(
                  child: _buildMetricCol(
                    context,
                    title: 'Active Theme',
                    value: state.selectedTheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(BuildContext context, {required String title, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showAvatarPickerSheet(BuildContext context, List<IconData> avatars) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Profile Icon',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppTheme.spacingMD),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, idx) {
                    final isSel = state.selectedAvatarIndex == idx;
                    return GestureDetector(
                      onTap: () {
                        state.updateAvatarIndex(idx);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? AppTheme.primary : theme.dividerColor,
                            width: isSel ? 3.0 : 1.0,
                          ),
                          color: isSel ? AppTheme.primary.withAlpha(26) : Colors.transparent,
                        ),
                        child: Icon(avatars[idx], color: isSel ? AppTheme.primary : theme.iconTheme.color, size: 28),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorGrid(BuildContext context, {required Color selectedColor, required ValueChanged<Color> onColorSelected}) {
    final List<Color> colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFD946EF), // Fuchsia
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Rose
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF14B8A6), // Teal
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final c = colors[idx];
          final sel = selectedColor.value == c.value;
          return GestureDetector(
            onTap: () => onColorSelected(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: sel ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: sel
                    ? [BoxShadow(color: c.withAlpha(128), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: sel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          );
        },
      ),
    );
  }
}

class SettingsCollapsibleTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const SettingsCollapsibleTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  State<SettingsCollapsibleTile> createState() => _SettingsCollapsibleTileState();
}

class _SettingsCollapsibleTileState extends State<SettingsCollapsibleTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSM),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 20),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right_rounded, color: theme.iconTheme.color?.withAlpha(128)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  child: widget.child,
                ),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
