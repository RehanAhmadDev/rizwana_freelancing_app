import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/work_entry.dart';
import '../state/app_state.dart';
import '../widgets/app_state_provider.dart';
import '../theme/app_theme.dart';

/// Professional Expert-Level PDF Ledger — styled exactly like a premium Excel report.
/// Light blues, greens and purples. Full grid borders, KPI summary cards,
/// zebra-striped rows, accounting double-underline totals, and a clean page footer.
class LedgerPrintScreen extends StatefulWidget {
  /// Pass a month string (e.g. 'April 2025') to show only that month.
  /// Pass null to show ALL entries across all months.
  final String? filterMonth;
  final String? filterClient;

  const LedgerPrintScreen({super.key, this.filterMonth, this.filterClient});

  @override
  State<LedgerPrintScreen> createState() => _LedgerPrintScreenState();
}

class _LedgerPrintScreenState extends State<LedgerPrintScreen> {
  bool _saving = false;

  // ── Color Palette (Light, Professional, Excel-inspired) ──
  static final _headerBg      = PdfColor.fromHex('#EFF6FF'); // Blue 50
  static final _headerText    = PdfColor.fromHex('#1E3A5F'); // Deep navy
  static final _subText       = PdfColor.fromHex('#64748B'); // Slate 500
  static final _accentBlue    = PdfColor.fromHex('#2563EB'); // Blue 600
  static final _accentGreen   = PdfColor.fromHex('#059669'); // Emerald 600
  static final _accentPurple  = PdfColor.fromHex('#7C3AED'); // Violet 600
  static final _tblHeadBg     = PdfColor.fromHex('#DBEAFE'); // Blue 100
  static final _tblHeadText   = PdfColor.fromHex('#1E40AF'); // Blue 800
  static final _tblRowEven    = PdfColors.white;
  static final _tblRowOdd     = PdfColor.fromHex('#F8FAFC'); // Slate 50
  static final _tblBorder     = PdfColor.fromHex('#CBD5E1'); // Slate 300
  static final _tblCellText   = PdfColor.fromHex('#1E293B'); // Slate 900
  static final _totalsBg      = PdfColor.fromHex('#ECFDF5'); // Emerald 50
  static final _totalsText    = PdfColor.fromHex('#065F46'); // Emerald 900
  static final _kpiBlueBg     = PdfColor.fromHex('#DBEAFE'); // Blue 100
  static final _kpiGreenBg    = PdfColor.fromHex('#D1FAE5'); // Emerald 100
  static final _kpiPurpleBg   = PdfColor.fromHex('#EDE9FE'); // Violet 100
  static final _dividerColor  = PdfColor.fromHex('#BFDBFE'); // Blue 200
  static final _footerText    = PdfColor.fromHex('#94A3B8'); // Slate 400

  // ── Formatters ──
  static String _fmtPKR(double val) {
    final intVal = val.toInt();
    final str = intVal.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return 'Rs. $formatted';
  }

  static String _fmtDuration(int h, int m, int s) {
    final List<String> parts = [];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (s > 0 && h == 0) parts.add('${s}s');
    return parts.isEmpty ? '0m' : parts.join(' ');
  }

  // ── Main PDF Generator ──
  Future<pw.Document> _generateLedgerPdf(AppState state) async {
    final pdf = pw.Document();
    final filterMonth = widget.filterMonth;
    final filterClient = widget.filterClient;

    // Filter entries by selected month, or show all if filterMonth is null
    final allEntries = List<WorkEntry>.from(state.allEntries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final entries1 = filterMonth == null
        ? allEntries
        : allEntries.where((e) => e.month == filterMonth).toList();

    final entries = filterClient == null || filterClient == 'All'
        ? entries1
        : entries1.where((e) => e.clientName == filterClient).toList();

    final int totalMins = entries.fold(0, (sum, e) => sum + e.totalMinutes);
    final double totalHours = totalMins / 60.0;
    final double totalEarnings = totalHours * state.hourlyRate;
    final String generatedDate = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
    
    String titlePrefix = filterMonth ?? 'All Months';
    String titleSuffix = (filterClient != null && filterClient != 'All') ? ' - $filterClient' : '';
    final String reportTitle = '$titlePrefix$titleSuffix - Performance Ledger';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 28),
        build: (pw.Context ctx) => [
          _buildHeader(state, generatedDate, reportTitle),
          pw.SizedBox(height: 16),
          _buildDivider(),
          pw.SizedBox(height: 14),
          _buildKpiRow(entries.length, totalHours, totalEarnings, state.hourlyRate),
          pw.SizedBox(height: 18),
          _buildSectionTitle('Detailed Transactions Ledger'),
          pw.SizedBox(height: 7),
          _buildTable(entries, state),
          pw.SizedBox(height: 10),
          _buildLegend(),
        ],
        footer: (pw.Context ctx) => _buildFooter(ctx, state),
      ),
    );

    return pdf;
  }

  // ── HEADER ──
  pw.Widget _buildHeader(AppState state, String date, String title) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _dividerColor, width: 0.8),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Company / Freelancer info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                state.userName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _headerText,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                state.userEmail.isNotEmpty ? state.userEmail : 'Freelance Professional',
                style: pw.TextStyle(fontSize: 8.5, color: _subText),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Freelance Services Provider',
                style: pw.TextStyle(fontSize: 7.5, color: _subText),
              ),
            ],
          ),
          // Right: Document info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _accentBlue,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 5),
              _buildInfoRow('Generated:', date),
              pw.SizedBox(height: 2),
              _buildInfoRow('Billing Rate:', '${_fmtPKR(0).replaceAll('0', _fmtPKR(0).substring(4))}'.isNotEmpty
                  ? '${_fmtPKR(0)} / hr'.replaceFirst('Rs. 0', 'Rs. ${state.hourlyRate.toInt()},00 / hr')
                      .replaceAll(',00', ',000')
                  : '---'),
              pw.SizedBox(height: 2),
              _buildInfoRow('Currency:', 'PKR (Pakistani Rupee)'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 7.5, color: _subText),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: _tblCellText,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDivider() {
    return pw.Container(
      height: 1.5,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_accentBlue, _dividerColor, PdfColors.white],
        ),
      ),
    );
  }

  // ── KPI CARDS ROW ──
  pw.Widget _buildKpiRow(int count, double hours, double earnings, double rate) {
    return pw.Row(
      children: [
        _buildKpiCard(
          icon: 'hrs',
          title: 'TOTAL HOURS LOGGED',
          value: '${hours.toStringAsFixed(1)} hrs',
          subtitle: '${(hours * 60).toInt()} minutes total',
          bg: _kpiBlueBg,
          accent: _accentBlue,
        ),
        pw.SizedBox(width: 10),
        _buildKpiCard(
          icon: 'PKR',
          title: 'GROSS REVENUE (PKR)',
          value: _fmtPKR(earnings),
          subtitle: 'At ${_fmtPKR(rate)}/hr rate',
          bg: _kpiGreenBg,
          accent: _accentGreen,
        ),
        pw.SizedBox(width: 10),
        _buildKpiCard(
          icon: '#',
          title: 'TASK TRANSACTIONS',
          value: '$count Tasks',
          subtitle: 'Avg ${count > 0 ? (hours / count).toStringAsFixed(1) : "0"} hrs/task',
          bg: _kpiPurpleBg,
          accent: _accentPurple,
        ),
      ],
    );
  }

  pw.Widget _buildKpiCard({
    required String icon,
    required String title,
    required String value,
    required String subtitle,
    required PdfColor bg,
    required PdfColor accent,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
          border: pw.Border.all(color: _tblBorder, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Text(icon, style: pw.TextStyle(fontSize: 10, color: accent)),
                pw.SizedBox(width: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 6.5,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 7, color: _subText),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 14, color: _accentBlue),
        pw.SizedBox(width: 7),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _headerText,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── MAIN TABLE ──
  pw.Widget _buildTable(List<WorkEntry> entries, AppState state) {
    return pw.Table(
      border: pw.TableBorder.all(color: _tblBorder, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(54),  // #
        1: const pw.FixedColumnWidth(60),  // Date
        2: const pw.FlexColumnWidth(1.6),  // Client
        3: const pw.FlexColumnWidth(1.2),  // Category
        4: const pw.FlexColumnWidth(2.8),  // Task Description
        5: const pw.FixedColumnWidth(46),  // Duration
        6: const pw.FixedColumnWidth(72),  // Earnings
      },
      children: [
        // ── Header Row ──
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tblHeadBg),
          children: [
            _thCell('#'),
            _thCell('DATE'),
            _thCell('CLIENT NAME'),
            _thCell('CATEGORY'),
            _thCell('TASK / DESCRIPTION'),
            _thCell('TIME', alignRight: true),
            _thCell('EARNINGS (PKR)', alignRight: true),
          ],
        ),

        // ── Data Rows ──
        for (int i = 0; i < entries.length; i++) ...[
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 0 ? _tblRowEven : _tblRowOdd,
            ),
            children: [
              _tdCell('${i + 1}', center: true, muted: true),
              _tdCell(DateFormat('dd MMM yy').format(entries[i].createdAt), center: true, muted: true),
              _tdCell(entries[i].clientName, bold: true),
              _tdCategoryBadge(entries[i].taskType.displayName),
              _tdCell(entries[i].label),
              _tdCell(
                _fmtDuration(entries[i].hours, entries[i].minutes, entries[i].seconds),
                alignRight: true,
                muted: true,
              ),
              _tdEarnings(_fmtPKR((entries[i].totalMinutes / 60.0) * state.hourlyRate)),
            ],
          ),
        ],

        // ── Totals Row ──
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _totalsBg),
          children: [
            _totalsCell(''),
            _totalsCell(''),
            _totalsCell('GRAND TOTAL', span: true),
            _totalsCell(''),
            _totalsCell(''),
            _totalsCell(
              '${(entries.fold(0, (s, e) => s + e.totalMinutes) / 60.0).toStringAsFixed(1)}h',
              alignRight: true,
            ),
            _totalsEarningsCell(_fmtPKR(
              entries.fold(0, (s, e) => s + e.totalMinutes) / 60.0 * state.hourlyRate,
            )),
          ],
        ),
      ],
    );
  }

  // ── Table Cell Builders ──

  pw.Widget _thCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _tblHeadText,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  pw.Widget _tdCell(String text, {
    bool alignRight = false,
    bool center = false,
    bool bold = false,
    bool muted = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : (alignRight ? pw.TextAlign.right : pw.TextAlign.left),
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: muted ? _subText : _tblCellText,
        ),
      ),
    );
  }

  pw.Widget _tdCategoryBadge(String label) {
    // Pick a soft background based on label hash
    final colors = [
      [PdfColor.fromHex('#DBEAFE'), PdfColor.fromHex('#1E40AF')], // Blue
      [PdfColor.fromHex('#D1FAE5'), PdfColor.fromHex('#065F46')], // Green
      [PdfColor.fromHex('#EDE9FE'), PdfColor.fromHex('#5B21B6')], // Purple
      [PdfColor.fromHex('#FEF3C7'), PdfColor.fromHex('#92400E')], // Amber
      [PdfColor.fromHex('#FCE7F3'), PdfColor.fromHex('#9D174D')], // Pink
      [PdfColor.fromHex('#E0F2FE'), PdfColor.fromHex('#0C4A6E')], // Cyan
    ];
    final pair = colors[label.hashCode.abs() % colors.length];
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
        decoration: pw.BoxDecoration(
          color: pair[0],
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 6.5,
            fontWeight: pw.FontWeight.bold,
            color: pair[1],
          ),
        ),
      ),
    );
  }

  pw.Widget _tdEarnings(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: _accentGreen,
        ),
      ),
    );
  }

  pw.Widget _totalsCell(String text, {bool alignRight = false, bool span = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: _totalsText,
        ),
      ),
    );
  }

  pw.Widget _totalsEarningsCell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: const pw.Border(
                top: pw.BorderSide(color: PdfColors.black, width: 0.6),
              ),
            ),
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _totalsText,
              ),
            ),
          ),
          pw.SizedBox(height: 1.5),
          pw.Container(
            height: 0.6,
            color: PdfColors.black,
          ),
        ],
      ),
    );
  }

  // ── LEGEND ──
  pw.Widget _buildLegend() {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          color: _tblRowOdd,
          margin: const pw.EdgeInsets.only(right: 4),
        ),
        pw.Text('Alternating row shading for readability  ', style: pw.TextStyle(fontSize: 6.5, color: _footerText)),
        pw.Container(
          width: 8,
          height: 8,
          color: _totalsBg,
          margin: const pw.EdgeInsets.only(right: 4),
        ),
        pw.Text('Totals row (Emerald highlight)  ', style: pw.TextStyle(fontSize: 6.5, color: _footerText)),
        pw.Text('Amounts in PKR (Pakistani Rupees)', style: pw.TextStyle(fontSize: 6.5, color: _footerText)),
      ],
    );
  }

  // ── FOOTER ──
  pw.Widget _buildFooter(pw.Context ctx, AppState state) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Container(height: 0.5, color: _dividerColor),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${state.userName} - Freelance Performance Ledger',
                style: pw.TextStyle(fontSize: 6.5, color: _footerText),
              ),
              pw.Text(
                'Confidential — For Internal Use Only',
                style: pw.TextStyle(fontSize: 6.5, color: _footerText),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _subText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FLUTTER WIDGET BUILD ──
  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Professional Ledger Statement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _savePdfToDownloads(context, state),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Save PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: PdfPreview(
          build: (format) => _generateLedgerPdf(state).then((doc) => doc.save()),
          canChangeOrientation: false,
          canChangePageFormat: false,
          maxPageWidth: 760,
          previewPageMargin: const EdgeInsets.all(AppTheme.spacingMD),
          pdfFileName:
              'Ledger_${state.userName.replaceAll(' ', '_')}_${DateFormat('MMM_yyyy').format(DateTime.now())}.pdf',
          loadingWidget: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 14),
                Text(
                  'Generating professional ledger...',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          onError: (context, error) => Center(
            child: Text(
              'Error generating statement: $error',
              style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // ── PDF Save to Downloads ──
  Future<void> _savePdfToDownloads(BuildContext context, AppState state) async {
    if (_saving) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final pdf = await _generateLedgerPdf(state);
      final bytes = await pdf.save();
      final filename =
          'Ledger_${state.userName.replaceAll(' ', '_')}_${DateFormat('MMM_yyyy').format(DateTime.now())}.pdf';

      if (Platform.isWindows) {
        final homeDir =
            Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
        if (homeDir.isNotEmpty) {
          final downloadsPath = '$homeDir\\Downloads';
          final file = File('$downloadsPath\\$filename');
          await file.writeAsBytes(bytes);
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PDF saved to Downloads folder!\n$filename',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF059669), // Emerald
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Open Folder',
                  textColor: Colors.white,
                  onPressed: () => Process.run('explorer.exe', [
                    '/select,',
                    '$downloadsPath\\$filename',
                  ]),
                ),
              ),
            );
          }
        }
      } else {
        // Non-Windows: use system share sheet
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
