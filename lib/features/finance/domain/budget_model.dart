import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 4)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryName;

  @HiveField(2)
  final double monthlyLimit;

  Budget({
    required this.id,
    required this.categoryName,
    required this.monthlyLimit,
  });

  Budget copyWith({String? id, String? categoryName, double? monthlyLimit}) {
    return Budget(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }
}
