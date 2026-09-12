part of '../main.dart';

class Api {
  Api(this.baseUrl);
  final String baseUrl;
  Future<dynamic> get(String path) async {
    final r = await http
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 90));
    if (r.statusCode < 200 || r.statusCode > 299)
      throw Exception('API-fel ${r.statusCode}');
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<dynamic> send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    late http.Response r;
    if (method == 'PATCH')
      r = await http.patch(uri, headers: headers, body: jsonEncode(body));
    else if (method == 'PUT')
      r = await http.put(uri, headers: headers, body: jsonEncode(body));
    else if (method == 'POST')
      r = await http.post(uri, headers: headers, body: jsonEncode(body));
    else
      r = await http.delete(uri, headers: headers);
    if (r.statusCode < 200 || r.statusCode > 299)
      throw Exception('API-fel ${r.statusCode}: ${r.body}');
    return r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
  }
}

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
