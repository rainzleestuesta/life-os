// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 2;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      category: fields[2] as String,
      isExpense: fields[3] as bool,
      date: fields[4] as DateTime,
      budgetCategory: fields[5] as String?,
      tags: (fields[6] as List).cast<String>(),
      walletId: fields[7] as String?,
      title: fields[8] as String?,
      isTransfer: fields[9] == null ? false : fields[9] as bool,
      transferToWalletId: fields[10] as String?,
      transferFee: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.isExpense)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.budgetCategory)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.walletId)
      ..writeByte(8)
      ..write(obj.title)
      ..writeByte(9)
      ..write(obj.isTransfer)
      ..writeByte(10)
      ..write(obj.transferToWalletId)
      ..writeByte(11)
      ..write(obj.transferFee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
