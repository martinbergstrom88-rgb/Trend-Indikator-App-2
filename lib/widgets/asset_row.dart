part of '../main.dart';

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
