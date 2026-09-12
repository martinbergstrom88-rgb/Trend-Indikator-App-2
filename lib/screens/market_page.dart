part of '../main.dart';

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
