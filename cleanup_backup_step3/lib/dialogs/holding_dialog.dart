part of '../main.dart';

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
