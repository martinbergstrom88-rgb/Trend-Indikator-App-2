import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

part 'core/api_client.dart';
part 'models/asset_data.dart';
part 'screens/app_shell.dart';
part 'widgets/app_header.dart';
part 'core/presentation_utils.dart';
part 'widgets/asset_row.dart';
part 'widgets/async_views_and_sorting.dart';
part 'screens/favorites_page.dart';
part 'screens/holdings_page.dart';
part 'screens/market_page.dart';
part 'screens/alerts_page.dart';
part 'screens/settings_page.dart';
part 'screens/asset_detail_page.dart';
part 'widgets/detail_helpers.dart';
part 'dialogs/api_url_dialog.dart';
part 'dialogs/holding_dialog.dart';
part 'dialogs/price_alert_dialog.dart';

const bg = Color(0xFF0D1424);
const navBg = Color(0xFF10192B);
const yellow = Color(0xFFFCD34D);
const navy = Color(0xFF172750);
const gray = Color(0xFF64748B);
const muted = Color(0xFF94A3B8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TrendApp());
}

class TrendApp extends StatelessWidget {
  const TrendApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trading Indicator',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.dark,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: navBg,
            indicatorColor: Color(0x293B82F6),
          ),
        ),
        home: const AppShell(),
      );
}
