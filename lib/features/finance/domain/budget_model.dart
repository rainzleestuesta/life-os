import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 4)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryName;

  @HiveField(2)
  final double? monthlyLimit;

  @HiveField(3)
  final DateTime startDate;

  @HiveField(4)
  final DateTime? endDate;

  Budget({
    required this.id,
    required this.categoryName,
    this.monthlyLimit,
    required this.startDate,
    this.endDate,
  });

  /// Returns true if this budget applies to the current date.
  bool get isActive {
    final now = DateTime.now();
    final afterStart = !now.isBefore(startDate);
    final beforeEnd = endDate == null || now.isBefore(endDate!.add(const Duration(days: 1)));
    return afterStart && beforeEnd;
  }

  /// Returns true if this budget's period has fully passed.
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!.add(const Duration(days: 1)));
  }

  Budget copyWith({
    String? id,
    String? categoryName,
    double? monthlyLimit,
    bool clearMonthlyLimit = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      monthlyLimit: clearMonthlyLimit ? null : (monthlyLimit ?? this.monthlyLimit),
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}
