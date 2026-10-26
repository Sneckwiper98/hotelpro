import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ivf_hospital/config/ivf_erp_theme.dart';
import 'ivf_hospital/data/repositories/ivf_hospital_repository.dart';
import 'ivf_hospital/ui/ivf_erp_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IvfHospitalRepository()),
      ],
      child: const IvfHospitalApp(),
    ),
  );
}

class IvfHospitalApp extends StatelessWidget {
  const IvfHospitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<IvfHospitalRepository>();

    return MaterialApp(
      title: '${repo.config.hospitalName} — IVFPro Enterprise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: IvfErpTheme.primaryNavy,
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: IvfErpTheme.windowBg,
        dialogTheme: const DialogThemeData(backgroundColor: IvfErpTheme.dialogBg),
        colorScheme: ColorScheme.fromSeed(
          seedColor: IvfErpTheme.primaryNavy,
          primary: IvfErpTheme.primaryNavy,
          secondary: IvfErpTheme.clinicalTeal,
        ),
      ),
      home: const IvfErpShell(),
    );
  }
}
