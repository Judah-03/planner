import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:planner/domain/entities/exam.dart';

class PdfExportService {
  static Future<void> exportExams(List<Exam> exams) async {
    final pdf = pw.Document();

    // Tri des examens par date
    final sortedExams = List<Exam>.from(exams)..sort((a, b) => a.date.compareTo(b.date));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Emploi du Temps des Examens', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              if (sortedExams.isEmpty)
                pw.Center(child: pw.Text('Aucun examen prévu.'))
              else
                pw.Table.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  cellAlignment: pw.Alignment.centerLeft,
                  data: <List<String>>[
                    <String>['Matière', 'Date', 'Heure', 'Salle', 'Enseignant'],
                    ...sortedExams.map((exam) => [
                      exam.subject,
                      DateFormat('dd/MM/yyyy').format(exam.date),
                      exam.time,
                      exam.room,
                      exam.teacher,
                    ]),
                  ],
                ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Généré par Planner App', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Examens_Emploi_du_temps.pdf',
    );
  }
}
