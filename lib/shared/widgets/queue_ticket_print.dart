import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';

// ── Data model passed to the print slip ─────────────────────────────────────

class QueueTicketData {
  final String queueNumber;
  final String patientName;
  final String department;
  final String? doctorName;
  final String? roomName;
  final String? purpose;
  final DateTime issuedAt;

  QueueTicketData({
    required this.queueNumber,
    required this.patientName,
    required this.department,
    this.doctorName,
    this.roomName,
    this.purpose,
    DateTime? issuedAt,
  }) : issuedAt = issuedAt ?? DateTime.now();

  String get departmentLabel =>
      department == 'ENT' ? 'ENT (Ear, Nose & Throat)' : 'EYES (Ophthalmology)';

  String get formattedTime =>
      DateFormat('hh:mm a  •  MMM d, yyyy').format(issuedAt);
}

// ── Public API ───────────────────────────────────────────────────────────────

/// Show a print-preview dialog and allow printing/PDF export of the queue slip.
Future<void> showQueueTicketPrintDialog(
  BuildContext context, {
  required QueueTicketData ticket,
  required bool isDark,
}) {
  return showDialog(
    context: context,
    builder: (_) => _QueueTicketPrintDialog(ticket: ticket, isDark: isDark),
  );
}

// ── Dialog ───────────────────────────────────────────────────────────────────

class _QueueTicketPrintDialog extends StatelessWidget {
  final QueueTicketData ticket;
  final bool isDark;

  const _QueueTicketPrintDialog({
    required this.ticket,
    required this.isDark,
  });

  Color get _deptColor =>
      ticket.department == 'ENT' ? AppColors.entColor : AppColors.eyesColor;

  LinearGradient get _deptGradient =>
      ticket.department == 'ENT' ? AppColors.entGradient : AppColors.eyesGradient;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF131D31) : Colors.white;
    final border = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Dialog header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: _deptGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Queue Ticket',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Print or save as PDF',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                  height: 24,
                  color: border,
                  indent: 24,
                  endIndent: 24),

              // ── Ticket preview ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildTicketPreview(),
              ),

              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                          side: BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => _printTicket(context),
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text(
                          'Print Ticket',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _deptColor,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Visual preview of the physical ticket
  Widget _buildTicketPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header band
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: _deptGradient,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              children: [
                const Text(
                  'OUR LADY OF FATIMA E.E.N.T. CENTER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  ticket.departmentLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Queue number — BIG
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const Text(
                  'QUEUE NUMBER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.queueNumber,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: _deptColor,
                    letterSpacing: 3,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Dashed divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DashedDivider(color: const Color(0xFFCBD5E1)),
          ),

          // Patient details
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                _ticketRow(Icons.person_rounded, 'PATIENT', ticket.patientName),
                if (ticket.doctorName != null &&
                    ticket.doctorName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ticketRow(Icons.medical_services_rounded, 'DOCTOR',
                      ticket.doctorName!),
                ],
                if (ticket.roomName != null &&
                    ticket.roomName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ticketRow(Icons.meeting_room_rounded, 'ROOM',
                      ticket.roomName!),
                ],
                if (ticket.purpose != null &&
                    ticket.purpose!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ticketRow(
                      Icons.assignment_rounded, 'PURPOSE', ticket.purpose!),
                ],
                const SizedBox(height: 8),
                _ticketRow(
                    Icons.access_time_rounded, 'ISSUED', ticket.formattedTime),
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: const Text(
              'Please listen for your number on the TV display.\nSenior citizens & PWDs receive priority service.',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(
          '$label:  ',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── PDF generation & printing ─────────────────────────────────────────────

  // ── Thermal receipt printing (Windows direct text & PDF fallback) ─────────

  Future<bool> _printThermalWindows(String printerName) async {
    if (!Platform.isWindows) return false;
    try {
      final scriptFile = File('lib\\core\\utils\\thermal_printer_windows.ps1');
      final logoFile = File('assets\\logo.jpg');

      final deptTag =
          ticket.department == 'ENT' ? '[ENT CLINIC]' : '[EYE CLINIC]';
      final dateStr = DateFormat('MM/dd hh:mm a').format(ticket.issuedAt);

      final args = [
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.absolute.path,
        '-PrinterName',
        printerName,
        '-LogoPath',
        logoFile.existsSync() ? logoFile.absolute.path : '',
        '-Dept',
        ticket.department,
        '-DeptLabel',
        deptTag,
        '-QueueNo',
        ticket.queueNumber,
        '-PatientName',
        ticket.patientName,
        '-DoctorName',
        ticket.doctorName ?? '',
        '-RoomName',
        ticket.roomName ?? '',
        '-Purpose',
        ticket.purpose ?? '',
        '-IssuedAt',
        dateStr,
      ];

      final res = await Process.run('powershell', args);
      return res.exitCode == 0;
    } catch (e) {
      debugPrint('Thermal Windows direct print error: $e');
      return false;
    }
  }

  Future<void> _printTicket(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // close dialog first

    try {
      // 1. Direct thermal printing on Windows
      if (Platform.isWindows) {
        String targetPrinter = 'POS-58';
        try {
          final printers = await Printing.listPrinters();
          final thermal = printers.where((p) {
            final n = p.name.toUpperCase();
            return n.contains('POS-58') ||
                n.contains('POS') ||
                n.contains('PT-') ||
                n.contains('GOOJPRT') ||
                n.contains('58');
          }).toList();
          if (thermal.isNotEmpty) {
            targetPrinter = thermal.first.name;
          }
        } catch (_) {}

        final printed = await _printThermalWindows(targetPrinter);
        if (printed) {
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('Ticket #${ticket.queueNumber} printed on $targetPrinter!'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      // 2. Fallback to PDF layout / system print dialog
      final pdf = pw.Document();
      final deptHex = ticket.department == 'ENT' ? 0xFF0EA5E9 : 0xFF6366F1;
      final deptPdfColor = PdfColor.fromInt(deptHex);

      const receiptWidth = 58 * PdfPageFormat.mm;
      const receiptMargin = 5 * PdfPageFormat.mm;

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(receiptWidth, double.infinity,
              marginAll: receiptMargin),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: deptPdfColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'OUR LADY OF FATIMA',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'E.E.N.T. CENTER',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      ticket.departmentLabel,
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'QUEUE NUMBER',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                ticket.queueNumber,
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: deptPdfColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 6),
              _pdfRow(ctx, 'PATIENT', ticket.patientName),
              if (ticket.doctorName != null && ticket.doctorName!.isNotEmpty)
                _pdfRow(ctx, 'DOCTOR', ticket.doctorName!),
              if (ticket.roomName != null && ticket.roomName!.isNotEmpty)
                _pdfRow(ctx, 'ROOM', ticket.roomName!),
              if (ticket.purpose != null && ticket.purpose!.isNotEmpty)
                _pdfRow(ctx, 'PURPOSE', ticket.purpose!),
              _pdfRow(ctx, 'ISSUED', ticket.formattedTime),
              pw.SizedBox(height: 10),
              pw.Divider(
                  color: PdfColors.grey300,
                  borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),
              pw.Text(
                'Please wait for your number\nto be called on the TV display.',
                style: const pw.TextStyle(
                  fontSize: 6.5,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Senior citizens & PWDs\nreceive priority service.',
                style: const pw.TextStyle(
                  fontSize: 6,
                  color: PdfColors.grey500,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );

      final pdfBytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Queue_Ticket_${ticket.queueNumber}',
        format: const PdfPageFormat(receiptWidth, double.infinity,
            marginAll: receiptMargin),
      );
    } catch (e) {
      debugPrint('Print ticket error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Print error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  pw.Widget _pdfRow(pw.Context ctx, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 42,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper: dashed divider ────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: color),
      child: const SizedBox(width: double.infinity, height: 1),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashWidth = 5.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
