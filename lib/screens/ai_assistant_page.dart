import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../widgets/modern_snackbar.dart';
import '../widgets/modern_dialog.dart';
import '../widgets/modern_bottom_sheet.dart';
import '../state/app_state.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  static const String routeName = '/ai-assistant';

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  bool _isTyping = false;
  bool _isRecording = false;
  bool _hasText = false;

  // Предустановленные вопросы для водителей
  List<QuickQuestion> _getQuickQuestions(AppState appState) {
    return [
      QuickQuestion(
        icon: Icons.local_gas_station_rounded,
        text: appState.t('ai_quick_question_cheap_station'),
        color: const Color(0xFF1565C0),
      ),
      QuickQuestion(
        icon: Icons.route_rounded,
        text: appState.t('ai_quick_question_fast_route'),
        color: const Color(0xFF4CAF50),
      ),
      QuickQuestion(
        icon: Icons.info_outline_rounded,
        text: appState.t('ai_quick_question_fuel_quality'),
        color: const Color(0xFFFF9800),
      ),
      QuickQuestion(
        icon: Icons.tips_and_updates_rounded,
        text: appState.t('ai_quick_question_fuel_saving'),
        color: const Color(0xFF9C27B0),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _messages.add(
        ChatMessage(
          id: 'welcome',
          text: appState.t('ai_welcome_message'),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _controller.clear();
    });
    _scrollToBottom();

    // Имитация ответа ИИ
    _simulateAiResponse(text);
  }

  void _simulateAiResponse(String userMessage) {
    setState(() {
      _isTyping = true;
    });

    // Имитация задержки ответа
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      String response = _generateResponse(userMessage);

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  String _generateResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('дешев') ||
        lowerMessage.contains('цена') ||
        lowerMessage.contains('стоимость')) {
      return 'Сейчас самые выгодные цены на топливо:\n\n• AI-80: от 10 500 сум (Highway Fuel)\n• AI-91: от 11 200 сум (PoCho City Station)\n• AI-95: от 11 800 сум (Ring Road Gas)\n• AI-98: от 12 500 сум (Central Station)\n• Дизель: от 11 000 сум (Highway Fuel)\n\nРекомендую проверить акции - многие заправки предлагают скидки до 10%!';
    } else if (lowerMessage.contains('маршрут') ||
        lowerMessage.contains('дорога') ||
        lowerMessage.contains('путь')) {
      return 'Для построения оптимального маршрута мне нужна информация:\n\n📍 Точка отправления\n📍 Точка назначения\n⛽ Нужны ли заправки по пути\n\nЯ могу:\n• Найти самый короткий путь\n• Построить маршрут с заправками\n• Учесть пробки и дорожные условия\n• Предложить альтернативные варианты\n\nУкажите, пожалуйста, откуда и куда вы едете?';
    } else if (lowerMessage.contains('качество') ||
        lowerMessage.contains('топливо') ||
        lowerMessage.contains('бензин')) {
      return 'Качество топлива в Узбекистане:\n\n✅ **AI-80** - стандартное топливо, подходит для старых автомобилей\n✅ **AI-91** - улучшенное топливо, рекомендовано для большинства авто\n✅ **AI-95** - премиум топливо, лучшее качество, экономия до 8%\n✅ **AI-98** - супер премиум, максимальная мощность двигателя\n✅ **Дизель** - для дизельных двигателей\n\n💡 Совет: Используйте топливо, рекомендованное производителем вашего автомобиля.';
    } else if (lowerMessage.contains('экономи') ||
        lowerMessage.contains('совет') ||
        lowerMessage.contains('экономия')) {
      return 'Советы по экономии топлива:\n\n🚗 **Стиль вождения:**\n• Плавное ускорение и торможение\n• Поддерживайте постоянную скорость\n• Избегайте резких маневров\n\n⛽ **Выбор топлива:**\n• Используйте качественное топливо (AI-95/98)\n• Заправляйтесь на проверенных заправках\n• Следите за акциями и скидками\n\n🔧 **Техническое состояние:**\n• Регулярно проверяйте давление в шинах\n• Своевременно меняйте воздушный фильтр\n• Используйте правильное моторное масло\n\n💡 Экономия может составить до 15-20%!';
    } else if (lowerMessage.contains('заправк') ||
        lowerMessage.contains('станция')) {
      return 'В приложении PoCho доступно более 500 заправок по всему Узбекистану!\n\n📍 **Рядом с вами:**\n• PoCho City Station - 2.5 км\n• Highway Fuel - 5.1 км\n• Ring Road Gas - 7.3 км\n\n🔍 Я могу помочь найти:\n• Ближайшие заправки\n• Заправки с определенным типом топлива\n• Круглосуточные заправки\n• Заправки с лучшими отзывами\n\nЧто именно вас интересует?';
    } else {
      return 'Понял ваш вопрос! Я могу помочь с:\n\n⛽ Поиском заправок и ценами\n🗺️ Построением маршрутов\n💡 Советами по экономии топлива\n📊 Информацией о качестве топлива\n🚗 Рекомендациями по выбору заправок\n\nЗадайте более конкретный вопрос, и я дам подробный ответ!';
    }
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
    });
    // TODO: Начать запись голоса
  }

  void _stopVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Остановить запись и отправить
    final appState = Provider.of<AppState>(context, listen: false);
    _sendMessage(appState.t('ai_voice_message'));
  }

  void _cancelVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                )
                .animate(
                  onPlay: (controller) {
                    controller.repeat();
                  },
                )
                .shimmer(duration: 2000.ms, delay: 300.ms),
            const SizedBox(width: 12),
            Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context, listen: false);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.t('ai_assistant_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      appState.t('ai_assistant_subtitle'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context, listen: false);
              return IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: appState.t('ai_history'),
                onPressed: _showHistory,
              );
            },
          ),
          Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context, listen: false);
              return IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                    tooltip: appState.t('ai_menu'),
                onPressed: () {
                  _showMenu();
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Быстрые вопросы (только если нет сообщений кроме приветствия)
          if (_messages.length <= 1)
            Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context, listen: false);
                final quickQuestions = _getQuickQuestions(appState);
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          appState.t('ai_quick_questions'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(quickQuestions.length, (
                            index,
                          ) {
                            final question = quickQuestions[index];
                            return _QuickQuestionCard(
                              question: question,
                              onTap: () => _sendMessage(question.text),
                            )
                                .animate()
                                .fadeIn(
                                  duration: 300.ms,
                                  delay: (index * 100).ms,
                                )
                                .slideX(
                                  begin: -0.2,
                                  end: 0,
                                  delay: (index * 100).ms,
                                );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: -0.1, end: 0);
              },
            ),
          // Список сообщений
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _TypingIndicator()
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.2, end: 0);
                }
                final message = _messages[index];
                return _MessageBubble(message: message, index: index)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                    .slideX(
                      begin: message.isUser ? 0.2 : -0.2,
                      end: 0,
                      delay: (index * 50).ms,
                    );
              },
            ),
          ),
          // Индикатор записи голоса
          if (_isRecording)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                      .animate(
                        onPlay: (controller) {
                          controller.repeat();
                        },
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(context, listen: false);
                        return Text(
                          appState.t('ai_voice_recording'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context, listen: false);
                      return TextButton(
                        onPressed: _cancelVoiceRecording,
                        child: Text(appState.t('ai_cancel')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context, listen: false);
                      return ElevatedButton(
                        onPressed: _stopVoiceRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(appState.t('ai_send')),
                      );
                    },
                  ),
                ],
              ),
            ),
          // Поле ввода
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Кнопка голосового ввода
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _startVoiceRecording,
                        onLongPress: _startVoiceRecording,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Поле ввода
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Builder(
                          builder: (context) {
                            final appState = Provider.of<AppState>(context, listen: false);
                            return TextField(
                              controller: _controller,
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: _sendMessage,
                              decoration: InputDecoration(
                                hintText: appState.t('ai_ask_question'),
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF111827),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Кнопка отправки
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _hasText
                          ? Material(
                              key: const ValueKey('send'),
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _sendMessage(_controller.text),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1565C0),
                                        Color(0xFF42A5F5),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu() {
    ModernBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context, listen: false);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModernBottomSheetOption(
                    icon: Icons.delete_outline_rounded,
                    title: appState.t('ai_clear_history'),
                    iconColor: Colors.red,
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _clearHistory();
                    },
                  ),
                  ModernBottomSheetOption(
                    icon: Icons.feedback_outlined,
                    title: appState.t('ai_feedback'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Открыть форму отзыва
                    },
                  ),
                  ModernBottomSheetOption(
                    icon: Icons.help_outline_rounded,
                    title: appState.t('ai_help'),
                    iconColor: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Показать справку
                    },
                  ),
                ],
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _showHistory() {
    final appState = Provider.of<AppState>(context, listen: false);
    // Мок данные истории (в реальном приложении загружать из хранилища)
    final historyItems = [
      _HistoryItem(
        title: appState.t('ai_dialog_search_stations'),
        preview: appState.t('ai_quick_question_cheap_station'),
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _HistoryItem(
        title: appState.t('ai_dialog_fuel_saving'),
        preview: appState.t('ai_quick_question_fuel_saving'),
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      _HistoryItem(
        title: appState.t('ai_dialog_route'),
        preview: appState.t('ai_quick_question_fast_route'),
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    ModernBottomSheet.show(
      context: context,
      title: appState.t('ai_dialog_history'),
      showCloseButton: true,
      isScrollControlled: true,
      maxHeight: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Spacer(),
                Builder(
                  builder: (context) {
                    final appState = Provider.of<AppState>(context, listen: false);
                    return TextButton(
                      onPressed: () {
                        // TODO: Очистить всю историю
                        Navigator.pop(context);
                        ModernSnackBar.showSuccess(
                          context,
                          message: appState.t('ai_history_cleared'),
                        );
                      },
                      child: Text(appState.t('ai_clear_all')),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: historyItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final appState = Provider.of<AppState>(context, listen: false);
                            return Text(
                              appState.t('ai_history_empty'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: historyItems.length,
                    itemBuilder: (context, index) {
                      final item = historyItems[index];
                      return _HistoryItemCard(
                            item: item,
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Загрузить диалог из истории
                            },
                          )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                          .slideX(
                            begin: -0.2,
                            end: 0,
                            delay: (index * 50).ms,
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    final appState = Provider.of<AppState>(context, listen: false);
    ModernDialog.show(
      context: context,
      title: appState.t('ai_clear_history_confirm'),
      content: appState.t('ai_clear_history_content'),
      icon: Icons.delete_sweep_rounded,
      iconColor: Colors.orange,
      primaryAction: DialogAction(
        label: appState.t('ai_clear_history'),
        onPressed: () {
          setState(() {
            _messages.clear();
            _addWelcomeMessage();
          });
        },
        isDestructive: true,
      ),
      secondaryAction: DialogAction(
        label: appState.t('cancel'),
        onPressed: () {},
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class QuickQuestion {
  final IconData icon;
  final String text;
  final Color color;

  QuickQuestion({required this.icon, required this.text, required this.color});
}

class _QuickQuestionCard extends StatelessWidget {
  const _QuickQuestionCard({required this.question, required this.onTap});

  final QuickQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Адаптивная ширина: минимум 140px, максимум 48% от ширины экрана
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 60) / 2; // 2 колонки с отступами

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: cardWidth.clamp(140.0, double.infinity),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: question.color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: question.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: question.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(question.icon, color: question.color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              question.text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.index});

  final ChatMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ).copyWith(bottomRight: const Radius.circular(4)),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    20,
                  ).copyWith(bottomLeft: const Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111827),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                20,
              ).copyWith(bottomLeft: const Radius.circular(4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 600.ms, delay: delay.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}

class _HistoryItem {
  _HistoryItem({
    required this.title,
    required this.preview,
    required this.timestamp,
  });

  final String title;
  final String preview;
  final DateTime timestamp;
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({required this.item, required this.onTap});

  final _HistoryItem item;
  final VoidCallback onTap;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${_pluralize(difference.inDays, 'день', 'дня', 'дней')} назад';
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }

  String _pluralize(int count, String one, String few, String many) {
    if (count % 10 == 1 && count % 100 != 11) return one;
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return few;
    }
    return many;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.chat_bubble_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            item.preview,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(item.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
