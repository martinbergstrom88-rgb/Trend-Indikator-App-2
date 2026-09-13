part of '../main.dart';

Future<bool> showAddProductDialog(BuildContext context, Api api) async {
  final symbolController = TextEditingController();
  final nameController = TextEditingController();
  final currencyController = TextEditingController(text: 'SEK');
  final tradingViewController = TextEditingController();
  String assetType = 'stock';

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Ny produkt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: symbolController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Ticker'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Namn'),
              ),
              DropdownButtonFormField<String>(
                initialValue: assetType,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: const [
                  DropdownMenuItem(value: 'stock', child: Text('Aktie')),
                  DropdownMenuItem(value: 'crypto', child: Text('Krypto')),
                  DropdownMenuItem(value: 'commodity', child: Text('Råvara')),
                  DropdownMenuItem(value: 'index', child: Text('Index')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => assetType = value);
                  }
                },
              ),
              TextField(
                controller: currencyController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Valuta'),
              ),
              TextField(
                controller: tradingViewController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'TradingView-symbol',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lägg till'),
          ),
        ],
      ),
    ),
  );

  if (shouldSave != true) return false;

  final symbol = symbolController.text.trim().toUpperCase();
  if (symbol.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticker måste anges.')),
      );
    }
    return false;
  }

  try {
    await api.send('POST', '/api/v1/tickers', {
      'symbol': symbol,
      'name': nameController.text.trim(),
      'asset_type': assetType,
      'currency': currencyController.text.trim().toUpperCase(),
      'tradingview_symbol': tradingViewController.text.trim().toUpperCase(),
      'is_favorite': false,
    });
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
    return false;
  } finally {
    symbolController.dispose();
    nameController.dispose();
    currencyController.dispose();
    tradingViewController.dispose();
  }
}
