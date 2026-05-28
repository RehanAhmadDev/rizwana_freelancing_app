import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_entry.dart';
import '../theme/app_theme.dart';

/// Central state manager for the Rizwana Freelancing App.
/// Uses ChangeNotifier so UI rebuilds automatically on any data change.
class AppState extends ChangeNotifier {
  final List<WorkEntry> _entries = [];
  String _selectedMonth = '';
  String _selectedClient = 'All';
  String _searchQuery = '';
  String _selectedTheme = 'Royal Violet';

  // Profile and rate configurations
  String _userName = 'Rizwana';
  String _userEmail = 'rizwana@freelancing.com';
  double _hourlyRate = 30.0;
  int _selectedAvatarIndex = 0;

  // Monthly Target Goal configuration
  double _monthlyTargetGoal = 1000.0;

  // Live Work Session Timer state
  bool _isTimerActive = false;
  bool _isTimerPaused = false;
  int _timerSeconds = 0;
  Timer? _timer;
  String _timerClient = '';
  TaskType _timerTaskType = TaskType.carousel;
  String _timerLabel = '';

  // Custom Gradient Theme configuration
  Color _customPrimaryColor = const Color(0xFF6366F1);
  Color _customAccentColor = const Color(0xFFD946EF);

  final List<TaskType> _customTaskTypes = [];
  List<TaskType> get customTaskTypes => List.unmodifiable(_customTaskTypes);

  final List<String> _customClients = [];
  List<String> get customClients => List.unmodifiable(_customClients);

  List<TaskType> get allTaskTypes => [
    ...TaskType.values,
    ..._customTaskTypes,
  ];

  StreamSubscription<List<Map<String, dynamic>>>? _entriesSubscription;

  final List<Map<String, dynamic>> _syncQueue = [];
  bool _isSyncing = false;

  // Supabase real-time sync initializer
  void initializeSupabaseSync() async {
    await _loadCustomTaskTypes();
    await _loadCustomClients();
    await _loadCustomEntries(); // Load local cached entries immediately (instant startup)
    await _loadSyncQueue();     // Load pending sync queue
    await _loadTargetGoal();    // Load monthly target goal
    await _loadAvatarIndex();   // Load selected avatar index
    await _loadThemeName();     // Load premium selected theme
    _fetchProfile();
    _startListeningToEntries();
    syncOfflineQueue();         // Attempt background synchronization immediately
  }

  // Helper: get cross-platform app documents directory
  Future<String> _getAppDir() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
        if (homeDir.isNotEmpty) return homeDir;
      }
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (e) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  Future<void> _loadSyncQueue() async {
    try {
      final appDir = await _getAppDir();
      final file = File('$appDir/.freelancing_app_sync_queue.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _syncQueue.clear();
        for (final item in jsonList) {
          _syncQueue.add(Map<String, dynamic>.from(item));
        }
      }
    } catch (e) {
      debugPrint('Error loading sync queue: $e');
    }
  }

  Future<void> _saveSyncQueue() async {
    try {
      final appDir = await _getAppDir();
      final file = File('$appDir/.freelancing_app_sync_queue.json');
      await file.writeAsString(jsonEncode(_syncQueue));
    } catch (e) {
      debugPrint('Error saving sync queue: $e');
    }
  }

  Future<void> _loadCustomEntries() async {
    try {
      final appDir = await _getAppDir();
      final file = File('$appDir/.freelancing_app_entries.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _entries.clear();
        for (final item in jsonList) {
          _entries.add(WorkEntry.fromJson(item, allTaskTypes));
        }
        _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (_selectedMonth.isEmpty && allMonths.isNotEmpty) {
          _selectedMonth = allMonths.last;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached entries: $e');
    }
  }

  Future<void> _saveCustomEntries() async {
    try {
      final appDir = await _getAppDir();
      final file = File('$appDir/.freelancing_app_entries.json');
      final jsonList = _entries.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving cached entries: $e');
    }
  }

  Future<void> _loadThemeName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedTheme = prefs.getString('app_theme') ?? 'Royal Violet';
      final primaryVal = prefs.getInt('custom_theme_primary') ?? 0xFF6366F1;
      final accentVal = prefs.getInt('custom_theme_accent') ?? 0xFFD946EF;
      _customPrimaryColor = Color(primaryVal);
      _customAccentColor = Color(accentVal);
      
      _updateCurrentColors();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme name: $e');
    }
  }

  void _updateCurrentColors() {
    if (_selectedTheme == 'Custom Gradient') {
      AppTheme.currentThemeColors = AppThemeColors(
        name: 'Custom Gradient',
        primary: _customPrimaryColor,
        primaryLight: _customPrimaryColor.withAlpha(204),
        primaryDark: _customPrimaryColor.withAlpha(255),
        accent: _customAccentColor,
      );
    } else {
      final tc = AppThemeColors.themes.firstWhere(
        (t) => t.name == _selectedTheme,
        orElse: () => AppThemeColors.royalViolet,
      );
      AppTheme.currentThemeColors = tc;
    }
  }

  Future<void> _saveThemeName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', _selectedTheme);
    } catch (e) {
      debugPrint('Error saving theme name: $e');
    }
  }

  void updateTheme(String themeName) async {
    _selectedTheme = themeName;
    _updateCurrentColors();
    notifyListeners();
    await _saveThemeName();
  }

  void updateCustomColors(Color primary, Color accent) async {
    _customPrimaryColor = primary;
    _customAccentColor = accent;
    if (_selectedTheme == 'Custom Gradient') {
      _updateCurrentColors();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('custom_theme_primary', primary.toARGB32());
      await prefs.setInt('custom_theme_accent', accent.toARGB32());
    } catch (e) {
      debugPrint('Error saving custom colors: $e');
    }
  }

  Future<void> syncOfflineQueue() async {
    if (_isSyncing || _syncQueue.isEmpty) return;
    _isSyncing = true;

    while (_syncQueue.isNotEmpty) {
      final item = _syncQueue.first;
      final action = item['action'] as String;
      final entryData = item['entry'] as Map<String, dynamic>?;
      final id = item['id'] as String;

      try {
        final client = Supabase.instance.client;
        if (action == 'add' && entryData != null) {
          final entry = WorkEntry.fromJson(entryData, allTaskTypes);
          await client.from('work_entries').insert({
            'id': entry.id,
            'client_name': entry.clientName,
            'task_type': entry.taskType.name,
            'label': entry.label,
            'hours': entry.hours,
            'minutes': entry.minutes,
            'month': entry.month,
            'note': entry.supabaseNote,
            'created_at': entry.createdAt.toIso8601String(),
          });
        } else if (action == 'update' && entryData != null) {
          final entry = WorkEntry.fromJson(entryData, allTaskTypes);
          await client.from('work_entries').update({
            'client_name': entry.clientName,
            'task_type': entry.taskType.name,
            'label': entry.label,
            'hours': entry.hours,
            'minutes': entry.minutes,
            'month': entry.month,
            'note': entry.supabaseNote,
          }).eq('id', entry.id);
        } else if (action == 'delete') {
          await client.from('work_entries').delete().eq('id', id);
        }

        _syncQueue.removeAt(0);
        await _saveSyncQueue();
      } catch (e) {
        debugPrint('Sync failed for item (action: $action, id: $id): $e');
        break;
      }
    }

    _isSyncing = false;
  }

  // Fetch settings from the profiles table
  Future<void> _fetchProfile() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('profiles')
          .select()
          .eq('id', 'main_profile');
      
      if (response.isEmpty) {
        // Self-heal: insert default profile row in Supabase
        await client.from('profiles').insert({
          'id': 'main_profile',
          'user_name': 'Rizwana',
          'user_email': 'rizwana@freelancing.com',
          'hourly_rate': 30.0,
        });
        _userName = 'Rizwana';
        _userEmail = 'rizwana@freelancing.com';
        _hourlyRate = 30.0;
      } else {
        final profile = response.first;
        _userName = profile['user_name'] as String;
        _userEmail = profile['user_email'] as String;
        _hourlyRate = (profile['hourly_rate'] as num).toDouble();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile from Supabase: $e');
    }
  }

  // Start real-time stream subscription on work_entries
  void _startListeningToEntries() {
    _entriesSubscription?.cancel();
    _entriesSubscription = Supabase.instance.client
        .from('work_entries')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
          if (_syncQueue.isNotEmpty) {
            syncOfflineQueue();
            return;
          }

          _entries.clear();
          for (final row in data) {
            final taskStr = row['task_type'] as String;
            final type = allTaskTypes.firstWhere(
              (t) => t.name == taskStr,
              orElse: () {
                final cleanName = taskStr.replaceAll('_', ' ');
                final capitalized = cleanName.isEmpty
                    ? 'Other'
                    : '${cleanName[0].toUpperCase()}${cleanName.substring(1)}';
                return TaskType(
                  name: taskStr,
                  displayName: capitalized,
                  icon: Icons.work_outline_rounded,
                  color: const Color(0xFF94A3B8), // Slate color
                );
              },
            );
            final rawNote = row['note'] as String?;
            final parsedTime = WorkEntry.parseNoteAndSeconds(rawNote);
            _entries.add(WorkEntry(
              id: row['id'] as String,
              clientName: row['client_name'] as String,
              taskType: type,
              label: row['label'] as String,
              hours: row['hours'] as int,
              minutes: row['minutes'] as int,
              seconds: parsedTime['seconds'] as int,
              month: row['month'] as String,
              note: parsedTime['note'] as String?,
              createdAt: DateTime.parse(row['created_at'] as String),
            ));
          }
          if (_selectedMonth.isEmpty && allMonths.isNotEmpty) {
            _selectedMonth = allMonths.last;
          }
          _saveCustomEntries();
          notifyListeners();
        }, onError: (e) {
          debugPrint('Supabase stream error: $e');
        });
  }

  // ──────────────────── GETTERS ────────────────────

  List<WorkEntry> get allEntries => List.unmodifiable(_entries);

  String get selectedMonth => _selectedMonth;
  String get selectedClient => _selectedClient;
  String get searchQuery => _searchQuery;
  String get selectedTheme => _selectedTheme;

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  String get userName => _userName;
  String get userEmail => _userEmail;
  double get hourlyRate => _hourlyRate;

  // ──────────────────── TARGET GOAL GETTERS/SETTERS ────────────────────
  double get monthlyTargetGoal => _monthlyTargetGoal;
  int get selectedAvatarIndex => _selectedAvatarIndex;

  Future<void> _loadAvatarIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedAvatarIndex = prefs.getInt('selected_avatar_index') ?? 0;
    } catch (e) {
      debugPrint('Error loading avatar index: $e');
    }
  }

  void updateAvatarIndex(int index) async {
    _selectedAvatarIndex = index;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_avatar_index', index);
    } catch (e) {
      debugPrint('Error saving avatar index: $e');
    }
  }

  Future<void> _loadTargetGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _monthlyTargetGoal = prefs.getDouble('monthly_target_goal') ?? 1000.0;
    } catch (e) {
      debugPrint('Error loading target goal: $e');
    }
  }

  void updateTargetGoal(double goal) async {
    _monthlyTargetGoal = goal;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('monthly_target_goal', goal);
    } catch (e) {
      debugPrint('Error saving target goal: $e');
    }
  }

  // ──────────────────── LIVE SESSION TIMER GETTERS & METHODS ────────────────────
  bool get isTimerActive => _isTimerActive;
  bool get isTimerPaused => _isTimerPaused;
  int get timerSeconds => _timerSeconds;
  String get timerClient => _timerClient;
  TaskType get timerTaskType => _timerTaskType;
  String get timerLabel => _timerLabel;

  Color get customPrimaryColor => _customPrimaryColor;
  Color get customAccentColor => _customAccentColor;

  void startTimer(String client, TaskType taskType, String label) {
    if (_isTimerActive) return;
    _timerClient = client;
    _timerTaskType = taskType;
    _timerLabel = label;
    _isTimerActive = true;
    _isTimerPaused = false;
    _timerSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isTimerPaused) {
        _timerSeconds++;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    if (!_isTimerActive) return;
    _isTimerPaused = true;
    notifyListeners();
  }

  void resumeTimer() {
    if (!_isTimerActive || !_isTimerPaused) return;
    _isTimerPaused = false;
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isTimerActive = false;
    _isTimerPaused = false;
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _timerSeconds = 0;
    _timerClient = '';
    _timerLabel = '';
    notifyListeners();
  }

  // ──────────────────── PROFILE & RATE ACTIONS ────────────────────

  void updateProfile(String name, String email) async {
    _userName = name;
    _userEmail = email;
    notifyListeners();
    try {
      await Supabase.instance.client.from('profiles').update({
        'user_name': name,
        'user_email': email,
      }).eq('id', 'main_profile');
    } catch (e) {
      debugPrint('Error updating profile in Supabase: $e');
    }
  }

  void updateHourlyRate(double rate) async {
    _hourlyRate = rate;
    notifyListeners();
    try {
      await Supabase.instance.client.from('profiles').update({
        'hourly_rate': rate,
      }).eq('id', 'main_profile');
    } catch (e) {
      debugPrint('Error updating hourly rate in Supabase: $e');
    }
  }

  double totalEarningsForMonth(String month) {
    final mins = totalMinutesForMonth(month);
    return (mins / 60.0) * _hourlyRate;
  }

  /// All months present in entries, sorted by calendar order
  List<String> get allMonths {
    const order = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final months = _entries.map((e) => e.month).toSet().toList();
    months.sort((a, b) {
      final aParts = a.split(' ');
      final bParts = b.split(' ');
      final aY = aParts.length > 1 ? int.tryParse(aParts[1]) ?? 0 : 0;
      final bY = bParts.length > 1 ? int.tryParse(bParts[1]) ?? 0 : 0;
      if (aY != bY) return aY.compareTo(bY);
      return order.indexOf(aParts[0]).compareTo(order.indexOf(bParts[0]));
    });
    return months;
  }

  /// All unique client names, with 'All' prepended
  List<String> get allClients {
    final entryClients = _entries.map((e) => e.clientName).toSet();
    final combined = {..._customClients, ...entryClients}.toList()..sort();
    return ['All', ...combined];
  }

  /// Entries for a specific month, optionally filtered by current client
  List<WorkEntry> entriesForMonth(String month) {
    return _entries.where((e) {
      final monthOk = month.isEmpty || month == 'All Months' || e.month == month;
      final clientOk = _selectedClient == 'All' || e.clientName == _selectedClient;
      return monthOk && clientOk;
    }).toList();
  }

  // ──────────────────── SUMMARY HELPERS ────────────────────

  int totalMinutesForMonth(String month) =>
      entriesForMonth(month).fold(0, (s, e) => s + e.totalMinutes);

  String formattedTotalForMonth(String month) {
    final mins = totalMinutesForMonth(month);
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  Map<TaskType, int> taskBreakdownForMonth(String month) {
    final breakdown = <TaskType, int>{};
    for (final e in entriesForMonth(month)) {
      breakdown[e.taskType] = (breakdown[e.taskType] ?? 0) + e.totalMinutes;
    }
    return breakdown;
  }

  // ──────────────────── DASHBOARD STATS ────────────────────

  String get latestMonth => allMonths.isNotEmpty ? allMonths.last : '';

  int get totalTasksLatestMonth => entriesForMonth(latestMonth).length;

  String get totalHoursLatestMonth => formattedTotalForMonth(latestMonth);

  int get totalClientsCount => allClients.length - 1; // minus 'All'

  String get topTaskTypeLatestMonth {
    final breakdown = taskBreakdownForMonth(latestMonth);
    if (breakdown.isEmpty) return 'N/A';
    return breakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key
        .displayName;
  }

  int get totalEntriesAllTime => _entries.length;

  // ──────────────────── ACTIONS ────────────────────

  void selectMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void selectClient(String client) {
    _selectedClient = client;
    notifyListeners();
  }

  void addEntry(WorkEntry entry) async {
    // 1. Optimistic Local Update
    _entries.add(entry);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _saveCustomEntries();
    notifyListeners();

    // 2. Queue and Sync
    _syncQueue.add({
      'action': 'add',
      'id': entry.id,
      'entry': entry.toJson(),
    });
    await _saveSyncQueue();
    syncOfflineQueue();
  }

  void updateEntry(WorkEntry updated) async {
    // 1. Optimistic Local Update
    final index = _entries.indexWhere((x) => x.id == updated.id);
    if (index != -1) {
      _entries[index] = updated;
      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _saveCustomEntries();
      notifyListeners();
    }

    // 2. Queue and Sync
    _syncQueue.add({
      'action': 'update',
      'id': updated.id,
      'entry': updated.toJson(),
    });
    await _saveSyncQueue();
    syncOfflineQueue();
  }

  void deleteEntry(String id) async {
    // 1. Optimistic Local Update
    final index = _entries.indexWhere((x) => x.id == id);
    if (index != -1) {
      _entries.removeAt(index);
      _saveCustomEntries();
      notifyListeners();
    }

    // 2. Queue and Sync
    _syncQueue.add({
      'action': 'delete',
      'id': id,
    });
    await _saveSyncQueue();
    syncOfflineQueue();
  }

  // ──────────────────── SAMPLE DATA ────────────────────

  void loadSampleData() async {
    try {
      // First wipe all entries in Supabase
      await Supabase.instance.client.from('work_entries').delete().neq('id', '');
      
      // Then batch insert all sample entries
      final entries = _buildSampleData();
      final rows = entries.map((e) => {
        'id': e.id,
        'client_name': e.clientName,
        'task_type': e.taskType.name,
        'label': e.label,
        'hours': e.hours,
        'minutes': e.minutes,
        'month': e.month,
        'note': e.note,
        'created_at': e.createdAt.toIso8601String(),
      }).toList();
      
      await Supabase.instance.client.from('work_entries').insert(rows);
    } catch (e) {
      debugPrint('Error loading sample data in Supabase: $e');
    }
  }

  void clearAllData() async {
    _entries.clear();
    _syncQueue.clear();
    _saveCustomEntries();
    _saveSyncQueue();
    notifyListeners();
    try {
      await Supabase.instance.client.from('work_entries').delete().neq('id', '');
    } catch (e) {
      debugPrint('Error wiping data in Supabase: $e');
    }
  }

  static int _idSeq = 1000;
  static String _uid() => (++_idSeq).toString();

  List<WorkEntry> _buildSampleData() {
    final d = DateTime(2026, 4, 1);
    return [
      // ── APRIL 2026 ────────────────────────────────
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 1',                    hours: 4, minutes: 32, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.quote,       label: 'Day 2',                    hours: 3, minutes: 15, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.infographic, label: 'Day 3',                    hours: 3, minutes: 24, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.graphicPost, label: 'Day 4',                    hours: 3, minutes: 45, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 5',                    hours: 4, minutes: 45, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.infographic, label: 'Day 6',                    hours: 3, minutes: 36, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.quote,       label: 'Day 7',                    hours: 3, minutes: 19, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 8',                    hours: 4, minutes: 45, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.graphicPost, label: 'Day 9',                    hours: 3, minutes: 42, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 10',                   hours: 4, minutes: 40, month: 'April 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.other,       label: '4th Anniversary Post',     hours: 4, minutes:  0, month: 'April 2026', createdAt: d),
      // ── MAY 2026 ──────────────────────────────────
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 1',                    hours: 4, minutes: 35, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.quote,       label: 'Day 2 · 3D Quote',         hours: 3, minutes: 37, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.graphicPost, label: 'Day 3',                    hours: 4, minutes: 20, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Urgent Stroke Carousel',   hours: 5, minutes: 20, month: 'May 2026', note: 'Urgent',                        createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.graphicPost, label: 'Day 4',                    hours: 3, minutes: 53, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 5',                    hours: 4, minutes: 51, month: 'May 2026', note: 'Redesign: 1h 26m included',     createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.infographic, label: 'Day 6',                    hours: 3, minutes: 44, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.quote,       label: 'Day 7',                    hours: 3, minutes: 28, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 8',                    hours: 4, minutes: 56, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.other,       label: 'UK Visas PDF',             hours: 2, minutes:  0, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.graphicPost, label: 'Day 9',                    hours: 3, minutes: 50, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 10',                   hours: 4, minutes: 45, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.infographic, label: 'Day 11',                   hours: 3, minutes: 36, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.quote,       label: 'Day 12',                   hours: 3, minutes: 21, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 13',                   hours: 4, minutes: 44, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.graphicPost, label: 'Day 14',                   hours: 4, minutes:  0, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.carousel,    label: 'Day 15',                   hours: 4, minutes: 45, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.infographic, label: 'Day 16',                   hours: 3, minutes: 41, month: 'May 2026', createdAt: d),
      WorkEntry(id: _uid(), clientName: 'Heart of Gold', taskType: TaskType.quote,       label: 'Day 17',                   hours: 3, minutes: 26, month: 'May 2026', createdAt: d),
    ];
  }

  Future<void> _loadCustomTaskTypes() async {
    try {
      final appDir = await _getAppDir();
      final file = File('$appDir/.freelancing_app_task_types.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _customTaskTypes.clear();
        for (final item in jsonList) {
          _customTaskTypes.add(TaskType(
            name: item['name'] as String,
            displayName: item['displayName'] as String,
            icon: IconData(item['icon'] as int, fontFamily: 'MaterialIcons'),
            color: Color(item['color'] as int),
          ));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading custom task types: $e');
    }
  }

  Future<void> _saveCustomTaskTypes() async {
    try {
      final appDir = await _getAppDir();
      final file = File('$appDir/.freelancing_app_task_types.json');
      final jsonList = _customTaskTypes.map((t) => {
        'name': t.name,
        'displayName': t.displayName,
        'icon': t.icon.codePoint,
        'color': t.color.toARGB32(),
      }).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving custom task types: $e');
    }
  }

  void addCustomTaskType(String name, Color color, IconData icon) async {
    final lowerName = name.toLowerCase().trim().replaceAll(' ', '_');
    if (lowerName.isEmpty) return;
    // Prevent duplicates
    if (allTaskTypes.any((t) => t.name == lowerName)) return;

    final newType = TaskType(
      name: lowerName,
      displayName: name.trim(),
      icon: icon,
      color: color,
    );
    _customTaskTypes.add(newType);
    notifyListeners();
    await _saveCustomTaskTypes();
  }

  void deleteCustomTaskType(String name) async {
    _customTaskTypes.removeWhere((t) => t.name == name);
    notifyListeners();
    await _saveCustomTaskTypes();
  }

  // ──────────────────── CUSTOM CLIENTS ACTIONS ────────────────────

  void addCustomClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_customClients.contains(trimmed)) return;
    _customClients.add(trimmed);
    notifyListeners();
    await _saveCustomClients();
  }

  void deleteCustomClient(String name) async {
    _customClients.remove(name);
    notifyListeners();
    await _saveCustomClients();
  }

  void updateCustomClient(String oldName, String newName) async {
    final oldTrimmed = oldName.trim();
    final newTrimmed = newName.trim();
    if (oldTrimmed.isEmpty || newTrimmed.isEmpty || oldTrimmed == newTrimmed) return;

    // Update in custom clients list
    final idx = _customClients.indexOf(oldTrimmed);
    if (idx != -1) {
      _customClients[idx] = newTrimmed;
      await _saveCustomClients();
    }

    // Update all work entries with this client name locally & push to Supabase
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].clientName == oldTrimmed) {
        final updatedEntry = _entries[i].copyWith(clientName: newTrimmed);
        _entries[i] = updatedEntry;

        try {
          await Supabase.instance.client
              .from('work_entries')
              .update({'client_name': newTrimmed})
              .eq('id', updatedEntry.id);
        } catch (e) {
          debugPrint('Error updating client name in Supabase: $e');
        }
      }
    }

    notifyListeners();
  }

  Future<void> _loadCustomClients() async {
    try {
      final appDir = await _getAppDir();
      final file = File('$appDir/.freelancing_app_clients.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _customClients.clear();
        for (final item in jsonList) {
          _customClients.add(item as String);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading custom clients: $e');
    }
  }

  Future<void> _saveCustomClients() async {
    try {
      final appDir = await _getAppDir();
      final file = File('$appDir/.freelancing_app_clients.json');
      await file.writeAsString(jsonEncode(_customClients));
    } catch (e) {
      debugPrint('Error saving custom clients: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entriesSubscription?.cancel();
    super.dispose();
  }
}
