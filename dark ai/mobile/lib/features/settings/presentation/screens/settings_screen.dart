import 'package:flutter/material.dart';
import '../../../../core/theme/dark_theme.dart';
import '../../voice/wake_word_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/battery_card.dart';
import '../widgets/permission_card.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController settingsController;
  final WakeWordController wakeWordController;

  const SettingsScreen({
    Key? key,
    required this.settingsController,
    required this.wakeWordController,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _phraseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.settingsController.backendUrl;
    _phraseController.text = widget.wakeWordController.wakePhrase;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () => widget.settingsController.refreshAll(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([widget.settingsController, widget.wakeWordController]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. WAKE WORD TOGGLE CARD
              _buildSectionHeader('VOICE ACTIVATION'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Wake Word Assistant',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: DarkTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.wakeWordController.isWakeWordEnabled
                                      ? 'Active: listening for "${widget.wakeWordController.wakePhrase}"'
                                      : 'Disabled: wake word detection is off',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.wakeWordController.isWakeWordEnabled
                                        ? DarkTheme.accentNeon
                                        : DarkTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: widget.wakeWordController.isWakeWordEnabled,
                            onChanged: (val) async {
                              final success = await widget.settingsController.toggleWakeWord(val);
                              if (!success && val && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to enable: check microphone permission.'),
                                    backgroundColor: DarkTheme.errorRed,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF222F3E), height: 24),
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over_outlined,
                              size: 20, color: DarkTheme.primaryCyan),
                          const SizedBox(width: 12),
                          const Text(
                            'Wake Phrase:',
                            style: TextStyle(fontSize: 14, color: DarkTheme.textPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _phraseController,
                              style: const TextStyle(
                                color: DarkTheme.primaryCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onSubmitted: (newPhrase) {
                                if (newPhrase.trim().isNotEmpty) {
                                  widget.wakeWordController.setWakePhrase(newPhrase.trim());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. ASSISTANT PREFERENCES
              _buildSectionHeader('PREFERENCES'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Voice Response (TTS)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Read AI answers aloud using native Android TTS',
                          style: TextStyle(fontSize: 12, color: DarkTheme.textSecondary)),
                      secondary: const Icon(Icons.volume_up, color: DarkTheme.primaryCyan),
                      value: widget.wakeWordController.voiceResponseEnabled,
                      onChanged: (val) => widget.wakeWordController.setVoiceResponseEnabled(val),
                    ),
                    const Divider(color: Color(0xFF222F3E), height: 1),
                    SwitchListTile(
                      title: const Text('Screen-Off & Background Mode',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Keep wake-word engine active when screen turns off',
                          style: TextStyle(fontSize: 12, color: DarkTheme.textSecondary)),
                      secondary: const Icon(Icons.screen_lock_portrait, color: DarkTheme.primaryCyan),
                      value: widget.settingsController.backgroundModeEnabled,
                      onChanged: (val) => widget.settingsController.setBackgroundModeEnabled(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. SYSTEM PERMISSIONS & BATTERY
              _buildSectionHeader('SYSTEM HEALTH & PERMISSIONS'),
              PermissionCard(
                title: 'Microphone Permission',
                description: 'Required for on-device wake-word detection and voice commands.',
                icon: Icons.mic,
                isGranted: widget.settingsController.micPermissionGranted,
                onRequestTap: () => widget.settingsController.requestMicrophonePermission(),
              ),
              PermissionCard(
                title: 'Notification Permission',
                description: 'Required on Android 13+ to maintain the Foreground Service.',
                icon: Icons.notifications,
                isGranted: widget.settingsController.notificationPermissionGranted,
                onRequestTap: () => widget.settingsController.requestNotificationPermission(),
              ),
              BatteryCard(
                isIgnored: widget.settingsController.batteryOptimizationIgnored,
                onRequestTap: () => widget.settingsController.requestBatteryOptimization(),
              ),

              const SizedBox(height: 16),

              // 4. BACKEND CONFIGURATION
              _buildSectionHeader('AI BACKEND CONNECTION'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FastAPI Endpoint URL',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              style: const TextStyle(fontSize: 13, color: DarkTheme.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'http://10.0.2.2:8000',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              widget.settingsController.setBackendUrl(_urlController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backend URL updated.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('SAVE'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use http://10.0.2.2:8000 on Android Emulator, or your local machine IP on a physical phone.',
                        style: TextStyle(color: DarkTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 5. PRIVACY GUARANTEE BANNER
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1722),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E2B3C)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.shield_outlined, color: DarkTheme.accentNeon, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Privacy Guarantee: DARK detects "Hey Dark" 100% locally on-device. Audio is only processed when explicitly activated, and continuous recording is never stored or streamed.',
                        style: TextStyle(color: DarkTheme.textSecondary, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: DarkTheme.primaryCyan,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
