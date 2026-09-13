part of '../main.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage(
      {super.key, required this.api, required this.onDataChanged});
  final Api api;
  final VoidCallback onDataChanged;
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Future<List<AssetData>> f = Future.value([]);
  SortChoice sort = SortChoice.name;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool refresh = false}) async {
    final suffix = refresh ? '?refresh=true' : '';
    final result = widget.api.get('/api/v1/favorites$suffix').then(
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
            'Favoriter',
            subtitle: 'Dina viktigaste tillgångar',
            onRefresh: () => load(refresh: true),
            onSort: () async {
              final value = await chooseSort(c, sort);
              if (value != null) setState(() => sort = value);
            },
          ),
          const Columns('Namn', 'Pris', 'Utv. idag'),
          FutureBuilder<List<AssetData>>(
            future: f,
            builder: (c, s) {
              if (s.hasError) return ErrorPane(s.error!, retry: load);
              if (!s.hasData) return const LoadingList();
              return Expanded(
                child: RefreshIndicator(
                  onRefresh: () => load(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: sortAssets(s.data!, sort)
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

class Columns extends StatelessWidget {
  const Columns(this.a, this.b, this.c, {super.key});
  final String a, b, c;
  @override
  Widget build(x) => Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 44, 2),
        child: Row(
          children: [
            Expanded(flex: 11, child: Text(a, style: style)),
            Expanded(
              flex: 11,
              child: Text(b, textAlign: TextAlign.right, style: style),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 72,
              child: Text(c, textAlign: TextAlign.right, style: style),
            ),
          ],
        ),
      );
  static const style = TextStyle(
    color: muted,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}
