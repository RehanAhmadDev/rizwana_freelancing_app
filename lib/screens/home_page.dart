import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_state_provider.dart';
import '../widgets/responsive_layout.dart';
import '../models/work_entry.dart';
import 'work_log_screen.dart';
import 'clients_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'add_entry_sheet.dart';


class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  bool _isSearching = false;
  late final TextEditingController _searchCtrl;
  late final TextEditingController _timerClientCtrl;
  late final TextEditingController _timerLabelCtrl;
  TaskType _timerTaskType = TaskType.carousel;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarWidthAnimation;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard_rounded,    'label': 'Dashboard'},
    {'icon': Icons.work_history_rounded, 'label': 'Work Log'},
    {'icon': Icons.people_alt_rounded,   'label': 'Clients'},
    {'icon': Icons.bar_chart_rounded,    'label': 'Reports'},
    {'icon': Icons.settings_rounded,     'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _timerClientCtrl = TextEditingController();
    _timerLabelCtrl = TextEditingController();
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sidebarWidthAnimation = Tween<double>(begin: 240.0, end: 72.0).animate(
      CurvedAnimation(
        parent: _sidebarAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _timerClientCtrl.dispose();
    _timerLabelCtrl.dispose();
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
      if (_isSidebarCollapsed) {
        _sidebarAnimationController.forward();
      } else {
        _sidebarAnimationController.reverse();
      }
    });
  }

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
      _isSearching = false;
      _searchCtrl.clear();
    });
    AppStateProvider.of(context).setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: _buildMobileBody(context),
        tabletBody: _buildTabletBody(context),
        desktopBody: _buildDesktopBody(context),
      ),
      bottomNavigationBar: ResponsiveLayout.isMobile(context)
          ? _buildBottomNavigationBar(context)
          : null,
    );
  }

  // Routes content based on selected nav index
  Widget _buildContent(BuildContext context, {int crossAxisCount = 4}) {
    final isMobile = ResponsiveLayout.isMobile(context);
    switch (_selectedIndex) {
      case 0:
        return isMobile
            ? _buildMobileDashboard(context)
            : _buildDesktopDashboard(context, crossAxisCount: crossAxisCount);
      case 1:
        return const WorkLogScreen();
      case 2:
        return const ClientsScreen();
      case 3:
        return const ReportsScreen();
      case 4:
        return SettingsScreen(
          onToggleTheme: widget.onToggleTheme,
          isDarkMode: widget.isDarkMode,
        );
      default:
        return isMobile
            ? _buildMobileDashboard(context)
            : _buildDesktopDashboard(context, crossAxisCount: crossAxisCount);
    }
  }

  // --- DEDICATED DESKTOP DASHBOARD ---
  Widget _buildDesktopDashboard(BuildContext context, {int crossAxisCount = 4}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        crossAxisCount >= 4 ? AppTheme.spacingXL : AppTheme.spacingMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: AppTheme.spacingLG),
          if (crossAxisCount >= 4)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildGoalProgressCard(context)),
                const SizedBox(width: AppTheme.spacingLG),
                Expanded(child: _buildLiveTimerCard(context)),
              ],
            )
          else ...[
            _buildGoalProgressCard(context),
            const SizedBox(height: AppTheme.spacingLG),
            _buildLiveTimerCard(context),
          ],
          const SizedBox(height: AppTheme.spacingLG),
          _buildStatsGrid(crossAxisCount: crossAxisCount),
          const SizedBox(height: AppTheme.spacingLG),
          if (crossAxisCount >= 4)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildChartCard(context)),
                const SizedBox(width: AppTheme.spacingLG),
                Expanded(flex: 3, child: _buildRecentActivity(context)),
              ],
            )
          else ...[
            _buildChartCard(context),
            const SizedBox(height: AppTheme.spacingLG),
            _buildRecentActivity(context),
          ],
        ],
      ),
    );
  }

  // --- DEDICATED MOBILE DASHBOARD ---
  Widget _buildMobileDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: AppTheme.spacingLG),
          _buildGoalProgressCard(context),
          const SizedBox(height: AppTheme.spacingMD),
          _buildLiveTimerCard(context),
          const SizedBox(height: AppTheme.spacingLG),
          // Flexible row-column combo layout for mobile stats (zero bottom overflows)
          _buildMobileStatsColumn(),
          const SizedBox(height: AppTheme.spacingLG),
          _buildChartCard(context),
          const SizedBox(height: AppTheme.spacingLG),
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  // --- FLEXIBLE 2x2 MOBILE STATS LAYOUT ---
  Widget _buildMobileStatsColumn() {
    final state = AppStateProvider.of(context);
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Hours This Month',
        'value': state.totalHoursLatestMonth.isEmpty ? '0h' : state.totalHoursLatestMonth,
        'subtitle': state.latestMonth,
        'icon': Icons.timer_outlined,
        'color': AppTheme.primary,
      },
      {
        'title': 'Tasks This Month',
        'value': '${state.totalTasksLatestMonth}',
        'subtitle': 'entries logged',
        'icon': Icons.task_alt_rounded,
        'color': AppTheme.accent,
      },
      {
        'title': 'Top Task Type',
        'value': state.topTaskTypeLatestMonth,
        'subtitle': 'most worked',
        'icon': Icons.star_rounded,
        'color': AppTheme.success,
      },
      {
        'title': 'Total Clients',
        'value': '${state.totalClientsCount}',
        'subtitle': '${state.totalEntriesAllTime} entries total',
        'icon': Icons.people_outline_rounded,
        'color': AppTheme.warning,
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMobileStatCard(stats[0])),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(child: _buildMobileStatCard(stats[1])),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMD),
        Row(
          children: [
            Expanded(child: _buildMobileStatCard(stats[2])),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(child: _buildMobileStatCard(stats[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(Map<String, dynamic> stat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stat['title'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXS),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withAlpha(26),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Icon(stat['icon'], color: stat['color'], size: 16),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              stat['value'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              stat['subtitle'],
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- MOBILE BODY ---
  Widget _buildMobileBody(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, showSidebarToggle: false),
          Expanded(child: _buildContent(context, crossAxisCount: 2)),
        ],
      ),
    );
  }

  // --- TABLET BODY ---
  Widget _buildTabletBody(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(context),
        Expanded(
          child: Column(
            children: [
              _buildHeader(context, showSidebarToggle: true),
              Expanded(child: _buildContent(context, crossAxisCount: 2)),
            ],
          ),
        ),
      ],
    );
  }

  // --- DESKTOP BODY ---
  Widget _buildDesktopBody(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(context),
        Expanded(
          child: Column(
            children: [
              _buildHeader(context, showSidebarToggle: true),
              Expanded(child: _buildContent(context, crossAxisCount: 4)),
            ],
          ),
        ),
      ],
    );
  }

  // --- HEADER VIEW ---
  Widget _buildHeader(BuildContext context, {required bool showSidebarToggle}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    if (_isSearching) {
      return Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 1.0),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchCtrl.clear();
                });
                state.setSearchQuery('');
              },
              tooltip: 'Exit Search',
            ),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Search tasks, clients, notes...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchCtrl.clear();
                            });
                            state.setSearchQuery('');
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {}); // to show/hide clear icon
                  state.setSearchQuery(val);
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          if (showSidebarToggle) ...[
            IconButton(
              icon: Icon(
                _isSidebarCollapsed
                    ? Icons.menu_open_rounded
                    : Icons.menu_rounded,
                color: theme.iconTheme.color,
              ),
              onPressed: _toggleSidebar,
              tooltip: 'Toggle Navigation Menu',
            ),
            const SizedBox(width: AppTheme.spacingSM),
          ],
          // Search Field (Shown inline in Desktop/Tablet)
          if (!ResponsiveLayout.isMobile(context))
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => state.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search tasks, clients, notes...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: isDark
                        ? AppTheme.darkBg.withAlpha(128)
                        : AppTheme.lightBg,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                              });
                              state.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            )
          else ...[
            Icon(
              Icons.blur_on_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
            const SizedBox(width: AppTheme.spacingSM),
            const Text(
              'Rizwana App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
          const Spacer(),
          // Search Button (Mobile can trigger searching view overlay)
          if (ResponsiveLayout.isMobile(context)) ...[
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              tooltip: 'Search logs',
            ),
            const SizedBox(width: AppTheme.spacingSM),
          ],
          // Dark Mode Toggle
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: theme.iconTheme.color,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
    );
  }

  // --- WELCOME SECTION ---
  Widget _buildWelcomeSection() {
    final state = AppStateProvider.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${state.userName} 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          'Here is what is happening with ${state.userName} Freelancing App today. View live metrics below.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // --- SIDEBAR (Desktop / Tablet) ---
  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    return AnimatedBuilder(
      animation: _sidebarWidthAnimation,
      builder: (context, child) {
        return Container(
          width: _sidebarWidthAnimation.value,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              right: BorderSide(color: theme.dividerColor, width: 1.0),
            ),
          ),
          child: Column(
            children: [
              // Logo Header
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
                child: Row(
                  mainAxisAlignment: _isSidebarCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.electric_car_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                    if (!_isSidebarCollapsed) ...[
                      const SizedBox(width: AppTheme.spacingSM),
                      const Text(
                        'Rizwana Freelancing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.spacingMD),
              // Navigation Items
              Expanded(
                child: ListView.builder(
                  itemCount: _navItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSM),
                  itemBuilder: (context, index) {
                    final item = _navItems[index];
                    final isSelected = _selectedIndex == index;

                    return Padding(
                      key: ValueKey(item['label']),
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                      child: InkWell(
                        onTap: () => _changeTab(index),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMD,
                            horizontal: AppTheme.spacingSM,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(26)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.primary.withAlpha(51),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: _isSidebarCollapsed
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(
                                item['icon'],
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.iconTheme.color?.withAlpha(178),
                                size: 22,
                              ),
                              if (!_isSidebarCollapsed) ...[
                                const SizedBox(width: AppTheme.spacingMD),
                                Text(
                                  item['label'],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // User Profile Footer info
              if (!_isSidebarCollapsed) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primary,
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              state.userEmail,
                              style: TextStyle(
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- STATS CARDS GRID (Live from AppState) ---
  Widget _buildStatsGrid({required int crossAxisCount}) {
    final state = AppStateProvider.of(context);
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Hours This Month',
        'value': state.totalHoursLatestMonth.isEmpty ? '0h' : state.totalHoursLatestMonth,
        'subtitle': state.latestMonth,
        'icon': Icons.timer_outlined,
        'color': AppTheme.primary,
      },
      {
        'title': 'Tasks This Month',
        'value': '${state.totalTasksLatestMonth}',
        'subtitle': 'entries logged',
        'icon': Icons.task_alt_rounded,
        'color': AppTheme.accent,
      },
      {
        'title': 'Top Task Type',
        'value': state.topTaskTypeLatestMonth,
        'subtitle': 'most worked',
        'icon': Icons.star_rounded,
        'color': AppTheme.success,
      },
      {
        'title': 'Total Clients',
        'value': '${state.totalClientsCount}',
        'subtitle': '${state.totalEntriesAllTime} entries total',
        'icon': Icons.people_outline_rounded,
        'color': AppTheme.warning,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppTheme.spacingMD,
        mainAxisSpacing: AppTheme.spacingMD,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stat['title'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSM),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withAlpha(26),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Icon(stat['icon'], color: stat['color'], size: 20),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['value'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      stat['subtitle'],
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // --- PREMIUM CANVAS CHART CARD ---
  Widget _buildChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue Analytics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Monthly statistics and overall trend overview',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                        maxLines: ResponsiveLayout.isMobile(context) ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                // Dropdown menu button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSM, vertical: AppTheme.spacingXS),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: const Row(
                    children: [
                      Text('This Year', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLG),
            // Custom Painted Canvas Chart
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(
                  isDarkMode: isDark,
                  gridColor: theme.dividerColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Bookings Revenue', AppTheme.primary),
                const SizedBox(width: AppTheme.spacingLG),
                _buildLegendItem('Inventory Cost', AppTheme.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // --- RECENT WORK ENTRIES (Live from AppState) ---
  Widget _buildRecentActivity(BuildContext context) {
    final theme = Theme.of(context);
    final state = AppStateProvider.of(context);
    // Show latest 4 entries across all months
    final recent = state.allEntries.reversed.take(4).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Work Entries',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => _changeTab(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (recent.isEmpty)
              Center(
                child: Text(
                  'No entries yet. Go to Work Log to add.',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, _) =>
                    Divider(color: theme.dividerColor, height: 20),
                itemBuilder: (context, index) {
                  final e = recent[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: e.taskType.color.withAlpha(26),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        child: Icon(e.taskType.icon,
                            color: e.taskType.color, size: 18),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${e.taskType.displayName} · ${e.clientName} · ${e.month}',
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: e.taskType.color.withAlpha(20),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border:
                              Border.all(color: e.taskType.color.withAlpha(51)),
                        ),
                        child: Text(
                          e.formattedTime,
                          style: TextStyle(
                            color: e.taskType.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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

  Widget _buildGoalProgressCard(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);
    
    final month = state.latestMonth.isEmpty ? 'May 2026' : state.latestMonth;
    final totalEarned = state.totalEarningsForMonth(month);
    final target = state.monthlyTargetGoal;
    final double percent = target > 0 ? (totalEarned / target).clamp(0.0, 1.0) : 0.0;
    final displayPercent = (percent * 100).toStringAsFixed(0);
    final isGoalAchieved = totalEarned >= target;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          gradient: isGoalAchieved 
              ? LinearGradient(
                  colors: [AppTheme.success.withAlpha(26), AppTheme.success.withAlpha(51)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isGoalAchieved ? AppTheme.success : AppTheme.primary).withAlpha(26),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Text(
                          isGoalAchieved ? '🎉 GOAL CRUSHED' : '📈 MONTHLY PROGRESS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isGoalAchieved ? AppTheme.success : AppTheme.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    'Rs. ${totalEarned.toStringAsFixed(0)} earned of Rs. ${target.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isGoalAchieved 
                        ? 'Congratulations! You have achieved your goal for $month!'
                        : 'You are $displayPercent% on track to hit your monthly target in $month.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            // Progress Indicator Stack
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 6,
                      backgroundColor: theme.dividerColor,
                      color: isGoalAchieved ? AppTheme.success : AppTheme.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Center(
                    child: Text(
                      '$displayPercent%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isGoalAchieved ? AppTheme.success : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTimerCard(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);

    if (!state.isTimerActive) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    'Quick Live Tracker',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: AppTheme.spacingMD),
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(text: _timerClientCtrl.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final clients = state.allClients.where((c) => c != 'All').toList();
                        if (textEditingValue.text.isEmpty) {
                          return clients;
                        }
                        return clients.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _timerClientCtrl.text = selection;
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
                              width: 250,
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
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onSubmitted: (v) => onFieldSubmitted(),
                          decoration: const InputDecoration(
                            hintText: 'Client name',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 16),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (val) {
                            _timerClientCtrl.text = val;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<TaskType>(
                      value: _timerTaskType,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: state.allTaskTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(t.icon, size: 14, color: t.color),
                                    const SizedBox(width: 6),
                                    Text(t.displayName, style: TextStyle(fontSize: 12, color: t.color)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _timerTaskType = v;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _timerLabelCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Session Description (e.g. Day 1, Redesign)',
                        prefixIcon: Icon(Icons.label_outline_rounded, size: 16),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final client = _timerClientCtrl.text.trim();
                      final label = _timerLabelCtrl.text.trim();
                      state.startTimer(
                        client.isEmpty ? 'Client' : client,
                        _timerTaskType,
                        label.isEmpty ? 'Work Log' : label,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final totalSecs = state.timerSeconds;
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    final s = totalSecs % 60;
    final durationStr = "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          children: [
            Row(
              children: [
                const _PulsingDot(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ Active Work Session',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        'Client: ${state.timerClient} · ${state.timerTaskType.displayName}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  durationStr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Discard Session?'),
                        content: const Text('Are you sure you want to stop and discard this session without logging the time?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              state.resetTimer();
                            },
                            child: const Text('Discard', style: TextStyle(color: AppTheme.danger)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                  label: const Text('Discard', style: TextStyle(color: AppTheme.danger)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (state.isTimerPaused) {
                      state.resumeTimer();
                    } else {
                      state.pauseTimer();
                    }
                  },
                  icon: Icon(state.isTimerPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18),
                  label: Text(state.isTimerPaused ? 'Resume' : 'Pause'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final capturedSeconds = state.timerSeconds;
                    final client = state.timerClient;
                    final type = state.timerTaskType;
                    final label = state.timerLabel;
                    
                    state.resetTimer();
                    _timerClientCtrl.clear();
                    _timerLabelCtrl.clear();

                    final ch = capturedSeconds ~/ 3600;
                    final cm = (capturedSeconds % 3600) ~/ 60;
                    final cs = capturedSeconds % 60;

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      builder: (_) => AddEntrySheet(
                        appState: state,
                        initialMonth: state.latestMonth.isEmpty ? 'May 2026' : state.latestMonth,
                        prefilledClient: client,
                        prefilledTaskType: type,
                        prefilledLabel: label,
                        prefilledHours: ch,
                        prefilledMinutes: cm,
                        prefilledSeconds: cs,
                      ),
                    );
                  },
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Stop & Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // --- MOBILE BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _changeTab,
      destinations: _navItems
          .map((item) => NavigationDestination(
                icon: Icon(item['icon']),
                label: item['label'],
              ))
          .toList(),
    );
  }
}

/// Custom line chart painter simulating sleek glassmorphic visualizations
class LineChartPainter extends CustomPainter {
  final bool isDarkMode;
  final Color gridColor;

  LineChartPainter({required this.isDarkMode, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintLine1 = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintLine2 = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double stepX = size.width / 5;
    
    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Points for Revenue Line Chart
    final List<Offset> points1 = [
      Offset(0, size.height * 0.75),
      Offset(stepX, size.height * 0.60),
      Offset(stepX * 2, size.height * 0.40),
      Offset(stepX * 3, size.height * 0.45),
      Offset(stepX * 4, size.height * 0.20),
      Offset(size.width, size.height * 0.10),
    ];

    // Points for Costs Line Chart
    final List<Offset> points2 = [
      Offset(0, size.height * 0.90),
      Offset(stepX, size.height * 0.85),
      Offset(stepX * 2, size.height * 0.70),
      Offset(stepX * 3, size.height * 0.68),
      Offset(stepX * 4, size.height * 0.55),
      Offset(size.width, size.height * 0.48),
    ];

    // Draw Smooth Line 1 Path
    final path1 = Path()..moveTo(points1[0].dx, points1[0].dy);
    for (int i = 0; i < points1.length - 1; i++) {
      final xc = (points1[i].dx + points1[i + 1].dx) / 2;
      final yc = (points1[i].dy + points1[i + 1].dy) / 2;
      path1.quadraticBezierTo(points1[i].dx, points1[i].dy, xc, yc);
    }
    path1.lineTo(points1.last.dx, points1.last.dy);
    canvas.drawPath(path1, paintLine1);

    // Draw Smooth Line 2 Path
    final path2 = Path()..moveTo(points2[0].dx, points2[0].dy);
    for (int i = 0; i < points2.length - 1; i++) {
      final xc = (points2[i].dx + points2[i + 1].dx) / 2;
      final yc = (points2[i].dy + points2[i + 1].dy) / 2;
      path2.quadraticBezierTo(points2[i].dx, points2[i].dy, xc, yc);
    }
    path2.lineTo(points2.last.dx, points2.last.dy);
    canvas.drawPath(path2, paintLine2);

    // Draw Area under Line 1 for a rich gradient effect
    final areaPath1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(points1[0].dx, points1[0].dy);
    for (int i = 0; i < points1.length - 1; i++) {
      final xc = (points1[i].dx + points1[i + 1].dx) / 2;
      final yc = (points1[i].dy + points1[i + 1].dy) / 2;
      areaPath1.quadraticBezierTo(points1[i].dx, points1[i].dy, xc, yc);
    }
    areaPath1.lineTo(size.width, points1.last.dy);
    areaPath1.lineTo(size.width, size.height);
    areaPath1.close();

    final paintArea1 = Paint()
      ..shader = LinearGradient(
        colors: [AppTheme.primary.withAlpha(51), AppTheme.primary.withAlpha(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawPath(areaPath1, paintArea1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.3 + 0.7 * _ctrl.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withAlpha((128 * _ctrl.value).toInt()),
                blurRadius: 6 + 6 * _ctrl.value,
                spreadRadius: 1 + 2 * _ctrl.value,
              )
            ],
          ),
        );
      },
    );
  }
}
