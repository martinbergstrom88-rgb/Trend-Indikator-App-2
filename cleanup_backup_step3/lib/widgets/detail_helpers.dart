part of '../main.dart';

Widget metric(String l, dynamic v) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(l, style: const TextStyle(color: muted, fontSize: 11)),
              Text(pct(v), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
Widget kv(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(a, style: const TextStyle(color: muted)),
          ),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
