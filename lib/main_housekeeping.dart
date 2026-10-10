import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'data/repositories/hotel_repository.dart';
import 'data/services/hotel_sync_bridge_service.dart';
import 'ui/mobile/housekeeping/housekeeping_app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  final repo = HotelRepository();
  HotelSyncBridgeService.instance.attachRepository(repo);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
      ],
      child: const HousekeepingStandaloneApp(),
    ),
  );
}

class HousekeepingStandaloneApp extends StatelessWidget {
  const HousekeepingStandaloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HotelPro Housekeeping',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF6C3483),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C3483)),
      ),
      home: const HousekeepingAppShell(),
    );
  }
}
