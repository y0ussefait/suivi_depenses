import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class PdfService {
  static Future<void> generatePdf(List<Transaction> transactions, String currency) async {
    final pdf = pw.Document();
    
    // On charge une police compatible (nécessaire pour printing)
    await PdfGoogleFonts.nunitoExtraLight();

    double totalRevenus = 0;
    double totalDepenses = 0;
    for (var t in transactions) {
      if (t.estDepense) totalDepenses += t.montant;
      else totalRevenus += t.montant;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Rapport Budgétaire', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Revenus: +${totalRevenus.toStringAsFixed(2)} $currency', style: const pw.TextStyle(color: PdfColors.green)),
                  pw.Text('Dépenses: -${totalDepenses.toStringAsFixed(2)} $currency', style: const pw.TextStyle(color: PdfColors.red)),
                  pw.Text('Solde: ${(totalRevenus - totalDepenses).toStringAsFixed(2)} $currency', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Correction de la dépréciation Table.fromTextArray -> TableHelper.fromTextArray
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Date', 'Catégorie', 'Description', 'Montant'],
              data: transactions.map((t) {
                return [
                  DateFormat('dd/MM/yyyy').format(t.date),
                  t.category,
                  t.description,
                  '${t.estDepense ? '-' : '+'} ${t.montant.toStringAsFixed(2)} $currency',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}