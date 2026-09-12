part of '../main.dart';

Color signalColor(String x) => switch (x.toLowerCase()) {
      'yellow' || 'gul' => yellow,
      'navy' => navy,
      _ => gray,
    };
Color signalText(String x) =>
    x.toLowerCase() == 'yellow' || x.toLowerCase() == 'gul'
        ? const Color(0xFF0F172A)
        : Colors.white;
String money(num? x, String? c) => x == null
    ? '–'
    : '${NumberFormat('#,##0.##', 'sv_SE').format(x).replaceAll('\u00a0', ' ')} ${c ?? ''}'
        .trim();
String pct(num? x) => x == null
    ? '–'
    : '${x >= 0 ? '+' : ''}${NumberFormat('0.0', 'sv_SE').format(x)} %';

String signalLabel(String value) => switch (value.toLowerCase()) {
      'yellow' || 'gul' => 'Gul',
      'navy' || 'blue' || 'blå' => 'Blå',
      _ => 'Grå',
    };
String signalInfo(AssetData a) {
  final date = a.raw['signal_since'] ?? a.raw['market']?['signal_since'];
  final previous =
      a.raw['previous_signal'] ?? a.raw['market']?['previous_signal'];
  final current = signalLabel(a.signal);
  if (date == null) return current;
  return previous == null
      ? '$current $date'
      : '$current $date (${signalLabel('$previous')})';
}

enum SortChoice { name, performance, signal, signalDate, value }
