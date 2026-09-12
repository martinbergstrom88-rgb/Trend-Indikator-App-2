part of '../main.dart';

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
