import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:planner/domain/entities/result.dart';
import 'package:planner/features/auth/presentation/providers/user_provider.dart';

class PdfService {
  static Future<void> exportResultsToPdf(List<ExamResult> results, UserData? user, double average) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.outfitBold();
    final fontRegular = await PdfGoogleFonts.outfitRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PLANNER', style: pw.TextStyle(font: font, fontSize: 24, color: PdfColors.indigo900)),
                      pw.Text('Relevé de Notes Académique', style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.indigo900,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text('P', style: pw.TextStyle(font: font, fontSize: 28, color: PdfColors.white)),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // User Info Card
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INFORMATIONS ÉTUDIANT', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(user?.fullName ?? 'N/A', style: pw.TextStyle(font: font, fontSize: 16)),
                            pw.Text('ID: ${user?.studentId ?? "N/A"}', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Niveau: ${user?.level ?? "N/A"}', style: pw.TextStyle(font: font, fontSize: 14)),
                            pw.Text('Moyenne: ${average.toStringAsFixed(2)} / 20', style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.indigo700)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Table
              pw.Text('DÉTAIL DES RÉSULTATS', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.indigo900)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                    children: [
                      _buildTableCell('Matière', font, isHeader: true),
                      _buildTableCell('Note', font, isHeader: true),
                      _buildTableCell('Crédits', font, isHeader: true),
                      _buildTableCell('Semestre', font, isHeader: true),
                    ],
                  ),
                  // Data Rows
                  ...results.map((r) => pw.TableRow(
                    children: [
                      _buildTableCell(r.subject, fontRegular),
                      _buildTableCell(r.grade.toString(), fontRegular, color: r.grade >= 10 ? PdfColors.green700 : PdfColors.red700),
                      _buildTableCell(r.credits?.toString() ?? '-', fontRegular),
                      _buildTableCell(r.semester ?? '-', fontRegular),
                    ],
                  )),
                ],
              ),
              
              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Généré par Planner App', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Show Print/Share Preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relevé_Notes_${user?.studentId ?? "export"}.pdf',
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
