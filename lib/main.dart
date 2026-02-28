import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sleep_provider.dart';
import 'screens/main_shell.dart';
import 'services/sleep_analysis_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final analysisService = SleepAnalysisService();

  runApp(SomnixApp(
    storageService: storageService,
    analysisService: analysisService,
  ));
}

class SomnixApp extends StatelessWidget {
  final StorageService storageService;
  final SleepAnalysisService analysisService;

  const SomnixApp({
    super.key,
    required this.storageService,
    required this.analysisService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SleepProvider(
        storageService: storageService,
        analysisService: analysisService,
      )..loadSessions(),
      child: MaterialApp(
        title: 'Somnix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainShell(),
      ),
    );
  }
}
