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
