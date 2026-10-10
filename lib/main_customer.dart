import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'data/repositories/hotel_repository.dart';
import 'data/services/hotel_sync_bridge_service.dart';
import 'ui/customer/customer_app_shell.dart';

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
      child: const CustomerStandaloneApp(),
    ),
  );
}

class CustomerStandaloneApp extends StatelessWidget {
  const CustomerStandaloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HotelPro Food & Dining',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFE23744),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE23744)),
      ),
      home: const CustomerAppShell(),
    );
  }
}
