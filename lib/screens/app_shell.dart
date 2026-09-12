part of '../main.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  String baseUrl = 'http://10.0.2.2:8000';
  bool settingsLoaded = false;
  int dataRevision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      baseUrl = preferences.getString('api_url') ?? baseUrl;
      settingsLoaded = true;
    });
    await _registerNotifications();
  }

  Future<void> _registerNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token != null) {
      try {
        await Api(baseUrl).send('POST', '/api/v1/devices', {
          'token': token,
          'platform': 'android',
        });
      } catch (_) {}
    }
    messaging.onTokenRefresh.listen((token) async {
      try {
        await Api(baseUrl).send('POST', '/api/v1/devices', {
          'token': token,
          'platform': 'android',
        });
      } catch (_) {}
    });
  }

  Future<void> setUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('api_url', value);
    if (!mounted) return;
    setState(() {
      baseUrl = value;
    });
  }

  void _dataChanged() {
    if (!mounted) return;
    setState(() => dataRevision++);
  }

  Widget _createPage(int pageIndex) => switch (pageIndex) {
        0 => FavoritesPage(
            key: ValueKey('favorites-$dataRevision'),
            api: Api(baseUrl),
            onDataChanged: _dataChanged,
          ),
        1 => HoldingsPage(
            key: ValueKey('holdings-$dataRevision'),
            api: Api(baseUrl),
            onDataChanged: _dataChanged,
          ),
        2 => MarketPage(
            key: ValueKey('market-$dataRevision'),
            api: Api(baseUrl),
            onDataChanged: _dataChanged,
          ),
        3 => AlertsPage(
            key: ValueKey('alerts-$dataRevision'),
            api: Api(baseUrl),
          ),
        _ => SettingsPage(baseUrl: baseUrl, onUrl: setUrl),
      };

  @override
  Widget build(BuildContext context) {
    if (!settingsLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(child: _createPage(index)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star),
              label: 'Favoriter'),
          NavigationDestination(
              icon: Icon(Icons.business_center_outlined), label: 'Innehav'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Marknad'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined), label: 'Larm'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Inställningar'),
        ],
      ),
    );
  }
}
