import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'data/repositories/hotel_repository.dart';
import 'data/services/hotel_sync_bridge_service.dart';
import 'ui/mobile/delivery/delivery_boy_app_shell.dart';

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
      child: const DeliveryBoyStandaloneApp(),
    ),
  );
}

class DeliveryBoyStandaloneApp extends StatelessWidget {
  const DeliveryBoyStandaloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HotelPro Delivery Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFD35400),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD35400)),
      ),
      home: const DeliveryBoyAppShell(),
    );
  }
}
