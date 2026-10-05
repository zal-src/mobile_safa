import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/database_helper.dart';
import '../models/loan_contract.dart';

class PrintablePdfService {
  final DatabaseHelper _database = DatabaseHelper.instance;

  Future<void> printContract(LoanContract contract) async {
    final lender = await _database.getUserById(contract.lenderId);
    final borrower = await _database.getUserById(contract.borrowerId);
    final borrowerAddress = await _database.getUserAddress(
      contract.borrowerId,
      addressType: 'registered',
    );
    final lenderAddress = await _database.getUserAddress(
      contract.lenderId,
      addressType: 'registered',
    );

    if (lender == null || borrower == null) {
      throw Exception('ไม่พบข้อมูลผู้ใช้ของสัญญา');
    }

    final regularFont = await PdfGoogleFonts.notoSansThaiRegular();
    final boldFont = await PdfGoogleFonts.notoSansThaiBold();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 36),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (_) => _buildAgreement(
          contract: contract,
          lender: lender,
          borrower: borrower,
          lenderAddress: lenderAddress,
          borrowerAddress: borrowerAddress,
          regularFont: regularFont,
          boldFont: boldFont,
        ),
      ),
    );

    await Printing.layoutPdf(
      name: '${contract.agreementId}.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  List<pw.Widget> _buildAgreement({
    required LoanContract contract,
    required Map<String, dynamic> lender,
    required Map<String, dynamic> borrower,
    required Map<String, dynamic>? lenderAddress,
    required Map<String, dynamic>? borrowerAddress,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    final borrowerAddressText = _addressText(borrowerAddress);
    final lenderAddressText = _addressText(lenderAddress);
    final amount = _money(contract.amount);

    return [
      pw.Center(
        child: pw.Text(
          'หนังสือสัญญากู้ยืมเงิน',
          style: pw.TextStyle(font: boldFont, fontSize: 19),
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text(
          'แบบเอกสารสำหรับคู่สัญญาตรวจสอบและกรอกข้อมูลต่อ',
          style: pw.TextStyle(font: regularFont, fontSize: 9),
        ),
      ),
      pw.SizedBox(height: 16),
      _lineRow('ลำดับที่', contract.agreementId, regularFont),
      _lineRow('ทำที่', 'ผ่านระบบออนไลน์ของ SAFA ', regularFont),
      _lineRow('วันที่', '${_formatThaiDate(contract.loanDate)} ', regularFont),
      pw.SizedBox(height: 10),
      pw.Text('คู่สัญญา', style: pw.TextStyle(font: boldFont, fontSize: 13)),
      pw.SizedBox(height: 5),
      _partyParagraph(
        'ผู้กู้',
        borrower,
        borrowerAddressText,
        regularFont,
        boldFont,
      ),
      _partyParagraph(
        'ผู้ให้กู้',
        lender,
        lenderAddressText,
        regularFont,
        boldFont,
      ),
      pw.SizedBox(height: 10),
      pw.Text(
        'แบบฟอร์มนี้สรุปข้อมูลจากระบบเพื่อให้คู่สัญญาตรวจสอบและกรอกข้อความที่จำเป็นเพิ่มเติมก่อนลงนาม',
        style: pw.TextStyle(font: regularFont, fontSize: 11, lineSpacing: 3),
      ),
      pw.SizedBox(height: 8),
      _article(
        'ข้อ ๑',
        'จำนวนเงินตามข้อมูลในระบบ: $amount บาท '
            'ข้อความและเงื่อนไขการกู้ยืมให้คู่สัญญาตรวจสอบและกรอกเพิ่มเติมก่อนลงนาม',
        regularFont,
        boldFont,
      ),
      _article(
        'ข้อ ๒',
        'หลักประกัน (ถ้ามี): ________________________________________________________________\n'
            '________________________________________________________________________________\n'
            'หากไม่มีหลักประกัน ให้ระบุว่า “ไม่มี”',
        regularFont,
        boldFont,
      ),
      _article(
        'ข้อ ๓',
        'วันครบกำหนดตามข้อมูลในระบบ:วันที่ ${_formatThaiDate(contract.returnDate)}'
            'ให้คู่สัญญาตรวจสอบและแก้ไขให้ตรงกับข้อตกลงจริง',
        regularFont,
        boldFont,
      ),
      _article(
        'ข้อ ๔',
        'ดอกเบี้ยหรือค่าตอบแทน  ${contract.interestRate.toStringAsFixed(2)}% ',
        regularFont,
        boldFont,
      ),
      _article(
        'ข้อ ๕',
        'การผิดนัด การบอกกล่าว และการดำเนินการต่อไป ให้คู่สัญญาตกลงและกรอกข้อความเพิ่มเติมด้วยตนเองให้ชัดเจนก่อนลงนาม',
        regularFont,
        boldFont,
      ),
      _article(
        'ข้อ ๖',
        'เงื่อนไขเพิ่มเติม: ${contract.notes?.trim().isNotEmpty == true ? contract.notes!.trim() : '________________________________________________________________________________'}',
        regularFont,
        boldFont,
      ),
      pw.SizedBox(height: 8),
      _lineRow(
        'วัตถุประสงค์',
        contract.purpose?.trim().isNotEmpty == true
            ? contract.purpose!.trim()
            : '________________________________________________________________________________',
        regularFont,
      ),
      pw.SizedBox(height: 12),
      pw.Text(
        'คู่สัญญาควรอ่าน ตรวจสอบ และกรอกข้อมูลเพิ่มเติมให้ตรงกับข้อตกลงจริงก่อนลงลายมือชื่อ',
        style: pw.TextStyle(font: regularFont, fontSize: 11, lineSpacing: 3),
      ),
      pw.SizedBox(height: 24),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _signatureLine(
              'ลงลายมือชื่อ __________________________ ผู้กู้',
              borrower,
              regularFont,
              boldFont,
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: _signatureLine(
              'ลงลายมือชื่อ __________________________ ผู้ให้กู้',
              lender,
              regularFont,
              boldFont,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 25),
      pw.Text('พยาน', style: pw.TextStyle(font: boldFont, fontSize: 12)),
      pw.SizedBox(height: 14),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _blankSignature(
              'ลงลายมือชื่อ __________________________ พยาน',
              regularFont,
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: _blankSignature(
              'ลงลายมือชื่อ __________________________ พยาน',
              regularFont,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 28),
      pw.Text(
        'ข้อมูลที่เว้นว่างให้คู่สัญญาตรวจสอบและกรอกเพิ่มเติมก่อนใช้งานจริง',
        style: pw.TextStyle(
          font: regularFont,
          fontSize: 8,
          color: PdfColors.grey700,
        ),
      ),
    ];
  }

  pw.Widget _partyParagraph(
    String role,
    Map<String, dynamic> user,
    String address,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final name = user['full_name']?.toString() ?? '________________________';
    final idCard = user['id_card']?.toString() ?? '________________________';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Text(
        '$role: $name เลขประจำตัวประชาชน $idCard\n'
        'อยู่บ้านเลขที่ $address',
        style: pw.TextStyle(font: regularFont, fontSize: 10, lineSpacing: 2),
      ),
    );
  }

  pw.Widget _article(
    String title,
    String text,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 42,
            child: pw.Text(
              title,
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 10,
                lineSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _lineRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        '$label $value',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    );
  }

  pw.Widget _signatureLine(
    String label,
    Map<String, dynamic> user,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 30),
        pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: regularFont, fontSize: 9),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          user['full_name']?.toString() ?? '-',
          style: pw.TextStyle(font: boldFont, fontSize: 9),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'วันที่ ____________________',
          style: pw.TextStyle(font: regularFont, fontSize: 9),
        ),
      ],
    );
  }

  pw.Widget _blankSignature(String label, pw.Font font) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 30),
        pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: font, fontSize: 9),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'วันที่ ____________________',
          style: pw.TextStyle(font: font, fontSize: 9),
        ),
      ],
    );
  }

  String _addressText(Map<String, dynamic>? address) {
    if (address == null) return '____________________________';
    final values = [
      address['address'],
      address['subdistrict'],
      address['district'],
      address['province'],
      address['postal_code'],
    ];
    return values
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' ');
  }

  String _formatThaiDate(String dateStr) {
    if (dateStr.isEmpty) return dateStr;
    final DateTime? date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;

    final List<String> thaiMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  String _money(double amount) => amount.toStringAsFixed(2);
}
