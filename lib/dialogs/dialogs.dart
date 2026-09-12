part of '../main.dart';

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
