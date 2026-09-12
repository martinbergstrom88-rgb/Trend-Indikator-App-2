import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const bg = Color(0xFF0D1424);
const navBg = Color(0xFF10192B);
const yellow = Color(0xFFFCD34D);
const navy = Color(0xFF172750);
const gray = Color(0xFF64748B);
const muted = Color(0xFF94A3B8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TrendApp());
}

class TrendApp extends StatelessWidget {
  const TrendApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trading Indicator',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.dark,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: navBg,
            indicatorColor: Color(0x293B82F6),
          ),
        ),
        home: const AppShell(),
      );
}

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

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  String baseUrl = 'http://10.0.2.2:8000';
  bool settingsLoaded = false;
  int dataRevision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      baseUrl = preferences.getString('api_url') ?? baseUrl;
      settingsLoaded = true;
    });
    await _registerNotifications();
  }

  Future<void> _registerNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token != null) {
      try {
        await Api(baseUrl).send('POST', '/api/v1/devices', {
          'token': token,
          'platform': 'android',
        });
      } catch (_) {}
    }
    messaging.onTokenRefresh.listen((token) async {
      try {
        await Api(baseUrl).send('POST', '/api/v1/devices', {
          'token': token,
          'platform': 'android',
        });
      } catch (_) {}
    });
  }

  Future<void> setUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('api_url', value);
    if (!mounted) return;
    setState(() {
      baseUrl = value;
    });
  }

  void _dataChanged() {
    if (!mounted) return;
    setState(() => dataRevision++);
  }

  Widget _createPage(int pageIndex) => switch (pageIndex) {
        0 => FavoritesPage(
            key: ValueKey('favorites-$dataRevision'),
            api: Api(baseUrl),
            onDataChanged: _dataChanged,
          ),
        1 => HoldingsPage(
            key: ValueKey('holdings-$dataRevision'),
            api: Api(baseUrl),
            onDataChanged: _dataChanged,
          ),
        2 => MarketPage(
            key: ValueKey('market-$dataRevision'),
            api: Api(baseUrl),
            onDataChanged: _dataChanged,
          ),
        3 => AlertsPage(
            key: ValueKey('alerts-$dataRevision'),
            api: Api(baseUrl),
          ),
        _ => SettingsPage(baseUrl: baseUrl, onUrl: setUrl),
      };

  @override
  Widget build(BuildContext context) {
    if (!settingsLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(child: _createPage(index)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star),
              label: 'Favoriter'),
          NavigationDestination(
              icon: Icon(Icons.business_center_outlined), label: 'Innehav'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Marknad'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined), label: 'Larm'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Inställningar'),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header(
    this.title, {
    super.key,
    this.subtitle,
    this.onRefresh,
    this.onSort,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final VoidCallback? onSort;
  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRADING INDICATOR',
                    style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (onSort != null)
              IconButton(onPressed: onSort, icon: const Icon(Icons.sort)),
            if (onRefresh != null)
              IconButton.filledTonal(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
      );
}

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

class AssetRow extends StatelessWidget {
  const AssetRow({
    super.key,
    required this.a,
    required this.trailingLabel,
    this.middle,
    this.onTap,
  });
  final AssetData a;
  final String trailingLabel;
  final String? middle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = signalText(a.signal);
    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: signalColor(a.signal),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 13,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        a.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color.withValues(alpha: .78),
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        signalInfo(a),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color.withValues(alpha: .78),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Text(
                    middle ?? money(a.price, a.currency),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 66,
                  child: Text(
                    trailingLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: color.withValues(alpha: .55),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key});
  @override
  Widget build(c) =>
      const Expanded(child: Center(child: CircularProgressIndicator()));
}

class ErrorPane extends StatelessWidget {
  const ErrorPane(this.error, {super.key, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(c) => Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 42, color: muted),
                const SizedBox(height: 12),
                Text(
                  error is TimeoutException
                      ? 'Uppdateringen tog för lång tid. Tryck Försök igen.'
                      : '$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: retry, child: const Text('Försök igen')),
              ],
            ),
          ),
        ),
      );
}

Future<SortChoice?> chooseSort(
  BuildContext context,
  SortChoice current, {
  bool holdings = false,
}) {
  return showModalBottomSheet<SortChoice>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Sortera',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          ListTile(
            title: const Text('Namn'),
            onTap: () => Navigator.pop(context, SortChoice.name),
          ),
          ListTile(
            title: Text(holdings ? 'Marknadsvärde' : 'Utveckling idag'),
            onTap: () => Navigator.pop(
              context,
              holdings ? SortChoice.value : SortChoice.performance,
            ),
          ),
          ListTile(
            title: const Text('Indikatorfärg: Gul, Grå, Blå'),
            onTap: () => Navigator.pop(context, SortChoice.signal),
          ),
          if (!holdings)
            ListTile(
              title: const Text('Senaste indikatorförändring'),
              onTap: () => Navigator.pop(context, SortChoice.signalDate),
            ),
        ],
      ),
    ),
  );
}

int signalRank(String value) => switch (value.toLowerCase()) {
      'yellow' || 'gul' => 0,
      'gray' || 'grey' || 'grå' => 1,
      'navy' || 'blue' || 'blå' => 2,
      _ => 3,
    };
List<AssetData> sortAssets(List<AssetData> input, SortChoice sort) {
  final items = [...input];
  items.sort(
    (a, b) => switch (sort) {
      SortChoice.performance => (b.today ?? -999999).compareTo(
          a.today ?? -999999,
        ),
      SortChoice.signal => signalRank(a.signal).compareTo(signalRank(b.signal)),
      SortChoice.signalDate => (b.signalSince ?? '').compareTo(
          a.signalSince ?? '',
        ),
      _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    },
  );
  return items;
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage(
      {super.key, required this.api, required this.onDataChanged});
  final Api api;
  final VoidCallback onDataChanged;
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Future<List<AssetData>> f = Future.value([]);
  SortChoice sort = SortChoice.name;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool refresh = false}) async {
    final suffix = refresh ? '?refresh=true' : '';
    final result = widget.api.get('/api/v1/favorites$suffix').then(
          (data) => (data as List)
              .map((item) => AssetData(Map<String, dynamic>.from(item)))
              .toList(),
        );
    setState(() => f = result);
    await result;
  }

  @override
  Widget build(c) => Column(
        children: [
          Header(
            'Favoriter',
            subtitle: 'Dina viktigaste tillgångar',
            onRefresh: () => load(refresh: true),
            onSort: () async {
              final value = await chooseSort(c, sort);
              if (value != null) setState(() => sort = value);
            },
          ),
          const Columns('Namn', 'Pris', 'Utv. idag'),
          FutureBuilder<List<AssetData>>(
            future: f,
            builder: (c, s) {
              if (s.hasError) return ErrorPane(s.error!, retry: load);
              if (!s.hasData) return const LoadingList();
              return Expanded(
                child: RefreshIndicator(
                  onRefresh: () => load(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: sortAssets(s.data!, sort)
                        .map(
                          (a) => AssetRow(
                            a: a,
                            trailingLabel: pct(a.today),
                            onTap: () async {
                              final changed =
                                  await openDetail(c, widget.api, a);
                              if (changed) {
                                await load();
                                widget.onDataChanged();
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      );
}

class Columns extends StatelessWidget {
  const Columns(this.a, this.b, this.c, {super.key});
  final String a, b, c;
  @override
  Widget build(x) => Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 44, 2),
        child: Row(
          children: [
            Expanded(flex: 11, child: Text(a, style: style)),
            Expanded(
              flex: 11,
              child: Text(b, textAlign: TextAlign.right, style: style),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 72,
              child: Text(c, textAlign: TextAlign.right, style: style),
            ),
          ],
        ),
      );
  static const style = TextStyle(
    color: muted,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}

class HoldingsPage extends StatefulWidget {
  const HoldingsPage(
      {super.key, required this.api, required this.onDataChanged});
  final Api api;
  final VoidCallback onDataChanged;
  @override
  State<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends State<HoldingsPage> {
  Future<List<Map<String, dynamic>>> f = Future.value([]);
  SortChoice sort = SortChoice.value;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool refresh = false}) async {
    final suffix = refresh ? '?refresh=true' : '';
    final result = widget.api
        .get('/api/v1/holdings$suffix')
        .then((data) => (data as List).cast<Map<String, dynamic>>());
    setState(() => f = result);
    await result;
  }

  @override
  Widget build(c) => Column(
        children: [
          Header(
            'Innehav',
            subtitle: 'Värde och utveckling från köp',
            onRefresh: () => load(refresh: true),
            onSort: () async {
              final value = await chooseSort(c, sort, holdings: true);
              if (value != null) setState(() => sort = value);
            },
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: f,
            builder: (c, s) {
              if (s.hasError) return ErrorPane(s.error!, retry: load);
              if (!s.hasData) return const LoadingList();
              final rows = s.data!;
              final total = rows.fold<num>(
                0,
                (v, e) => v + (e['market_value'] ?? 0),
              );
              final pnl =
                  rows.fold<num>(0, (v, e) => v + (e['profit_loss'] ?? 0));
              return Expanded(
                child: RefreshIndicator(
                  onRefresh: () => load(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Color(0x403B82F6), Color(0x102F46A5)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Totalt portföljvärde',
                              style: TextStyle(color: Color(0xFFBFDBFE)),
                            ),
                            Text(
                              money(total, 'kr'),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Totalt ${money(pnl, 'kr')}',
                              style: TextStyle(
                                color: pnl >= 0
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Columns('Namn', 'Värde', 'Sedan köp'),
                      ...rows.map((r) {
                        final a = AssetData(r);
                        return AssetRow(
                          a: a,
                          middle: money(r['market_value'], 'kr'),
                          trailingLabel: pct(r['return_since_purchase']),
                          onTap: () async {
                            final changed =
                                await openDetail(c, widget.api, a, holding: r);
                            if (changed) {
                              await load();
                              widget.onDataChanged();
                            }
                          },
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
}

class MarketPage extends StatefulWidget {
  const MarketPage({super.key, required this.api, required this.onDataChanged});
  final Api api;
  final VoidCallback onDataChanged;
  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  String q = '';
  String cat = '';
  Future<List<AssetData>> f = Future.value([]);
  SortChoice sort = SortChoice.name;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool refresh = false}) async {
    final params = <String>[];
    if (cat.isNotEmpty) params.add('asset_type=$cat');
    if (refresh) params.add('refresh=true');
    final suffix = params.isEmpty ? '' : '?${params.join('&')}';
    final result = widget.api.get('/api/v1/market$suffix').then(
          (data) => (data as List)
              .map((item) => AssetData(Map<String, dynamic>.from(item)))
              .toList(),
        );
    setState(() => f = result);
    await result;
  }

  @override
  Widget build(c) => Column(
        children: [
          Header(
            'Marknad',
            subtitle: 'Sök och hantera tillgångar',
            onRefresh: () => load(refresh: true),
            onSort: () async {
              final value = await chooseSort(c, sort);
              if (value != null) setState(() => sort = value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Sök ticker eller namn',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: {
                '': 'Alla',
                'stock': 'Aktier',
                'crypto': 'Krypto',
                'commodity': 'Råvaror',
                'index': 'Index',
              }
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: cat == e.key,
                        onSelected: (_) async {
                          if (cat == e.key) return;
                          setState(() => cat = e.key);
                          await load();
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          FutureBuilder<List<AssetData>>(
            future: f,
            builder: (c, s) {
              if (s.hasError) return ErrorPane(s.error!, retry: load);
              if (!s.hasData) return const LoadingList();
              final rows = s.data!.where(
                (a) => '${a.symbol} ${a.name}'
                    .toLowerCase()
                    .contains(q.toLowerCase()),
              );
              return Expanded(
                child: RefreshIndicator(
                  onRefresh: () => load(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: sortAssets(rows.toList(), sort)
                        .map(
                          (a) => AssetRow(
                            a: a,
                            trailingLabel: pct(a.today),
                            onTap: () async {
                              final changed =
                                  await openDetail(c, widget.api, a);
                              if (changed) {
                                await load();
                                widget.onDataChanged();
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      );
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, required this.api});
  final Api api;
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  Map<String, dynamic>? data;
  Future<void> load() async {
    final value = Map<String, dynamic>.from(
      await widget.api.get('/api/v1/notifications/active'),
    );
    if (mounted) setState(() => data = value);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Header('Larm', subtitle: 'Alla aktiva notiser', onRefresh: load),
          Expanded(
            child: RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (data?['firebase_ready'] != true)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.warning_amber),
                        title: Text('Firebase är inte redo på servern'),
                      ),
                    ),
                  const Text(
                    'Indikatornotiser',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  ...((data?['signal_alerts'] ?? []) as List).map(
                    (x) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.notifications_active,
                          color: yellow,
                        ),
                        title: Text('${x['ticker']['name']}'),
                        subtitle:
                            Text('${x['ticker']['symbol']} · Färgändringar'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Prisnotiser',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  ...((data?['price_alerts'] ?? []) as List).map(
                    (x) => Card(
                      child: ListTile(
                        leading: Icon(
                          x['alert']['triggered'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: x['alert']['triggered'] == true
                              ? Colors.greenAccent
                              : muted,
                        ),
                        title: Text('${x['ticker']['name']}'),
                        subtitle: Text(
                          '${x['alert']['direction']} ${x['alert']['target_price']} ${x['ticker']['currency'] ?? ''} · ${x['alert']['triggered'] == true ? 'Utlöst' : 'Väntar'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await widget.api.send(
                              'DELETE',
                              '/api/v1/notifications/price/${x['alert']['id']}',
                            );
                            await load();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.baseUrl, required this.onUrl});
  final String baseUrl;
  final ValueChanged<String> onUrl;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Header('Inställningar', subtitle: 'Anslutning'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('API-adress'),
                    subtitle: Text(baseUrl),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => editUrl(context, baseUrl, onUrl),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Trading Indicator · 5.2.6',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

Future<bool> openDetail(
  BuildContext context,
  Api api,
  AssetData initial, {
  Map<String, dynamic>? holding,
}) async {
  final changed = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          AssetDetailPage(api: api, initial: initial, initialHolding: holding),
    ),
  );
  return changed == true;
}

class AssetDetailPage extends StatefulWidget {
  const AssetDetailPage({
    super.key,
    required this.api,
    required this.initial,
    this.initialHolding,
  });
  final Api api;
  final AssetData initial;
  final Map<String, dynamic>? initialHolding;
  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  Map<String, dynamic>? raw;
  Map<String, dynamic>? holding;
  bool busy = true;
  bool signalNotification = false;
  List<dynamic> priceNotifications = [];
  bool dataChanged = false;
  Future<void> loadNotifications() async {
    final a = AssetData(raw ?? widget.initial.raw);
    final value = Map<String, dynamic>.from(
      await widget.api.get('/api/v1/tickers/${a.symbol}/notifications'),
    );
    if (mounted)
      setState(() {
        signalNotification = value['signal_enabled'] == true;
        priceNotifications = value['price_alerts'] ?? [];
      });
  }

  Future<void> addProductPriceAlert() async {
    final a = AssetData(raw ?? widget.initial.raw);
    final price = TextEditingController();
    String direction = '>';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('Ny prisnotis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: direction,
                items: const [
                  DropdownMenuItem(value: '>', child: Text('Över')),
                  DropdownMenuItem(value: '<', child: Text('Under')),
                ],
                onChanged: (v) {
                  if (v != null) setD(() => direction = v);
                },
              ),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Pris (${a.currency ?? ''})',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Lägg till'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await widget.api.send(
        'POST',
        '/api/v1/tickers/${a.symbol}/notifications/price',
        {
          'ticker_symbol': a.symbol,
          'direction': direction,
          'target_price': double.parse(price.text.replaceAll(',', '.')),
          'enabled': true,
        },
      );
      await loadNotifications();
    }
  }

  @override
  void initState() {
    super.initState();
    holding = widget.initialHolding;
    load();
    loadNotifications();
  }

  Future<void> load({bool refresh = false}) async {
    final d = Map<String, dynamic>.from(
      await widget.api.get(
        '/api/v1/tickers/${widget.initial.symbol}${refresh ? '?refresh=true' : ''}',
      ),
    );
    if (!mounted) return;
    setState(() {
      raw = d;
      final h = d['holding'];
      holding = h is Map ? Map<String, dynamic>.from(h) : null;
      busy = false;
    });
  }

  Future<void> editHolding() async {
    final a = AssetData(raw ?? widget.initial.raw);
    final q = TextEditingController(
      text: holding?['quantity']?.toString() ?? '',
    );
    final p = TextEditingController(
      text: holding?['purchase_price']?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(holding == null ? 'Lägg till innehav' : 'Ändra innehav'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: q,
              decoration: const InputDecoration(labelText: 'Antal'),
            ),
            TextField(
              controller: p,
              decoration: const InputDecoration(labelText: 'Inköpspris'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Spara'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.api.send('PUT', '/api/v1/holdings/${a.symbol}', {
        'quantity': double.parse(q.text.replaceAll(',', '.')),
        'purchase_price': double.parse(p.text.replaceAll(',', '.')),
      });
      await load();
    }
  }

  Future<void> deleteHolding() async {
    final a = AssetData(raw ?? widget.initial.raw);
    await widget.api.send('DELETE', '/api/v1/holdings/${a.symbol}');
    dataChanged = true;
    await load();
  }

  Future<void> editProduct() async {
    final a = AssetData(raw ?? widget.initial.raw);
    final name = TextEditingController(text: a.name);
    final currency = TextEditingController(text: a.currency ?? '');
    final tv = TextEditingController(
      text: '${raw?['tradingview_symbol'] ?? ''}',
    );
    String type = '${raw?['asset_type'] ?? 'stock'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setD) => AlertDialog(
          title: const Text('Redigera produkt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Namn'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: const [
                    DropdownMenuItem(value: 'stock', child: Text('Aktie')),
                    DropdownMenuItem(value: 'crypto', child: Text('Krypto')),
                    DropdownMenuItem(value: 'commodity', child: Text('Råvara')),
                    DropdownMenuItem(value: 'index', child: Text('Index')),
                  ],
                  onChanged: (v) {
                    if (v != null) setD(() => type = v);
                  },
                ),
                TextField(
                  controller: currency,
                  decoration: const InputDecoration(labelText: 'Valuta'),
                ),
                TextField(
                  controller: tv,
                  decoration: const InputDecoration(
                    labelText: 'TradingView-symbol',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Spara'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await widget.api.send('PATCH', '/api/v1/tickers/${a.symbol}', {
        'name': name.text.trim(),
        'asset_type': type,
        'currency': currency.text.trim().toUpperCase(),
        'tradingview_symbol': tv.text.trim().toUpperCase(),
      });
      await load();
    }
  }

  Future<void> deleteProduct() async {
    final a = AssetData(raw ?? widget.initial.raw);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Ta bort produkt helt?'),
        content: Text(
          '${a.name} tas bort från Marknad, Favoriter, Innehav, larm och historik.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.api.send('DELETE', '/api/v1/tickers/${a.symbol}');
      dataChanged = true;
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = AssetData(raw ?? widget.initial.raw);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, dataChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(a.name),
          actions: [
            IconButton(
              onPressed: () => load(refresh: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: busy
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await load(refresh: true);
                  await loadNotifications();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.paddingOf(context).bottom + 64,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: signalColor(a.signal),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: DefaultTextStyle(
                        style: TextStyle(color: signalText(a.signal)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.symbol),
                            Text(
                              money(a.price, a.currency),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text('Idag ${pct(a.today)}'),
                          ],
                        ),
                      ),
                    ),
                    SwitchListTile(
                      value: a.favorite,
                      onChanged: (v) async {
                        await widget.api.send(
                          'PATCH',
                          '/api/v1/tickers/${a.symbol}',
                          {'is_favorite': v},
                        );
                        await load();
                      },
                      title: const Text('Favorit'),
                    ),
                    ListTile(
                      title: Text(
                        holding == null
                            ? 'Lägg till som innehav'
                            : 'Ändra innehav',
                      ),
                      onTap: editHolding,
                    ),
                    if (holding != null)
                      ListTile(
                        title: const Text('Ta bort innehav'),
                        onTap: deleteHolding,
                      ),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: signalNotification,
                            onChanged: (value) async {
                              await widget.api.send(
                                'PUT',
                                '/api/v1/tickers/${a.symbol}/notifications/signal',
                                {'enabled': value},
                              );
                              if (mounted)
                                setState(() => signalNotification = value);
                            },
                            secondary: const Icon(Icons.notifications_outlined),
                            title: const Text('Indikatorförändring'),
                            subtitle: const Text(
                              'Meddela när indikatorfärgen ändras',
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.add_alert),
                            title: const Text('Lägg till prisnotis'),
                            trailing: const Icon(Icons.add),
                            onTap: addProductPriceAlert,
                          ),
                          ...priceNotifications.map(
                            (item) => ListTile(
                              leading: Icon(
                                item['triggered'] == true
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: item['triggered'] == true
                                    ? Colors.greenAccent
                                    : muted,
                              ),
                              title: Text(
                                '${item['direction']} ${item['target_price']}',
                              ),
                              subtitle: Text(
                                item['triggered'] == true ? 'Utlöst' : 'Väntar',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await widget.api.send(
                                    'DELETE',
                                    '/api/v1/notifications/price/${item['id']}',
                                  );
                                  await loadNotifications();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Redigera produkt'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: editProduct,
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_forever_outlined,
                              color: Colors.redAccent,
                            ),
                            title: const Text('Ta bort från Marknad'),
                            onTap: deleteProduct,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        final u = raw?['tradingview_url'];
                        if (u != null)
                          await launchUrl(
                            Uri.parse('$u'),
                            mode: LaunchMode.externalApplication,
                          );
                      },
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Öppna graf i TradingView'),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Signalhistorik',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    ...((raw?['signal_history'] ?? []) as List).take(3).map(
                          (item) => ListTile(
                            dense: true,
                            title:
                                Text('${item['changed_at']}'.substring(0, 10)),
                            trailing:
                                Text(signalLabel('${item['new_signal']}')),
                          ),
                        ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

Widget metric(String l, dynamic v) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(l, style: const TextStyle(color: muted, fontSize: 11)),
              Text(pct(v), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
Widget kv(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(a, style: const TextStyle(color: muted)),
          ),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );

Future<void> editUrl(
  BuildContext c,
  String old,
  ValueChanged<String> done,
) async {
  final x = TextEditingController(text: old);
  await showDialog(
    context: c,
    builder: (_) => AlertDialog(
      title: const Text('API-adress'),
      content: TextField(controller: x, keyboardType: TextInputType.url),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () {
            done(x.text.trim().replaceAll(RegExp(r'/$'), ''));
            Navigator.pop(c);
          },
          child: const Text('Spara'),
        ),
      ],
    ),
  );
}

Future<void> addHolding(BuildContext c, Api api, VoidCallback reload) async {
  final t = TextEditingController(),
      q = TextEditingController(),
      p = TextEditingController();
  await showDialog(
    context: c,
    builder: (_) => AlertDialog(
      title: const Text('Nytt innehav'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: t,
            decoration: const InputDecoration(labelText: 'Ticker'),
          ),
          TextField(
            controller: q,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Antal'),
          ),
          TextField(
            controller: p,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Inköpspris'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () async {
            await api.send(
              'PUT',
              '/api/v1/holdings/${t.text.trim().toUpperCase()}',
              {
                'quantity': double.parse(q.text.replaceAll(',', '.')),
                'purchase_price': double.parse(p.text.replaceAll(',', '.')),
              },
            );
            if (c.mounted) Navigator.pop(c);
            reload();
          },
          child: const Text('Spara'),
        ),
      ],
    ),
  );
}

Future<void> addPriceAlert(BuildContext c, Api api, VoidCallback reload) async {
  final t = TextEditingController(), p = TextEditingController();
  String dir = '>';
  await showDialog(
    context: c,
    builder: (_) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: const Text('Nytt prislarm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: t,
              decoration: const InputDecoration(labelText: 'Ticker'),
            ),
            DropdownButtonFormField(
              value: dir,
              items: const [
                DropdownMenuItem(value: '>', child: Text('Över')),
                DropdownMenuItem(value: '<', child: Text('Under')),
              ],
              onChanged: (v) => set(() => dir = v!),
            ),
            TextField(
              controller: p,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pris'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () async {
              await api.send('POST', '/api/v1/alerts/price', {
                'ticker_symbol': t.text.trim().toUpperCase(),
                'direction': dir,
                'target_price': double.parse(p.text.replaceAll(',', '.')),
              });
              if (c.mounted) Navigator.pop(c);
              reload();
            },
            child: const Text('Spara'),
          ),
        ],
      ),
    ),
  );
}
