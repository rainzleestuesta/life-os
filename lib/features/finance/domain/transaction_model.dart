import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 2)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final bool isExpense;

  @HiveField(4)
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.isExpense,
    required this.date,
  });
}
