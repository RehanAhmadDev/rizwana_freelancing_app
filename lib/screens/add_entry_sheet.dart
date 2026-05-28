import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/work_entry.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Bottom sheet for adding a new or editing an existing WorkEntry.
class AddEntrySheet extends StatefulWidget {
  final AppState appState;
  final String initialMonth;
  final WorkEntry? editEntry;

  final String? prefilledClient;
  final TaskType? prefilledTaskType;
  final String? prefilledLabel;
  final int? prefilledHours;
  final int? prefilledMinutes;
  final int? prefilledSeconds;

  const AddEntrySheet({
    super.key,
    required this.appState,
    required this.initialMonth,
    this.editEntry,
    this.prefilledClient,
    this.prefilledTaskType,
    this.prefilledLabel,
    this.prefilledHours,
    this.prefilledMinutes,
    this.prefilledSeconds,
  });

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clientCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _noteCtrl;
  late TaskType _taskType;
  late String _month;
  late int _hours;
  late int _minutes;
  late int _seconds;

  // Month options: current year + next year
  static final List<String> _monthOptions = [
    for (final yr in [DateTime.now().year, DateTime.now().year + 1])
      for (final m in [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ])
        '$m $yr',
  ];

  bool get _isEditing => widget.editEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editEntry;
    // Pre-fill from existing entry or sensible defaults
    _clientCtrl = TextEditingController(text: e?.clientName ?? widget.prefilledClient ?? '');
    _labelCtrl  = TextEditingController(text: e?.label ?? widget.prefilledLabel ?? '');
    _noteCtrl   = TextEditingController(text: e?.note ?? '');
    _taskType   = e?.taskType ?? widget.prefilledTaskType ?? TaskType.carousel;
    _month      = _monthOptions.contains(e?.month ?? widget.initialMonth)
                      ? (e?.month ?? widget.initialMonth)
                      : _monthOptions[3]; // April 2025
    _hours      = e?.hours ?? widget.prefilledHours ?? 3;
    _minutes    = e?.minutes ?? widget.prefilledMinutes ?? 0;
    _seconds    = e?.seconds ?? widget.prefilledSeconds ?? 0;
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _labelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final clientName = _clientCtrl.text.trim();

    if (_isEditing) {
      widget.appState.updateEntry(
        widget.editEntry!.copyWith(
          clientName: clientName,
          taskType: _taskType,
          label: _labelCtrl.text.trim(),
          hours: _hours,
          minutes: _minutes,
          seconds: _seconds,
          month: _month,
          note: note,
          clearNote: note == null,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Task for "$clientName" updated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      widget.appState.addEntry(
        WorkEntry.create(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          clientName: clientName,
          taskType: _taskType,
          label: _labelCtrl.text.trim(),
          hours: _hours,
          minutes: _minutes,
          seconds: _seconds,
          month: _month,
          note: note,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Task for "$clientName" added successfully!'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // Switch to the month the entry was saved in
    widget.appState.selectMonth(_month);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row
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
                  child: Icon(
                    _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Text(
                  _isEditing ? 'Edit Work Entry' : 'Add Work Entry',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLG,
                AppTheme.spacingMD,
                AppTheme.spacingLG,
                MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingXXL,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Client Name ──
                    _SectionLabel('Client Name'),
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _clientCtrl.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final clients = widget.appState.allClients.where((c) => c != 'All').toList();
                        if (textEditingValue.text.isEmpty) {
                          return clients;
                        }
                        return clients.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _clientCtrl.text = selection;
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        final theme = Theme.of(context);
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            color: theme.cardColor,
                            child: Container(
                              width: MediaQuery.of(context).size.width - (AppTheme.spacingLG * 2),
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            option,
                                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onFieldSubmitted: (v) => onFieldSubmitted(),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Heart of Gold',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (val) {
                            _clientCtrl.text = val;
                          },
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Client name is required' : null,
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // ── Task Type ──
                    _SectionLabel('Task Type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...widget.appState.allTaskTypes.map((type) {
                          final sel = _taskType == type;
                          return GestureDetector(
                            onTap: () => setState(() => _taskType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? type.color : type.color.withAlpha(20),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                border: Border.all(
                                  color: sel ? type.color : type.color.withAlpha(51),
                                  width: sel ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(type.icon, size: 14,
                                      color: sel ? Colors.white : type.color),
                                  const SizedBox(width: 5),
                                  Text(
                                    type.displayName,
                                    style: TextStyle(
                                      color: sel ? Colors.white : type.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () => _showAddCustomTypeSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              border: Border.all(
                                color: theme.dividerColor,
                                style: BorderStyle.solid,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 5),
                                Text(
                                  'Add Custom',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // ── Label / Description ──
                    _SectionLabel('Task Label / Description'),
                    TextFormField(
                      controller: _labelCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Day 1, Urgent Stroke Carousel',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Label is required' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // ── Time: Hours + Minutes + Preview ──
                    _SectionLabel('Time Spent'),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hours',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              _Spinner(
                                value: _hours,
                                min: 0,
                                max: 23,
                                onChanged: (v) => setState(() => _hours = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Minutes',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              _Spinner(
                                value: _minutes,
                                min: 0,
                                max: 59,
                                onChanged: (v) => setState(() => _minutes = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Seconds',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              _Spinner(
                                value: _seconds,
                                min: 0,
                                max: 59,
                                onChanged: (v) => setState(() => _seconds = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSM),
                        // Live preview
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                              border: Border.all(color: AppTheme.primary.withAlpha(51)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Total',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${_hours}h ${_minutes}m ${_seconds}s',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // ── Month ──
                    _SectionLabel('Month'),
                    DropdownButtonFormField<String>(
                      initialValue: _month,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                      ),
                      items: _monthOptions
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _month = v);
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // ── Note (optional) ──
                    _SectionLabel('Note (Optional)'),
                    TextFormField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Urgent, Redesign included',
                        prefixIcon: Icon(Icons.sticky_note_2_outlined),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXXL),

                    // ── Save Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
                        label: Text(
                          _isEditing ? 'Save Changes' : 'Add Entry',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomTypeSheet(BuildContext context) {
    final theme = Theme.of(context);
    final nameCtrl = TextEditingController();
    final colorScrollController = ScrollController();
    final iconScrollController = ScrollController();
    
    // Curated premium design colors
    final List<Color> colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFD946EF), // Fuchsia
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Rose/Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF14B8A6), // Teal
    ];
    
    // Curated design/freelance icons
    final List<IconData> icons = [
      Icons.brush_rounded,
      Icons.palette_rounded,
      Icons.code_rounded,
      Icons.view_carousel_rounded,
      Icons.format_quote_rounded,
      Icons.bar_chart_rounded,
      Icons.image_rounded,
      Icons.videocam_rounded,
      Icons.edit_note_rounded,
      Icons.work_outline_rounded,
      Icons.design_services_rounded,
      Icons.web_rounded,
    ];

    Color selectedColor = colors.first;
    IconData selectedIcon = icons.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: AppTheme.spacingLG,
                right: AppTheme.spacingLG,
                top: AppTheme.spacingLG,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLG,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Create Custom Task Type',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacingMD),
                    const Text('Category Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Logo Design, Web Development',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    const Text('Select Theme Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        controller: colorScrollController,
                        thumbVisibility: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: SizedBox(
                            height: 40,
                            child: ListView.separated(
                              controller: colorScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: colors.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final c = colors[idx];
                                final sel = selectedColor == c;
                                return GestureDetector(
                                  onTap: () => setModalState(() => selectedColor = c),
                                  child: Container(
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
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    const Text('Select Category Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        controller: iconScrollController,
                        thumbVisibility: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: SizedBox(
                            height: 48,
                            child: ListView.separated(
                              controller: iconScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: icons.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final ic = icons[idx];
                                final sel = selectedIcon == ic;
                                return GestureDetector(
                                  onTap: () => setModalState(() => selectedIcon = ic),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: sel ? selectedColor.withAlpha(30) : theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: sel ? selectedColor : theme.dividerColor,
                                        width: sel ? 2 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      ic,
                                      color: sel ? selectedColor : theme.iconTheme.color?.withAlpha(128),
                                      size: 20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXXL),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          
                          // Save custom task type to app state
                          widget.appState.addCustomTaskType(name, selectedColor, selectedIcon);
                          
                          // Sync local state
                          final lowerName = name.toLowerCase().replaceAll(' ', '_');
                          final newType = widget.appState.allTaskTypes.firstWhere(
                            (t) => t.name == lowerName,
                            orElse: () => TaskType(
                              name: lowerName,
                              displayName: name,
                              icon: selectedIcon,
                              color: selectedColor,
                            ),
                          );
                          
                          setState(() {
                            _taskType = newType;
                          });
                          
                          Navigator.pop(ctx);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Custom task type "$name" added successfully!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                        child: const Text('Add Task Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      colorScrollController.dispose();
      iconScrollController.dispose();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
}

/// +/- spinner with direct manual numeric keyboard typing support
class _Spinner extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Spinner({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString().padLeft(2, '0'));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // When losing focus, format with a beautiful leading zero
        _controller.text = widget.value.toString().padLeft(2, '0');
      }
    });
  }

  @override
  void didUpdateWidget(covariant _Spinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final formatted = widget.value.toString().padLeft(2, '0');
      if (!_focusNode.hasFocus && _controller.text != formatted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.text = formatted;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateValue(int newValue) {
    final clamped = newValue.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
    _controller.text = clamped.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 18),
            onPressed: widget.value > widget.min ? () => _updateValue(widget.value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
          ),
          Expanded(
            child: SizedBox(
              width: 30,
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) {
                    final clamped = parsed.clamp(widget.min, widget.max);
                    widget.onChanged(clamped);
                  }
                },
                onFieldSubmitted: (val) {
                  final parsed = int.tryParse(val) ?? widget.value;
                  _updateValue(parsed);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: widget.value < widget.max ? () => _updateValue(widget.value + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
          ),
        ],
      ),
    );
  }
}
