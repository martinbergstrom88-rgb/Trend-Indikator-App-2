part of '../main.dart';

class AssetData {
  AssetData(this.raw);
  final Map<String, dynamic> raw;
  Map<String, dynamic>? get tickerData {
    final value = raw['ticker'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  String get symbol =>
      '${raw['symbol'] ?? raw['ticker_symbol'] ?? tickerData?['symbol'] ?? (raw['ticker'] is String ? raw['ticker'] : '')}';
  String get name => '${raw['name'] ?? tickerData?['name'] ?? symbol}';
  String get signal => '${raw['signal'] ?? raw['market']?['signal'] ?? 'gray'}';
  String? get signalSince =>
      (raw['signal_since'] ?? raw['market']?['signal_since'])?.toString();
  String? get previousSignal =>
      (raw['previous_signal'] ?? raw['market']?['previous_signal'])?.toString();
  num? get price => raw['price'] ?? raw['market']?['price'];
  num? get today => raw['change_today'] ?? raw['market']?['change_today'];
  String? get currency => raw['currency'] ?? tickerData?['currency'];
  bool get favorite =>
      raw['is_favorite'] == true || tickerData?['is_favorite'] == true;
}
