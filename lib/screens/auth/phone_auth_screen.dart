import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/auth_repository.dart';
import '../../exceptions/auth_exceptions.dart';
import '../../utils/phone_number_utils.dart';
import '../../widgets/modern_dialog.dart';
import '../../widgets/ios_swipe_button.dart';
import '../../widgets/app_logo.dart';
import 'otp_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  static const String routeName = '/auth';

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  bool _isPhoneValid = false;
  bool _isLoading = false;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = di.getIt<AuthRepository>();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  String? _validateUzbekPhone(String? value) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (value == null || value.isEmpty) {
      return appState.t('enter_phone_error');
    }
    if (!PhoneNumberUtils.isValidUzbek(value)) {
      return appState.t('invalid_phone_error');
    }
    return null;
  }

  Future<void> _onContinue() async {
    if ((_formKey.currentState?.validate() ?? false) && !_isLoading) {
      // Скрываем клавиатуру перед началом загрузки
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
      });

      try {
        // prefixText '+998 ' не входит в controller — собираем E.164 без пробелов
        final cleanedPhone = PhoneNumberUtils.normalizeUzbek(
          _phoneController.text,
        );
        if (cleanedPhone == null) {
          if (mounted) {
            _showErrorDialog(
              Provider.of<AppState>(
                context,
                listen: false,
              ).t('invalid_phone_error'),
            );
          }
          return;
        }


        if (kDebugMode) {
          print('📱 Проверка регистрации для: $cleanedPhone');
        }

        // Шаг 1: Проверяем регистрацию
        final isRegistered = await _authRepository.checkRegistration(
          cleanedPhone,
        );

        if (kDebugMode) {
          print(
            '✅ Результат проверки регистрации: ${isRegistered ? "зарегистрирован" : "не зарегистрирован"}',
          );
        }

        // Шаг 2: Отправляем код подтверждения
        if (kDebugMode) {
          print('📤 Отправка кода подтверждения...');
        }
        await _authRepository.sendCode(cleanedPhone);

        if (kDebugMode) {
          print('✅ Код отправлен успешно');
          print('   Следующий шаг: ${isRegistered ? "login" : "verify-code"}');
        }

        // Шаг 3: Переходим на экран OTP
        if (mounted) {
          final arguments = {
            'phone': cleanedPhone,
            'isRegistered': isRegistered,
          };

          if (kDebugMode) {
            print('🚀 Переход на OTP экран');
            print('   Arguments: $arguments');
            print('   Phone: $cleanedPhone');
            print('   Phone length: ${cleanedPhone.length}');
            print('   IsRegistered: $isRegistered');
          }

          Navigator.of(
            context,
          ).pushNamed(OtpScreen.routeName, arguments: arguments);
        }
      } on AuthException catch (e) {
        if (mounted) {
          _showErrorDialog(e.message);
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Произошла ошибка. Попробуйте позже.');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    ModernDialog.show(
      context: context,
      title: 'Ошибка',
      content: message,
      icon: Icons.error_outline_rounded,
      iconColor: Colors.red,
      primaryAction: DialogAction(label: 'OK', onPressed: () {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool isButtonEnabled = _isPhoneValid && !_isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF5F7FB),
                Colors.white,
                const Color(0xFFF0F4F8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Верхняя панель с анимацией
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                            onPressed: _showSupportSheet,
                            child: Text(
                              appState.t('help'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideX(begin: -0.2, end: 0),
                      Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: AppLogo(color: Colors.white),
                            ),
                          )
                          .animate()
                          .scale(delay: 200.ms, duration: 500.ms)
                          .then()
                          .shimmer(duration: 2000.ms, delay: 300.ms),
                      _LanguageButton(appState: appState)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideX(begin: 0.2, end: 0),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок с анимацией
                        Text(
                              appState.t('login_title'),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                letterSpacing: -0.5,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 200.ms)
                            .slideY(begin: -0.3, end: 0),
                        const SizedBox(height: 12),
                        Text(
                              appState.t('phone_instruction'),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 400.ms)
                            .slideY(begin: -0.2, end: 0),
                        const SizedBox(height: 40),
                        // Поле ввода с анимацией
                        Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: _phoneController,
                                focusNode: _phoneFocusNode,
                                keyboardType: TextInputType.phone,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  fontSize: 20,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '+998 ',
                                  prefixStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                  hintText: 'XX XXX XX XX',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 20,
                                  ),
                                  filled: true,
                                  fillColor: _isLoading
                                      ? Colors.grey.shade100
                                      : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1565C0),
                                      width: 2,
                                    ),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: _isPhoneValid
                                      ? const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF4CAF50),
                                            )
                                            .animate()
                                            .scale(duration: 300.ms)
                                            .fadeIn()
                                      : _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF1565C0),
                                                  ),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  final valid =
                                      PhoneNumberUtils.isValidUzbek(value);
                                  if (valid != _isPhoneValid) {
                                    setState(() {
                                      _isPhoneValid = valid;
                                    });
                                    // Скрываем клавиатуру когда номер становится валидным
                                    if (valid) {
                                      _phoneFocusNode.unfocus();
                                    }
                                  }
                                },
                                validator: (value) =>
                                    _validateUzbekPhone(value),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 600.ms)
                            .slideY(begin: 0.2, end: 0)
                            .then()
                            .shimmer(
                              duration: 1500.ms,
                              delay: 800.ms,
                              color: const Color(0xFF1565C0).withOpacity(0.1),
                            ),
                      ],
                    ),
                  ),
                ),
                // Нижняя часть с кнопкой-свайпером
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      IOSSwipeButton(
                            onSwipe: _onContinue,
                            text: appState.t('continue'),
                            enabled: isButtonEnabled,
                            isLoading: _isLoading,
                            backgroundColor: const Color(0xFF1565C0),
                            disabledColor: const Color(0xFFE5E7EB),
                            textColor: Colors.white,
                            disabledTextColor: Colors.grey.shade500,
                            height: 56,
                            borderRadius: 28,
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 800.ms)
                          .slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 16),
                      Text(
                        appState.t('agreement_text'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),
                      // Временно скрыта кнопка "Публичная оферта и политика"
                      // const SizedBox(height: 6),
                      // GestureDetector(
                      //       onTap: () {
                      //         Navigator.of(
                      //           context,
                      //         ).pushNamed(TermsAndPrivacyPage.routeName);
                      //       },
                      //       child: Text(
                      //         appState.t('offer_link'),
                      //         textAlign: TextAlign.center,
                      //         style: const TextStyle(
                      //           fontSize: 12,
                      //           color: Color(0xFF1565C0),
                      //           decoration: TextDecoration.underline,
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //     )
                      //     .animate()
                      //     .fadeIn(duration: 600.ms, delay: 1200.ms)
                      //     .then()
                      //     .shimmer(
                      //       duration: 2000.ms,
                      //       delay: 1400.ms,
                      //       color: const Color(0xFF1565C0).withOpacity(0.2),
                      //     ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(context);
                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                      appState.t('auth_instruction_title'),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 400.ms)
                                    .slideY(begin: -0.2, end: 0),
                                const SizedBox(height: 20),
                                _InstructionStep(
                                  number: 1,
                                  title: appState.t(
                                    'auth_instruction_step1_title',
                                  ),
                                  description: appState.t(
                                    'auth_instruction_step1_description',
                                  ),
                                  delay: 100.ms,
                                ),
                                const SizedBox(height: 16),
                                _InstructionStep(
                                  number: 2,
                                  title: appState.t(
                                    'auth_instruction_step2_title',
                                  ),
                                  description: appState.t(
                                    'auth_instruction_step2_description',
                                  ),
                                  delay: 200.ms,
                                ),
                                const SizedBox(height: 16),
                                _InstructionStep(
                                  number: 3,
                                  title: appState.t(
                                    'auth_instruction_step3_title',
                                  ),
                                  description: appState.t(
                                    'auth_instruction_step3_description',
                                  ),
                                  delay: 300.ms,
                                ),
                                const SizedBox(height: 16),
                                _InstructionStep(
                                  number: 4,
                                  title: appState.t(
                                    'auth_instruction_step4_title',
                                  ),
                                  description: appState.t(
                                    'auth_instruction_step4_description',
                                  ),
                                  delay: 400.ms,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .slideY(
              begin: 1,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(duration: 300.ms);
      },
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.title,
    required this.description,
    required this.delay,
  });

  final int number;
  final String title;
  final String description;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: delay)
        .slideX(begin: -0.1, end: 0);
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final isUzbek = appState.language == AppLanguage.uz;
    final label = isUzbek ? 'Uzb' : 'Рус';
    final flagIcon = isUzbek ? Icons.flag : Icons.flag;

    return InkWell(
          onTap: appState.toggleLanguage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUzbek
                    ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                    : [Colors.white, Colors.white],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUzbek ? Colors.transparent : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
              boxShadow: isUzbek
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  flagIcon,
                  size: 16,
                  color: isUzbek ? Colors.white : const Color(0xFF1565C0),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isUzbek ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(
          onPlay: (controller) {
            controller.repeat();
          },
        )
        .shimmer(
          duration: 2000.ms,
          delay: 500.ms,
          color: isUzbek
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFF1565C0).withOpacity(0.1),
        );
  }
}
