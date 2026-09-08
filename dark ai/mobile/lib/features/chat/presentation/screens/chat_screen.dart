import 'package:flutter/material.dart';
import '../../../../core/theme/dark_theme.dart';
import '../../voice/models/voice_state.dart';
import '../../voice/presentation/widgets/wake_word_hud.dart';
import '../../voice/voice_controller.dart';
import '../../voice/wake_word_controller.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/voice_visualizer.dart';

class ChatScreen extends StatefulWidget {
  final ChatController chatController;
  final WakeWordController wakeWordController;
  final VoiceController voiceController;
  final VoidCallback onOpenSettings;

  const ChatScreen({
    Key? key,
    required this.chatController,
    required this.wakeWordController,
    required this.voiceController,
    required this.onOpenSettings,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickSuggestions = [
    'What time is it?',
    'Weather forecast',
    'Remind me to call team at 3pm',
    'Take a note: System deployed',
    'Who are you?',
  ];

  @override
  void initState() {
    super.initState();
    widget.chatController.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.chatController.removeListener(_scrollToBottom);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendText() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      widget.chatController.sendTextMessage(
        text,
        speakResponse: widget.wakeWordController.voiceResponseEnabled,
      );
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: DarkTheme.primaryCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DarkTheme.primaryCyan.withOpacity(0.4)),
              ),
              child: const Icon(Icons.psychology, color: DarkTheme.primaryCyan, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DARK AI',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: widget.wakeWordController,
                      builder: (context, _) {
                        final isListening = widget.wakeWordController.state == VoiceState.wakeWordListening;
                        return Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isListening ? DarkTheme.accentNeon : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: isListening
                                ? [
                                    BoxShadow(
                                      color: DarkTheme.accentNeon.withOpacity(0.6),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    AnimatedBuilder(
                      animation: widget.wakeWordController,
                      builder: (context, _) {
                        return Text(
                          widget.wakeWordController.isWakeWordEnabled
                              ? 'Wake-Word: "${widget.wakeWordController.wakePhrase}"'
                              : 'Wake-Word: Off',
                          style: const TextStyle(color: DarkTheme.textSecondary, fontSize: 11),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 22),
            tooltip: 'Clear Chat',
            onPressed: () => widget.chatController.clearMessages(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live voice assistant HUD (Activated / Listening / Speaking)
            WakeWordHud(controller: widget.wakeWordController),

            // Message list
            Expanded(
              child: AnimatedBuilder(
                animation: widget.chatController,
                builder: (context, child) {
                  final messages = widget.chatController.messages;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubble(
                        message: msg,
                        onSpeakTap: msg.spokenText != null
                            ? () => widget.wakeWordController.toggleWakeWordService(true)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),

            // Quick suggestion chips
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _quickSuggestions.length,
                itemBuilder: (context, index) {
                  final text = _quickSuggestions[index];
                  return ActionChip(
                    label: Text(text, style: const TextStyle(fontSize: 12, color: DarkTheme.textPrimary)),
                    backgroundColor: DarkTheme.surfaceLight,
                    side: const BorderSide(color: Color(0xFF243042)),
                    onPressed: () {
                      _textController.text = text;
                      _handleSendText();
                    },
                  );
                },
              ),
            ),

            // Bottom Input Bar with Push-to-Talk and Text Send
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: DarkTheme.surface,
        border: Border(top: BorderSide(color: Color(0xFF1E2836), width: 1)),
      ),
      child: AnimatedBuilder(
        animation: widget.voiceController,
        builder: (context, _) {
          final isPttActive = widget.voiceController.isPushToTalkActive;

          if (isPttActive) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: DarkTheme.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DarkTheme.primaryCyan, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: DarkTheme.primaryCyan, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Listening... Release to send',
                      style: TextStyle(color: DarkTheme.primaryCyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const VoiceVisualizer(
                    isListening: true,
                    color: DarkTheme.primaryCyan,
                    barCount: 6,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: DarkTheme.errorRed, size: 20),
                    onPressed: () => widget.voiceController.cancelPushToTalk(),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              // Push to Talk Mic Button
              GestureDetector(
                onLongPressStart: (_) => widget.voiceController.startPushToTalk(),
                onLongPressEnd: (_) => widget.voiceController.finishPushToTalk('What can you do?'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DarkTheme.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: DarkTheme.primaryCyan.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.mic, color: DarkTheme.primaryCyan, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              // Text Field
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendText(),
                  style: const TextStyle(color: DarkTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ask DARK or say "Hey Dark"...',
                    suffixIcon: AnimatedBuilder(
                      animation: widget.chatController,
                      builder: (context, _) {
                        if (widget.chatController.isProcessing) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DarkTheme.primaryCyan,
                              ),
                            ),
                          );
                        }
                        return IconButton(
                          icon: const Icon(Icons.send, color: DarkTheme.primaryCyan, size: 20),
                          onPressed: _handleSendText,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
