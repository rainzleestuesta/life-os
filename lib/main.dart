import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:life_os/core/app_theme.dart';
import 'package:life_os/core/constants.dart';
import 'package:life_os/core/theme_provider.dart';
import 'package:life_os/core/notification_service.dart';
import 'package:life_os/features/finance/domain/transaction_model.dart';
import 'package:life_os/features/finance/domain/budget_model.dart';
import 'package:life_os/features/tasks/domain/task_model.dart';
import 'package:life_os/features/tasks/domain/subtask_model.dart';
import 'package:life_os/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  await Hive.initFlutter();

  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskCategoryAdapter());
  Hive.registerAdapter(SubTaskAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());

  await Hive.openBox<Task>(AppConstants.tasksBox);
  await Hive.openBox<Transaction>(AppConstants.financeBox);
  await Hive.openBox<Budget>(AppConstants.budgetBox);
  await Hive.openBox(AppConstants.settingsBox);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = goRouter;

    return MaterialApp.router(
      title: 'Life OS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
