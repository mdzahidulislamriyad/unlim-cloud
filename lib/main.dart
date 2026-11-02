import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/telegram_api_service.dart';
import 'data/services/download_manager_service.dart';
import 'data/repositories/cloud_storage_repository.dart';
import 'ui/view_models/storage_view_model.dart';
import 'ui/screens/main_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Storage
  final localStorage = await LocalStorageService.init();

  // 2. Initialize Telegram API Client with saved credentials
  final telegramApi = TelegramApiService(
    botToken: localStorage.getBotToken(),
    chatId: localStorage.getChatId(),
    apiEndpoint: localStorage.getCustomApiServer(),
  );

  // 3. Initialize Download Manager
  final downloadManager = DownloadManagerService();

  // 4. Initialize Repository
  final repository = CloudStorageRepository(
    telegramApi: telegramApi,
    localStorage: localStorage,
    downloadManager: downloadManager,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => StorageViewModel(
            repository: repository,
            telegramApi: telegramApi,
            localStorage: localStorage,
            downloadManager: downloadManager,
          ),
        ),
      ],
      child: const UnLimCloudApp(),
    ),
  );
}

class UnLimCloudApp extends StatelessWidget {
  const UnLimCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StorageViewModel>();

    return MaterialApp(
      title: 'UnLim Cloud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: vm.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainShellScreen(),
    );
  }
}
