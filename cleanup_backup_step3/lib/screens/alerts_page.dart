part of '../main.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, required this.api});
  final Api api;
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  Map<String, dynamic>? data;
  Future<void> load() async {
    final value = Map<String, dynamic>.from(
      await widget.api.get('/api/v1/notifications/active'),
    );
    if (mounted) setState(() => data = value);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Header('Larm', subtitle: 'Alla aktiva notiser', onRefresh: load),
          Expanded(
            child: RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (data?['firebase_ready'] != true)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.warning_amber),
                        title: Text('Firebase är inte redo på servern'),
                      ),
                    ),
                  const Text(
                    'Indikatornotiser',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  ...((data?['signal_alerts'] ?? []) as List).map(
                    (x) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.notifications_active,
                          color: yellow,
                        ),
                        title: Text('${x['ticker']['name']}'),
                        subtitle:
                            Text('${x['ticker']['symbol']} · Färgändringar'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Prisnotiser',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  ...((data?['price_alerts'] ?? []) as List).map(
                    (x) => Card(
                      child: ListTile(
                        leading: Icon(
                          x['alert']['triggered'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: x['alert']['triggered'] == true
                              ? Colors.greenAccent
                              : muted,
                        ),
                        title: Text('${x['ticker']['name']}'),
                        subtitle: Text(
                          '${x['alert']['direction']} ${x['alert']['target_price']} ${x['ticker']['currency'] ?? ''} · ${x['alert']['triggered'] == true ? 'Utlöst' : 'Väntar'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await widget.api.send(
                              'DELETE',
                              '/api/v1/notifications/price/${x['alert']['id']}',
                            );
                            await load();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
