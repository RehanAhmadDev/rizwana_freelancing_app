import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import '../models/work_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/app_state_provider.dart';
import '../widgets/responsive_layout.dart';
import 'ledger_print_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedMonth;
  String? _selectedClient;
  late final TextEditingController _rateCtrl;
  final FocusNode _rateFocusNode = FocusNode();
  bool _rateCtrlInitialized = false;

  @override
  void dispose() {
    if (_rateCtrlInitialized) {
      _rateCtrl.dispose();
    }
    _rateFocusNode.dispose();
    super.dispose();
  }

  static String _fmtPKR(double val) {
    final intVal = val.toInt();
    final str = intVal.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return 'Rs. $formatted';
  }

  Future<void> _exportReport(BuildContext context, String month, String selectedClient, dynamic state) async {
    final rawEntries = state.allEntries;
    final clientEntries = rawEntries.where((e) {
      final monthOk = month == 'All Months' || e.month == month;
      final clientOk = selectedClient == 'All' || e.clientName == selectedClient;
      return monthOk && clientOk;
    }).toList();

    if (clientEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export for this month.')),
      );
      return;
    }

    final excel = Excel.createExcel();
    final sheetName = 'Performance Ledger';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    // --- Column Widths Configuration (0-based) ---
    sheet.setColumnWidth(0, 8.0);   // A - Index
    sheet.setColumnWidth(1, 16.0);  // B - Date
    sheet.setColumnWidth(2, 25.0);  // C - Client Name
    sheet.setColumnWidth(3, 22.0);  // D - Design Category
    sheet.setColumnWidth(4, 45.0);  // E - Task Description
    sheet.setColumnWidth(5, 15.0);  // F - Time Spent
    sheet.setColumnWidth(6, 22.0);  // G - Earnings (PKR)

    // --- Style Builders ---
    CellStyle getStyle({
      String? bgColor,
      String? fontColor,
      bool bold = false,
      double? fontSize,
      HorizontalAlign align = HorizontalAlign.Left,
    }) {
      final style = CellStyle(
        bold: bold,
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: fontSize?.toInt(),
        horizontalAlign: align,
        verticalAlign: VerticalAlign.Center,
      );
      if (bgColor != null) {
        style.backgroundColor = ExcelColor.fromHexString(bgColor);
      }
      if (fontColor != null) {
        style.fontColor = ExcelColor.fromHexString(fontColor);
      }
      return style;
    }

    // Color Palette matching PDF Premium Theme (Tailwind Light themed)
    const tblHeadBg    = '#DBEAFE'; // Light blue 100
    const tblHeadText  = '#1E40AF'; // Deep blue 800
    const accentBlue   = '#2563EB'; // Blue 600
    const accentGreen  = '#059669'; // Emerald 600
    const accentPurple = '#7C3AED'; // Violet 600
    const textNavy     = '#1E3A5F'; // Navy
    const textSlate    = '#64748B'; // Slate 500
    const rowEvenBg    = '#FFFFFF'; // White
    const rowOddBg     = '#F8FAFC'; // Slate 50 (Very light gray)
    const totalsBg     = '#ECFDF5'; // Emerald 50
    const totalsText   = '#065F46'; // Emerald 900

    void writeCell(String colStr, int rowIdx, CellValue val, CellStyle style) {
      final cell = sheet.cell(CellIndex.indexByString('$colStr$rowIdx'));
      cell.value = val;
      cell.cellStyle = style;
    }

    // --- ROW 2: Header Title Banner ---
    final titleSuffix = selectedClient != 'All' ? ' - $selectedClient' : '';
    writeCell('A', 2, TextCellValue('RIZWANA ADNAN - PERFORMANCE BILLING STATEMENT$titleSuffix'), getStyle(
      bgColor: '#EFF6FF',
      fontColor: textNavy,
      bold: true,
      fontSize: 16,
      align: HorizontalAlign.Center,
    ));
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('G2'));

    // --- ROW 4: Profile & Billing Details ---
    final genDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    writeCell('A', 4, TextCellValue('Freelancer Profile:'), getStyle(bold: true, fontColor: textSlate));
    writeCell('B', 4, TextCellValue(state.userName), getStyle(fontColor: textNavy, bold: true));
    
    writeCell('D', 4, TextCellValue('Billing Rate:'), getStyle(bold: true, fontColor: textSlate));
    writeCell('E', 4, TextCellValue('${_fmtPKR(state.hourlyRate)} / hr'), getStyle(fontColor: textNavy, bold: true));

    writeCell('F', 4, TextCellValue('Generated Date:'), getStyle(bold: true, fontColor: textSlate));
    writeCell('G', 4, TextCellValue(genDate), getStyle(fontColor: textNavy, bold: true));

    // --- ROW 6 & 7: KPI Metrics Panel (Large attractive cards) ---
    final int totalMins = clientEntries.fold(0, (s, e) => s + e.totalMinutes);
    final double totalHours = totalMins / 60.0;
    final double totalEarnings = totalHours * state.hourlyRate;

    // Metric Labels
    writeCell('A', 6, TextCellValue('TOTAL HOURS LOGGED'), getStyle(bgColor: '#F1F5F9', fontColor: textSlate, bold: true, fontSize: 9, align: HorizontalAlign.Center));
    sheet.merge(CellIndex.indexByString('A6'), CellIndex.indexByString('B6'));

    writeCell('C', 6, TextCellValue('GROSS REVENUE (PKR)'), getStyle(bgColor: '#F1F5F9', fontColor: textSlate, bold: true, fontSize: 9, align: HorizontalAlign.Center));
    sheet.merge(CellIndex.indexByString('C6'), CellIndex.indexByString('D6'));

    writeCell('E', 6, TextCellValue('TASK TRANSACTIONS'), getStyle(bgColor: '#F1F5F9', fontColor: textSlate, bold: true, fontSize: 9, align: HorizontalAlign.Center));
    sheet.merge(CellIndex.indexByString('E6'), CellIndex.indexByString('G6'));

    // Metric Values
    writeCell('A', 7, TextCellValue('${totalHours.toStringAsFixed(1)} hrs'), getStyle(bgColor: '#DBEAFE', fontColor: accentBlue, bold: true, fontSize: 13, align: HorizontalAlign.Center));
    sheet.merge(CellIndex.indexByString('A7'), CellIndex.indexByString('B7'));

    writeCell('C', 7, TextCellValue(_fmtPKR(totalEarnings)), getStyle(bgColor: '#D1FAE5', fontColor: accentGreen, bold: true, fontSize: 13, align: HorizontalAlign.Center));
    sheet.merge(CellIndex.indexByString('C7'), CellIndex.indexByString('D7'));

    writeCell('E', 7, TextCellValue('${clientEntries.length} Tasks'), getStyle(bgColor: '#EDE9FE', fontColor: accentPurple, bold: true, fontSize: 13, align: HorizontalAlign.Center));
    sheet.merge(CellIndex.indexByString('E7'), CellIndex.indexByString('G7'));

    // --- ROW 9: Table Section Title ---
    writeCell('A', 9, TextCellValue('Detailed Transactions Ledger'), getStyle(bold: true, fontColor: textNavy, fontSize: 12));

    // --- ROW 10: Styled Excel Table Headers ---
    final headers = ['#', 'DATE', 'CLIENT NAME', 'DESIGN CATEGORY', 'TASK DESCRIPTION', 'TIME SPENT', 'EARNINGS (PKR)'];
    final cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    final headStyle = getStyle(bgColor: tblHeadBg, fontColor: tblHeadText, bold: true, fontSize: 10, align: HorizontalAlign.Center);
    
    for (int colIdx = 0; colIdx < headers.length; colIdx++) {
      writeCell(cols[colIdx], 10, TextCellValue(headers[colIdx]), headStyle);
    }

    // --- ROW 11+: High-Quality Data Rows (Zebra Striped) ---
    int rowIdx = 11;
    for (int i = 0; i < clientEntries.length; i++) {
      final entry = clientEntries[i];
      final isEven = i % 2 == 0;
      final rowBg = isEven ? rowEvenBg : rowOddBg;
      
      final cellStyleLeft = getStyle(bgColor: rowBg, fontColor: '#1E293B', fontSize: 10);
      final cellStyleCenter = getStyle(bgColor: rowBg, fontColor: '#1E293B', fontSize: 10, align: HorizontalAlign.Center);
      final cellStyleRight = getStyle(bgColor: rowBg, fontColor: '#1E293B', fontSize: 10, align: HorizontalAlign.Right);
      
      final dateStr = DateFormat('dd MMM yyyy').format(entry.createdAt);
      final taskMinsStr = _fmtMins(entry.totalMinutes);
      final taskEarnings = (entry.totalMinutes / 60.0) * state.hourlyRate;

      writeCell('A', rowIdx, IntCellValue(i + 1), cellStyleCenter);
      writeCell('B', rowIdx, TextCellValue(dateStr), cellStyleCenter);
      writeCell('C', rowIdx, TextCellValue(entry.clientName), getStyle(bgColor: rowBg, fontColor: '#1E293B', fontSize: 10, bold: true));
      writeCell('D', rowIdx, TextCellValue(entry.taskType.displayName), cellStyleCenter);
      writeCell('E', rowIdx, TextCellValue(entry.label), cellStyleLeft);
      writeCell('F', rowIdx, TextCellValue(taskMinsStr), cellStyleRight);
      writeCell('G', rowIdx, TextCellValue(_fmtPKR(taskEarnings)), getStyle(bgColor: rowBg, fontColor: accentGreen, fontSize: 10, bold: true, align: HorizontalAlign.Right));
      
      rowIdx++;
    }

    // --- GRAND TOTALS ROW WITH ACCREDITED ACCOUNTING ACCENT ---
    final totalsStyleLabel = getStyle(bgColor: totalsBg, fontColor: totalsText, bold: true, fontSize: 10, align: HorizontalAlign.Center);
    final totalsStyleRight = getStyle(bgColor: totalsBg, fontColor: totalsText, bold: true, fontSize: 10, align: HorizontalAlign.Right);

    writeCell('A', rowIdx, TextCellValue('GRAND TOTAL'), totalsStyleLabel);
    sheet.merge(CellIndex.indexByString('A$rowIdx'), CellIndex.indexByString('E$rowIdx'));
    
    final totalHoursStr = '${totalHours.toStringAsFixed(1)} hrs';
    writeCell('F', rowIdx, TextCellValue(totalHoursStr), totalsStyleRight);
    writeCell('G', rowIdx, TextCellValue(_fmtPKR(totalEarnings)), totalsStyleRight);

    // Save and export Excel Workbook
    final bytes = excel.save();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate Excel ledger.')),
      );
      return;
    }

    // Export on Windows
    if (!kIsWeb && Platform.isWindows) {
      try {
        final homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
        if (homeDir.isNotEmpty) {
          final downloadsPath = '$homeDir\\Downloads';
          final sanitizedMonth = month.replaceAll(' ', '_');
          final file = File('$downloadsPath\\${sanitizedMonth}_Performance_Ledger.xlsx');
          await file.writeAsBytes(bytes);
          
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: AppTheme.success),
                    SizedBox(width: 8),
                    Text('Export Successful'),
                  ],
                ),
                content: Text('Your professional Excel ledger for $month has been saved successfully to your Downloads folder!\n\nFile: ${file.path}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Process.run('explorer.exe', ['/select,', file.path]);
                    },
                    child: const Text('Open Downloads Folder'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Windows Excel save error: $e');
      }
    }

    // Export on Mobile
    else {
      try {
        final sanitizedMonth = month.replaceAll(' ', '_');
        await Printing.sharePdf(
          bytes: Uint8List.fromList(bytes),
          filename: '${sanitizedMonth}_Performance_Ledger.xlsx',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing Excel ledger: $e')),
          );
        }
      }
    }
  }

  static String _fmtMins(int m) {
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);

    if (!_rateCtrlInitialized) {
      _rateCtrl = TextEditingController(text: state.hourlyRate.toStringAsFixed(0));
      _rateCtrlInitialized = true;
    } else {
      final rateStr = state.hourlyRate.toStringAsFixed(0);
      if (_rateCtrl.text != rateStr && !_rateFocusNode.hasFocus) {
        _rateCtrl.text = rateStr;
      }
    }
    
    final months = state.allMonths;
    // Add 'All Months' as first option
    final allMonthOptions = ['All Months', ...months];
    final currentMonth = _selectedMonth ?? (months.isNotEmpty ? months.last : '');
    final isAllMonths = currentMonth == 'All Months';
    
    final clientOptions = state.allClients;
    final currentClient = _selectedClient ?? 'All';

    // Local filtering calculations
    final rawEntries = state.allEntries;
    final monthEntries = rawEntries.where((e) {
      return currentMonth.isEmpty || currentMonth == 'All Months' || e.month == currentMonth;
    }).toList();

    final clientEntries = currentClient == 'All'
        ? monthEntries
        : monthEntries.where((e) => e.clientName == currentClient).toList();

    // Key Stats for Selected Month & Client
    final int totalMins = clientEntries.fold(0, (s, e) => s + e.totalMinutes);
    final double totalHours = totalMins / 60.0;
    final double earnings = totalHours * state.hourlyRate;
    
    final double avgMins = clientEntries.isEmpty 
        ? 0.0 
        : totalMins / clientEntries.length;

    // Breakdown for Selected Month & Client
    final breakdown = <TaskType, int>{};
    for (final e in clientEntries) {
      breakdown[e.taskType] = (breakdown[e.taskType] ?? 0) + e.totalMinutes;
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveLayout.isMobile(context) ? AppTheme.spacingMD : AppTheme.spacingXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Reports',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live billing details and performance breakdowns',
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMD),
              // Filter Bar with Dropdowns and Actions
              if (months.isNotEmpty) ...[
                Wrap(
                  spacing: AppTheme.spacingSM,
                  runSpacing: AppTheme.spacingSM,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Month dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: allMonthOptions.contains(currentMonth) ? currentMonth : allMonthOptions.last,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          items: allMonthOptions
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Row(
                                      children: [
                                        if (m == 'All Months') ...[
                                          const Icon(Icons.layers_outlined, size: 14),
                                          const SizedBox(width: 6),
                                        ] else ...[
                                           Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primary),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(m),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedMonth = v);
                            }
                          },
                        ),
                      ),
                    ),
                    // Client dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: clientOptions.contains(currentClient) ? currentClient : 'All',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          items: clientOptions
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Row(
                                      children: [
                                        if (c == 'All') ...[
                                          const Icon(Icons.people_alt_outlined, size: 14),
                                          const SizedBox(width: 6),
                                        ] else ...[
                                           Icon(Icons.person_rounded, size: 14, color: AppTheme.accent),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(c),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedClient = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.grid_on_rounded, color: AppTheme.success),
                      tooltip: isAllMonths
                          ? 'Excel: All Months Report'
                          : 'Excel: $currentMonth Report',
                      onPressed: () => _exportReport(context, currentMonth, currentClient, state),
                    ),
                    IconButton(
                      icon: Icon(Icons.picture_as_pdf_outlined, color: AppTheme.accent),
                      tooltip: isAllMonths
                          ? 'PDF: All Months Ledger'
                          : 'PDF: $currentMonth Ledger',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LedgerPrintScreen(
                              filterMonth: isAllMonths ? null : currentMonth,
                              filterClient: currentClient == 'All' ? null : currentClient,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTheme.spacingLG),

              // If no data
              if (currentMonth.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 72, color: theme.dividerColor),
                        const SizedBox(height: AppTheme.spacingMD),
                        const Text(
                          'No Report Data',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // KPI Metric Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: ResponsiveLayout.valueFor(
                    context: context,
                    mobile: 1,
                    tablet: 3,
                    desktop: 3,
                  ),
                  crossAxisSpacing: AppTheme.spacingMD,
                  mainAxisSpacing: AppTheme.spacingMD,
                  childAspectRatio: ResponsiveLayout.isMobile(context) ? 2.2 : 1.4,
                  children: [
                    // Card 1: Hours
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Hours Logged',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodySmall?.color),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _fmtMins(totalMins),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentMonth,
                                    style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                                  ),
                                ],
                              ),
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    value: (totalHours / 160.0).clamp(0.0, 1.0), // Goal of 160h
                                    strokeWidth: 5,
                                    backgroundColor: AppTheme.primary.withAlpha(26),
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Icon(Icons.timer_outlined, color: AppTheme.primary, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Card 2: Earnings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Est. Earnings',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodySmall?.color),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _fmtPKR(earnings),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: AppTheme.success),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '@ Rs. ',
                                        style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        height: 20,
                                        child: TextFormField(
                                          controller: _rateCtrl,
                                          focusNode: _rateFocusNode,
                                          keyboardType: TextInputType.number,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.success,
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val);
                                            if (parsed != null) {
                                              state.updateHourlyRate(parsed);
                                            }
                                          },
                                        ),
                                      ),
                                      Text(
                                        '/hr rate',
                                        style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_outlined, color: AppTheme.success, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Card 3: Avg Time
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Avg Task Time',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodySmall?.color),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _fmtMins(avgMins.toInt()),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'across ${clientEntries.length} tasks',
                                    style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.bolt_outlined, color: AppTheme.accent, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLG),

                // Main Layout (Grid/Flex depending on device width)
                if (ResponsiveLayout.isDesktop(context))
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildTaskBreakdownCard(theme, breakdown, totalMins)),
                      const SizedBox(width: AppTheme.spacingLG),
                      Expanded(flex: 4, child: _buildMonthlyOverview(theme, state, months, currentClient)),
                    ],
                  )
                else ...[
                  _buildTaskBreakdownCard(theme, breakdown, totalMins),
                  const SizedBox(height: AppTheme.spacingLG),
                  _buildMonthlyOverview(theme, state, months, currentClient),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER: Task type breakdown progress bars ---
  Widget _buildTaskBreakdownCard(ThemeData theme, Map<TaskType, int> breakdown, int totalMins) {
    final sortedBreakdown = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Spent by Design Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (sortedBreakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: Text('No breakdown data available')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedBreakdown.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingMD),
                itemBuilder: (context, index) {
                  final entry = sortedBreakdown[index];
                  final percentage = totalMins == 0 ? 0.0 : entry.value / totalMins;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(entry.key.icon, size: 14, color: entry.key.color),
                              const SizedBox(width: 6),
                              Text(
                                entry.key.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            '${_fmtMins(entry.value)} (${(percentage * 100).toStringAsFixed(1)}%)',
                            style: TextStyle(color: entry.key.color, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: entry.key.color.withAlpha(26),
                          color: entry.key.color,
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

  // --- WIDGET BUILDER: Monthly overview comparison chart list ---
  Widget _buildMonthlyOverview(ThemeData theme, dynamic state, List<String> months, String currentClient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Progress Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (months.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: Text('No monthly data logged yet')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: months.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingMD),
                itemBuilder: (context, index) {
                  final month = months[index];
                  
                  final monthEntries = state.allEntries.where((e) {
                    final monthOk = e.month == month;
                    final clientOk = currentClient == 'All' || e.clientName == currentClient;
                    return monthOk && clientOk;
                  }).toList();

                  final mins = monthEntries.fold(0, (s, e) => s + e.totalMinutes);
                  final double hours = mins / 60.0;
                  final double earnings = hours * state.hourlyRate;
                  
                  // Percentage of typical 160h standard month
                  final percentage = (hours / 160.0).clamp(0.0, 1.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            month,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${_fmtPKR(earnings)} (${_fmtMins(mins)})',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 10,
                          backgroundColor: AppTheme.primary.withAlpha(26),
                          color: AppTheme.primary,
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
