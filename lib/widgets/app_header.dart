part of '../main.dart';

class Header extends StatelessWidget {
  const Header(
    this.title, {
    super.key,
    this.subtitle,
    this.onRefresh,
    this.onSort,
    this.onAdd,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final VoidCallback? onSort;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Padding(
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
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (onSort != null)
              IconButton(
                tooltip: 'Sortera',
                onPressed: onSort,
                icon: const Icon(Icons.sort),
              ),
            if (onAdd != null)
              IconButton.filledTonal(
                tooltip: 'Lägg till produkt',
                onPressed: onAdd,
                icon: const Icon(Icons.add),
              ),
            if (onRefresh != null)
              IconButton.filledTonal(
                tooltip: 'Uppdatera',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
      );
}
