import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:life_os/core/constants.dart';

/// Supported currencies: symbol → display name
const Map<String, String> kSupportedCurrencies = {
  '\$': 'USD · US Dollar',
  '€': 'EUR · Euro',
  '£': 'GBP · British Pound',
  '¥': 'JPY · Japanese Yen',
  '₱': 'PHP · Philippine Peso',
  '₩': 'KRW · South Korean Won',
  '₹': 'INR · Indian Rupee',
  'A\$': 'AUD · Australian Dollar',
  'C\$': 'CAD · Canadian Dollar',
};

/// Manages the selected currency symbol and persists it in Hive settingsBox.
class CurrencyNotifier extends Notifier<String> {
  static const _key = 'currencySymbol';

  @override
  String build() {
    final box = Hive.box(AppConstants.settingsBox);
    return box.get(_key, defaultValue: '\$') as String;
  }

  void setCurrency(String symbol) {
    state = symbol;
    Hive.box(AppConstants.settingsBox).put(_key, symbol);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(
  CurrencyNotifier.new,
);
