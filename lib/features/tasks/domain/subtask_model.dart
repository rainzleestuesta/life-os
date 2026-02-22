import 'package:hive/hive.dart';

part 'subtask_model.g.dart';

@HiveType(typeId: 5)
class SubTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  bool isCompleted;

  SubTask({required this.id, required this.title, this.isCompleted = false});

  SubTask copyWith({String? id, String? title, bool? isCompleted}) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
