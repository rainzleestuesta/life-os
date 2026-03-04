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

  @HiveField(5)
  final String? budgetCategory;

  @HiveField(6)
  final List<String> tags;

  @HiveField(7)
  final String? walletId;

  @HiveField(8)
  final String? title;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.isExpense,
    required this.date,
    this.budgetCategory,
    this.tags = const [],
    this.walletId,
    this.title,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? category,
    bool? isExpense,
    DateTime? date,
    String? budgetCategory,
    List<String>? tags,
    String? walletId,
    String? title,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isExpense: isExpense ?? this.isExpense,
      date: date ?? this.date,
      budgetCategory: budgetCategory ?? this.budgetCategory,
      tags: tags ?? this.tags,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
    );
  }
}
