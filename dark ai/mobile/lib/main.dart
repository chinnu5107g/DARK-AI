import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/network/api_client.dart';
import 'core/theme/dark_theme.dart';
import 'features/chat/controllers/chat_controller.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/voice/voice_controller.dart';
import 'features/voice/voice_service.dart';
import 'features/voice/wake_word_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation & status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: DarkTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DarkAiApp());
}

class DarkAiApp extends StatefulWidget {
  const DarkAiApp({Key? key}) : super(key: key);

  @override
  State<DarkAiApp> createState() => _DarkAiAppState();
}

class _DarkAiAppState extends State<DarkAiApp> {
  late final ApiClient apiClient;
  late final VoiceService voiceService;
  late final ChatController chatController;
  late final WakeWordController wakeWordController;
  late final VoiceController voiceController;
  late final SettingsController settingsController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    apiClient = ApiClient();
    voiceService = VoiceService();

    chatController = ChatController(
      apiClient: apiClient,
      voiceService: voiceService,
    );

    wakeWordController = WakeWordController(
      voiceService: voiceService,
      apiClient: apiClient,
      chatController: chatController,
    );

    voiceController = VoiceController(
      voiceService: voiceService,
      apiClient: apiClient,
      chatController: chatController,
    );

    settingsController = SettingsController(
      voiceService: voiceService,
      apiClient: apiClient,
      wakeWordController: wakeWordController,
    );
  }

  @override
  void dispose() {
    chatController.dispose();
    wakeWordController.dispose();
    voiceController.dispose();
    settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DARK AI',
      debugShowCheckedModeBanner: false,
      theme: DarkTheme.themeData,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            ChatScreen(
              chatController: chatController,
              wakeWordController: wakeWordController,
              voiceController: voiceController,
              onOpenSettings: () {
                setState(() => _currentIndex = 1);
              },
            ),
            SettingsScreen(
              settingsController: settingsController,
              wakeWordController: wakeWordController,
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: DarkTheme.surface,
          selectedItemColor: DarkTheme.primaryCyan,
          unselectedItemColor: DarkTheme.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
