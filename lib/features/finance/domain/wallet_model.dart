import 'package:hive/hive.dart';

part 'wallet_model.g.dart';

@HiveType(typeId: 6)
class Wallet extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String iconKey; // 'gcash', 'bank', 'cash', 'card', 'paypal', etc.

  @HiveField(3, defaultValue: 0.0)
  final double initialBalance;

  Wallet({
    required this.id,
    required this.name,
    required this.iconKey,
    this.initialBalance = 0.0,
  });

  Wallet copyWith({
    String? id,
    String? name,
    String? iconKey,
    double? initialBalance,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }
}
