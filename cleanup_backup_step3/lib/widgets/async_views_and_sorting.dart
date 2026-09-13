part of '../main.dart';

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
