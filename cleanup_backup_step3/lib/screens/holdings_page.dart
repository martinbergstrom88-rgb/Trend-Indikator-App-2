part of '../main.dart';

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
