part of '../main.dart';

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
