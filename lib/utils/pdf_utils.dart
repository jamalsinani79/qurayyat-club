import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../services/team_service.dart';

Future<void> printPlayers(
  List players, {
  required String rawLogoPath,
}) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  final ByteData logoClubData = await rootBundle.load('assets/images/quriyat_logo.png');
  final Uint8List logoClubBytes = logoClubData.buffer.asUint8List();
  final pw.ImageProvider clubLogo = pw.MemoryImage(logoClubBytes);

  String fullLogoUrl = rawLogoPath.isNotEmpty
      ? (rawLogoPath.startsWith('http')
          ? rawLogoPath
          : 'https://teams.quriyatclub.net/storage/teams/$rawLogoPath')
      : '';

  pw.ImageProvider? teamLogo;
  try {
    if (fullLogoUrl.isNotEmpty) {
      final response = await http.get(Uri.parse(fullLogoUrl));
      if (response.statusCode == 200) {
        teamLogo = pw.MemoryImage(response.bodyBytes);
      }
    }
  } catch (_) {}

  final token = await TeamService.getToken();
  final teamInfo = await TeamService.fetchTeamInfo(token!);
  final teamName = teamInfo?.name ?? '';

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      textDirection: pw.TextDirection.rtl,
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(clubLogo, width: 60),
            pw.Column(
              children: [
                pw.Text(
                  'قائمة اللاعبين المنتسبين',
                  style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  teamName.isNotEmpty
                      ? 'نادي قريات - فريق $teamName'
                      : 'نادي قريات',
                  style: pw.TextStyle(font: ttf, fontSize: 14, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Image(teamLogo ?? clubLogo, width: 60),
          ],
        ),

        pw.SizedBox(height: 20),

        pw.Table.fromTextArray(
          headers: ['الرقم المدني','الحالة','الاسم', 'تاريخ الميلاد', 'رقم القيد', '#'],
          data: List.generate(players.length, (index) {
            final player = players[index];
            return [
              '${player['card_id'] ?? ''}',
              '${player['join_status'] ?? ''}',
              '${player['name'] ?? ''}',
              '${player['birth_date'] ?? ''}',
              '${player['register_number'] ?? ''}',
              '${index + 1}',
            ];
          }),
          headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
          cellStyle: pw.TextStyle(font: ttf, fontSize: 12),
          border: pw.TableBorder.all(width: 0.5),
          cellAlignment: pw.Alignment.centerRight,
        ),

        pw.SizedBox(height: 30),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'التاريخ: ${DateTime.now().toLocal().toString().split(' ')[0]}',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
            pw.Text(
              'مسؤول الفريق',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
