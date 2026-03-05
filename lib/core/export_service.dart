import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:life_flow/features/finance/domain/transaction_model.dart';
import 'package:life_flow/features/tasks/domain/task_model.dart';
import 'package:life_flow/features/finance/domain/wallet_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

class ImportResult {
  final List<Transaction>? transactions;
  final List<Task>? tasks;
  
  ImportResult({this.transactions, this.tasks});
}

class ExportService {
  /// Export all transactions and tasks to CSV files and share them.
  Future<void> exportAllDataCsv(
    List<Transaction> transactions,
    List<Wallet> wallets,
    List<Task> tasks,
    String currency,
  ) async {
    final headers = [
      'Date',
      'Category',
      'Type',
      'Amount ($currency)',
      'Budget Category',
      'Wallet',
    ];

    final walletMap = {for (final w in wallets) w.id: w.name};

    final rows = transactions.map((t) {
      return [
        DateFormat('yyyy-MM-dd HH:mm').format(t.date),
        t.category,
        t.isExpense ? 'Expense' : 'Income',
        t.amount.toStringAsFixed(2),
        t.budgetCategory ?? '',
        t.walletId != null ? (walletMap[t.walletId] ?? 'Unknown') : '',
      ];
    }).toList();

    // Sort by date descending
    rows.sort((a, b) => b[0].compareTo(a[0]));

    final csvData = const ListToCsvConverter().convert([headers, ...rows]);

    // Tasks Export
    final taskHeaders = [
      'Title',
      'Completed',
      'Due Date',
      'Priority',
      'Category',
      'Description',
      'Scheduled Time',
      'Repeat Days',
    ];

    final taskRows = tasks.map((t) {
      return [
        t.title,
        t.isCompleted ? 'TRUE' : 'FALSE',
        t.dueDate != null ? DateFormat('yyyy-MM-dd HH:mm').format(t.dueDate!) : '',
        t.priority.name,
        t.category.name,
        t.description ?? '',
        t.scheduledTime ?? '',
        t.repeatDays.join('-'),
      ];
    }).toList();

    final taskCsvData = const ListToCsvConverter().convert([taskHeaders, ...taskRows]);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    if (kIsWeb) {
      final transactionsXFile = XFile.fromData(
        utf8.encode(csvData),
        mimeType: 'text/csv',
        name: 'lifeflow_transactions_$timestamp.csv',
      );
      final tasksXFile = XFile.fromData(
        utf8.encode(taskCsvData),
        mimeType: 'text/csv',
        name: 'lifeflow_routines_$timestamp.csv',
      );
      await Share.shareXFiles(
        [transactionsXFile, tasksXFile],
        subject: 'LifeFlow Data Export',
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/lifeflow_transactions_$timestamp.csv');
    await file.writeAsString(csvData);

    final taskFile = File('${dir.path}/lifeflow_routines_$timestamp.csv');
    await taskFile.writeAsString(taskCsvData);

    await Share.shareXFiles(
      [XFile(file.path), XFile(taskFile.path)],
      subject: 'LifeFlow Data Export',
    );
  }

  /// Import data from a CSV file.
  Future<ImportResult?> importDataCsv(
    List<Wallet> wallets,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // Required for Web support
    );

    if (result == null || result.files.isEmpty) {
      return null; // User canceled the picker
    }

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) {
      // On mobile/desktop, we might only get a path, so read the file
      final path = result.files.first.path;
      if (path != null) {
        final file = File(path);
        final csvString = await file.readAsString();
        return _parseCsv(csvString, wallets);
      }
      return null;
    }

    // We have bytes (common on Web)
    final csvString = String.fromCharCodes(fileBytes);
    return _parseCsv(csvString, wallets);
  }

  ImportResult? _parseCsv(String csvString, List<Wallet> wallets) {
    // Basic CSV parsing
    final List<List<dynamic>> rows =
        const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(csvString);

    if (rows.isEmpty || rows.length == 1) return null;

    final headerRow = rows[0].map((e) => e.toString().toLowerCase()).toList();

    // Check if it's a transactions file
    if (headerRow.contains('amount') || headerRow.contains('wallet') || headerRow.contains('type')) {
      return ImportResult(transactions: _parseTransactions(rows, wallets));
    } 
    // Check if it's a tasks file
    else if (headerRow.contains('title') || headerRow.contains('priority') || headerRow.contains('completed')) {
      return ImportResult(tasks: _parseTasks(rows));
    }

    return null;
  }

  List<Transaction> _parseTransactions(List<List<dynamic>> rows, List<Wallet> wallets) {
    final transactions = <Transaction>[];
    final walletReverseMap = {for (final w in wallets) w.name.toLowerCase(): w.id};

    for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 6) continue;

        try {
            final dateStr = row[0].toString();
            final category = row[1].toString();
            final typeStr = row[2].toString().toLowerCase();
            final amountStr = row[3].toString();
            final budgetCategoryStr = row[4].toString();
            final walletNameStr = row[5].toString().toLowerCase();

            final date = DateFormat('yyyy-MM-dd HH:mm').parse(dateStr);
            final isExpense = typeStr == 'expense';
            final amount = double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
            final budgetCategory = budgetCategoryStr.isNotEmpty ? budgetCategoryStr : null;
            final walletId = walletReverseMap[walletNameStr]; // Null if 'unknown' or empty

            transactions.add(Transaction(
                id: const Uuid().v4(),
                amount: amount,
                category: category,
                isExpense: isExpense,
                date: date,
                budgetCategory: budgetCategory,
                walletId: walletId,
            ));
        } catch (e) {
            print('Error parsing transaction row: $e');
        }
    }
    return transactions;
  }

  List<Task> _parseTasks(List<List<dynamic>> rows) {
    final tasks = <Task>[];

    for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 8) continue;

        try {
            final title = row[0].toString();
            final completedStr = row[1].toString().toLowerCase();
            final dueDateStr = row[2].toString();
            final priorityStr = row[3].toString().toLowerCase();
            final categoryStr = row[4].toString().toLowerCase();
            final descriptionStr = row[5].toString();
            final scheduledTimeStr = row[6].toString();
            final repeatDaysStr = row[7].toString();

            final isCompleted = completedStr == 'true';
            final dueDate = dueDateStr.isNotEmpty ? DateFormat('yyyy-MM-dd HH:mm').parse(dueDateStr) : null;
            
            final priority = TaskPriority.values.firstWhere(
              (p) => p.name == priorityStr, 
              orElse: () => TaskPriority.low,
            );

            final category = TaskCategory.values.firstWhere(
              (c) => c.name == categoryStr, 
              orElse: () => TaskCategory.anytime,
            );

            final repeatDays = repeatDaysStr.isNotEmpty 
                ? repeatDaysStr.split('-').map((e) => int.tryParse(e)).whereType<int>().toList()
                : <int>[];

            tasks.add(Task(
                id: const Uuid().v4(),
                title: title,
                isCompleted: isCompleted,
                dueDate: dueDate,
                priority: priority,
                description: descriptionStr.isNotEmpty ? descriptionStr : null,
                scheduledTime: scheduledTimeStr.isNotEmpty ? scheduledTimeStr : null,
                repeatDays: repeatDays,
                category: category,
                completedDates: [],
                subTasks: [],
                tags: [],
                createdDate: DateTime.now(),
            ));
        } catch (e) {
            print('Error parsing task row: $e');
        }
    }
    return tasks;
  }
}
