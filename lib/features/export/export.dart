import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';

class ExcelExportResult {
  final String path;
  final int rowCount;

  const ExcelExportResult({
    required this.path,
    required this.rowCount,
  });
}

class ExcelExporter {
  static const _downloadsChannel =
      MethodChannel('budgetko/downloads');

  Future<ExcelExportResult> exportTransactions(
    List<TransactionWithDetails> transactions,
  ) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'budgetko-transactions-$timestamp.xls';
    final workbook = _buildWorkbook(transactions);
    final path = await _saveWorkbook(fileName, workbook);

    return ExcelExportResult(
      path: path,
      rowCount: transactions.length,
    );
  }

  String _buildWorkbook(List<TransactionWithDetails> transactions) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<?mso-application progid="Excel.Sheet"?>',
      )
      ..writeln(
        '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
        'xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:x="urn:schemas-microsoft-com:office:excel" '
        'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" '
        'xmlns:html="http://www.w3.org/TR/REC-html40">',
      )
      ..writeln('<Styles>')
      ..writeln(
        '<Style ss:ID="Header"><Font ss:Bold="1"/>'
        '<Interior ss:Color="#D9EAD3" ss:Pattern="Solid"/></Style>',
      )
      ..writeln('</Styles>')
      ..writeln('<Worksheet ss:Name="Transactions">')
      ..writeln('<Table>')
      ..writeln(
        _row(
          [
            _stringCell('Date', styleId: 'Header'),
            _stringCell('Time', styleId: 'Header'),
            _stringCell('Type', styleId: 'Header'),
            _stringCell('Amount', styleId: 'Header'),
            _stringCell('Category', styleId: 'Header'),
            _stringCell('Wallet', styleId: 'Header'),
            _stringCell('Note', styleId: 'Header'),
          ],
        ),
      );

    for (final item in transactions) {
      final transaction = item.transaction;
      final localDate = transaction.date.toLocal();
      buffer.writeln(
        _row(
          [
            _stringCell(_date(localDate)),
            _stringCell(_time(localDate)),
            _stringCell(transaction.type),
            _numberCell(transaction.amount),
            _stringCell(item.category?.name ?? ''),
            _stringCell(item.wallet?.name ?? ''),
            _stringCell(transaction.note ?? ''),
          ],
        ),
      );
    }

    buffer
      ..writeln('</Table>')
      ..writeln('</Worksheet>')
      ..writeln('</Workbook>');

    return buffer.toString();
  }

  Future<String> _saveWorkbook(String fileName, String workbook) async {
    if (Platform.isAndroid) {
      return _downloadsChannel.invokeMethod<String>(
        'saveWorkbook',
        {
          'fileName': fileName,
          'content': workbook,
        },
      ).then((path) {
        if (path == null || path.isEmpty) {
          throw const FileSystemException(
            'Android did not return a download path',
          );
        }
        return path;
      });
    }

    final directory = await _exportDirectory();
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(workbook, flush: true);
    return file.path;
  }

  Future<Directory> _exportDirectory() async {
    final downloadsDirectory = await getDownloadsDirectory();
    final baseDirectory =
        downloadsDirectory ?? await getApplicationDocumentsDirectory();
    final directory =
        Directory(p.join(baseDirectory.path, 'BudgetKo exports'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _row(List<String> cells) {
    return '<Row>${cells.join()}</Row>';
  }

  String _stringCell(String value, {String? styleId}) {
    final style = styleId == null ? '' : ' ss:StyleID="$styleId"';
    return '<Cell$style><Data ss:Type="String">${_xml(value)}</Data></Cell>';
  }

  String _numberCell(double value) {
    return '<Cell><Data ss:Type="Number">${value.toStringAsFixed(2)}</Data></Cell>';
  }

  String _xml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
