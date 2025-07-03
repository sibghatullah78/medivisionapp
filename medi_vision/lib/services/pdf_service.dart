import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../screens/documents/MedicineScreen/model/medicines_model.dart';

class PDFService {
  static Future<File> generatePDF({
    required List<Medicine> medicines,
    File? imageFile,
    required String fileName,
    String? doctorName,
    String? patientName,
    String? extractedText,
  }) async {
    try {
      final pdf = pw.Document();

      // Handle image safely
      pw.MemoryImage? pdfImage;
      if (imageFile != null) {
        try {
          final imageBytes = await imageFile.readAsBytes();
          pdfImage = pw.MemoryImage(imageBytes);
        } catch (e, stackTrace) {
          debugPrint('Error loading image for PDF: $e\n$stackTrace');
          // Continue without image if there's an error
        }
      }

      // Define styles
      final titleStyle = pw.TextStyle(
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue800,
      );
      final headerStyle = pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue700,
      );
      final subtitleStyle = pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue600,
      );
      final bodyStyle = pw.TextStyle(
        fontSize: 12,
        color: PdfColors.grey800,
      );
      final boldBodyStyle = pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey900,
      );
      final footerStyle = pw.TextStyle(
        fontSize: 10,
        color: PdfColors.grey600,
      );
      final tableHeaderStyle = pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );

      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          header: (pw.Context context) => _buildHeader(
            patientName: patientName,
            doctorName: doctorName,
            titleStyle: titleStyle,
            bodyStyle: bodyStyle,
            image: pdfImage,
          ),
          footer: (pw.Context context) => _buildFooter(
            context: context,
            footerStyle: footerStyle,
          ),
          build: (pw.Context context) => _buildContent(
            medicines: medicines,
            extractedText: extractedText,
            headerStyle: headerStyle,
            subtitleStyle: subtitleStyle,
            boldBodyStyle: boldBodyStyle,
            bodyStyle: bodyStyle,
            tableHeaderStyle: tableHeaderStyle,
          ),
        ),
      );

      return await _savePDF(pdf, fileName);
    } catch (e, stackTrace) {
      debugPrint('PDF generation error: $e\n$stackTrace');
      throw PDFGenerationException('Failed to generate PDF: $e', stackTrace);
    }
  }

  static pw.Widget _buildHeader({
    required String? patientName,
    required String? doctorName,
    required pw.TextStyle titleStyle,
    required pw.TextStyle bodyStyle,
    required pw.MemoryImage? image,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MEDICAL PRESCRIPTION', style: titleStyle),
                pw.SizedBox(height: 4),
                if (doctorName != null && doctorName.isNotEmpty)
                  pw.Text('Prescribed by: Dr. $doctorName', style: bodyStyle),
              ],
            ),
            if (image != null)
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  image: pw.DecorationImage(
                    image: image,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
        if (patientName != null && patientName.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text('Patient: $patientName', style: bodyStyle),
          ),
        pw.Divider(thickness: 1.5, color: PdfColors.blue400),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required pw.TextStyle footerStyle,
  }) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}',
              style: footerStyle,
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: footerStyle,
            ),
          ],
        ),
      ],
    );
  }

  static List<pw.Widget> _buildContent({
    required List<Medicine> medicines,
    required String? extractedText,
    required pw.TextStyle headerStyle,
    required pw.TextStyle subtitleStyle,
    required pw.TextStyle boldBodyStyle,
    required pw.TextStyle bodyStyle,
    required pw.TextStyle tableHeaderStyle,
  }) {
    final content = <pw.Widget>[];

    // Add medication details section
    content.addAll([
      pw.Text('PRESCRIBED MEDICATIONS', style: headerStyle),
      pw.SizedBox(height: 12),
      _buildMedicineTable(medicines, tableHeaderStyle, boldBodyStyle, bodyStyle),
      pw.SizedBox(height: 20),
    ]);

    // Add additional info if any medicine has it
    if (medicines.any((med) =>
    (med.instructions?.isNotEmpty ?? false) ||
        (med.uses?.isNotEmpty ?? false) ||
        (med.precautions?.isNotEmpty ?? false) ||
        (med.warnings?.isNotEmpty ?? false) ||
        (med.sideEffects != null))) {
      content.addAll([
        pw.Text('MEDICATION DETAILS', style: headerStyle),
        pw.SizedBox(height: 12),
        _buildAdditionalInfoList(medicines, subtitleStyle, boldBodyStyle, bodyStyle),
        pw.SizedBox(height: 20),
      ]);
    }

    // Add extracted text if available
    if (extractedText != null && extractedText.isNotEmpty) {
      content.addAll([
        pw.Text('ADDITIONAL NOTES', style: headerStyle),
        pw.SizedBox(height: 12),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(extractedText, style: bodyStyle),
        ),
      ]);
    }

    return content;
  }

  static pw.Widget _buildMedicineTable(
      List<Medicine> medicines,
      pw.TextStyle headerStyle,
      pw.TextStyle boldStyle,
      pw.TextStyle regularStyle,
      ) {
    if (medicines.isEmpty) {
      return pw.Text('No medications prescribed', style: regularStyle);
    }

    return pw.TableHelper.fromTextArray(
      border: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.blue600,
        borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
      ),
      headerStyle: headerStyle,
      headerPadding: const pw.EdgeInsets.all(8),
      cellPadding: const pw.EdgeInsets.all(8),
      cellStyle: regularStyle,
      oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5), // Name
        1: const pw.FlexColumnWidth(2.5), // Generic Name
        2: const pw.FlexColumnWidth(2), // Dosage
        3: const pw.FlexColumnWidth(1.5), // Frequency
        4: const pw.FlexColumnWidth(1.5), // Strength
      },
      headers: ['Name', 'Generic Name', 'Dosage (Adults)', 'Frequency', 'Strength'],
      data: medicines.map((med) => [
        pw.Text(med.name, style: boldStyle),
        med.genericName ?? '--',
        med.dosage?.adults ?? '--',
        med.frequency ?? '--',
        med.strength ?? '--',
      ]).toList(),
    );
  }

  static pw.Widget _buildAdditionalInfoList(
      List<Medicine> medicines,
      pw.TextStyle subtitleStyle,
      pw.TextStyle boldStyle,
      pw.TextStyle regularStyle,
      ) {
    final items = <pw.Widget>[];

    for (final med in medicines) {
      // Only add medicine section if it has any additional info
      final hasInfo = (med.instructions?.isNotEmpty ?? false) ||
          (med.uses?.isNotEmpty ?? false) ||
          (med.precautions?.isNotEmpty ?? false) ||
          (med.warnings?.isNotEmpty ?? false) ||
          (med.sideEffects != null);

      if (hasInfo) {
        items.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(med.name.toUpperCase(), style: subtitleStyle),
              pw.SizedBox(height: 8),
              if (med.instructions?.isNotEmpty ?? false)
                _buildInfoCard('Instructions', med.instructions! as List<String>, boldStyle, regularStyle),
              if (med.uses?.isNotEmpty ?? false)
                _buildInfoCard('Uses', med.uses!, boldStyle, regularStyle),
              if (med.precautions?.isNotEmpty ?? false)
                _buildInfoCard('Precautions', med.precautions!, boldStyle, regularStyle),
              if (med.warnings?.isNotEmpty ?? false)
                _buildInfoCard('Warnings', med.warnings!, boldStyle, regularStyle),
              if (med.sideEffects != null) ...[
                if (med.sideEffects!.common?.isNotEmpty ?? false)
                  _buildInfoCard('Common Side Effects', med.sideEffects!.common!, boldStyle, regularStyle),
                if (med.sideEffects!.serious?.isNotEmpty ?? false)
                  _buildInfoCard('Serious Side Effects', med.sideEffects!.serious!, boldStyle, regularStyle),
              ],
              pw.SizedBox(height: 12),
            ],
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  static pw.Widget _buildInfoCard(
      String title,
      List<String> content,
      pw.TextStyle boldStyle,
      pw.TextStyle regularStyle,
      ) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: boldStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            content.join('\n• '),
            style: regularStyle,
          ),
        ],
      ),
    );
  }

  static Future<File> _savePDF(pw.Document pdf, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedFileName = _sanitizeFileName(fileName);
      final file = File('${dir.path}/$sanitizedFileName.pdf');
      await file.create(recursive: true);
      await file.writeAsBytes(await pdf.save());
      debugPrint('PDF saved to: ${file.path}');
      return file;
    } catch (e, stackTrace) {
      debugPrint('Error saving PDF: $e\n$stackTrace');
      throw PDFGenerationException('Failed to save PDF: $e', stackTrace);
    }
  }

  static String _sanitizeFileName(String fileName, {bool addTimestamp = true}) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final baseName = fileName.isEmpty
        ? 'prescription'
        : fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return addTimestamp ? '${baseName}_$timestamp' : baseName;
  }
}

class PDFGenerationException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  PDFGenerationException(this.message, [this.stackTrace]);

  @override
  String toString() => 'PDFGenerationException: $message';
}