part of '../main.dart';

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
