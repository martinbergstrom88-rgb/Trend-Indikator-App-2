part of '../main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.baseUrl, required this.onUrl});
  final String baseUrl;
  final ValueChanged<String> onUrl;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Header('Inställningar', subtitle: 'Anslutning'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('API-adress'),
                    subtitle: Text(baseUrl),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => editUrl(context, baseUrl, onUrl),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Trading Indicator · 5.2.6',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
