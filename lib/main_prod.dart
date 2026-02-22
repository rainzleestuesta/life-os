import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart' as app;

/// Production entry point for the application.
/// This matches the Codemagic setting: -t lib/main_prod.dart
void main() {
  // You can add production-specific configuration here (e.g., logging, environment variables)
  app.main();
}
