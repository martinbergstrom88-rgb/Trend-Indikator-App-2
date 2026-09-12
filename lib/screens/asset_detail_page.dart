part of '../main.dart';

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
