import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/auth_repository.dart';
import '../../exceptions/auth_exceptions.dart';
import '../../widgets/modern_dialog.dart';
import '../../widgets/modern_snackbar.dart';
import '../../widgets/app_logo.dart';
import '../../services/token_storage.dart';
import '../main_shell.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  static const String routeName = '/otp';

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  bool _isCodeComplete = false;
  bool _isLoading = false;
  Timer? _resendTimer;
  int _resendCountdown = 60; // 60 секунд
  String _phoneNumber = '';
  bool _isRegistered = false;
  bool _codeSent = false;
  late final AuthRepository _authRepository;
  late final TokenStorage _tokenStorage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Инициализируем данные из аргументов только один раз
    if (_phoneNumber.isEmpty) {
      final route = ModalRoute.of(context);
      final arguments = route?.settings.arguments;

      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📥 OTP Screen: Получение аргументов');
        print('   Route: ${route?.settings.name}');
        print('   Arguments type: ${arguments.runtimeType}');
        print('   Arguments: $arguments');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      if (arguments is Map<String, dynamic>) {
        _phoneNumber = arguments['phone'] as String? ?? '';
        _isRegistered = arguments['isRegistered'] as bool? ?? false;

        if (kDebugMode) {
          print('✅ Получены аргументы из Map:');
          print('   phone: $_phoneNumber');
          print('   phone length: ${_phoneNumber.length}');
          print('   isRegistered: $_isRegistered');
        }
      } else if (arguments is String) {
        // Поддержка старого формата для обратной совместимости
        _phoneNumber = arguments;
        _isRegistered = false;

        if (kDebugMode) {
          print('✅ Получены аргументы из String:');
          print('   phone: $_phoneNumber');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Аргументы не найдены или неверного типа');
          print('   Arguments: $arguments');
        }
      }

      // Проверка, что номер телефона получен
      if (_phoneNumber.isEmpty) {
        if (kDebugMode) {
          print('❌ ОШИБКА: Номер телефона пустой после получения аргументов!');
          print('   Попытка получить из route settings...');
        }

        // Попытка получить из route settings напрямую
        final routeSettings = route?.settings;
        if (routeSettings?.arguments is Map<String, dynamic>) {
          final routeArgs = routeSettings!.arguments as Map<String, dynamic>;
          _phoneNumber = routeArgs['phone'] as String? ?? '';
          _isRegistered = routeArgs['isRegistered'] as bool? ?? false;

          if (kDebugMode) {
            print('   Из route settings: phone=$_phoneNumber');
          }
        }
      }

      // Отправляем код после получения номера телефона
      if (_phoneNumber.isNotEmpty && !_codeSent) {
        if (kDebugMode) {
          print('✅ Номер телефона получен, запускаем отправку кода');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendCodeOnInit();
        });
      } else if (_phoneNumber.isNotEmpty && _codeSent && _resendTimer == null) {
        // Если код уже был отправлен, но таймер не запущен, запускаем его
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startResendTimer();
        });
      } else if (_phoneNumber.isEmpty) {
        if (kDebugMode) {
          print('❌ КРИТИЧЕСКАЯ ОШИБКА: Номер телефона не получен!');
        }
      }
    } else {
      if (kDebugMode) {
        print('ℹ️ Номер телефона уже установлен: $_phoneNumber');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _authRepository = di.getIt<AuthRepository>();
    _tokenStorage = di.getIt<TokenStorage>();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    // Автофокус на первое поле
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  Future<void> _sendCodeOnInit() async {
    // Код уже отправлен на предыдущем экране (phone_auth_screen)
    // Просто запускаем таймер и помечаем, что код отправлен
    if (_phoneNumber.isNotEmpty && !_codeSent) {
      if (kDebugMode) {
        print('ℹ️ Код уже отправлен на предыдущем экране, запускаем таймер');
      }
      setState(() {
        _codeSent = true;
      });
      // Запускаем таймер обратного отсчета
      _startResendTimer();
    } else if (_phoneNumber.isNotEmpty && _codeSent && _resendTimer == null) {
      // Если код был отправлен, но таймер не запущен, запускаем его
      _startResendTimer();
    }
  }

  void _startResendTimer() {
    if (!mounted) return;

    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            // Обновляем состояние для активации кнопки повтора
          });
        }
      }
    });
  }

  Future<void> _resendCode() async {
    // Разрешаем повторную отправку если таймер истек или не запущен
    if ((_resendCountdown == 0 || _resendTimer == null) &&
        !_isLoading &&
        _phoneNumber.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authRepository.sendCode(_phoneNumber);
        setState(() {
          _codeSent = true;
        });
        _startResendTimer();
        if (mounted) {
          ModernSnackBar.showSuccess(
            context,
            message: 'Код отправлен повторно',
            duration: const Duration(seconds: 2),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ModernSnackBar.showError(
            context,
            message: e.message,
            duration: const Duration(seconds: 3),
          );
        }
      } catch (e) {
        if (mounted) {
          ModernSnackBar.showError(
            context,
            message: 'Ошибка при отправке кода',
            duration: const Duration(seconds: 3),
          );
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

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _buttonAnimationController.dispose();
    super.dispose();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _checkCodeComplete();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _checkCodeComplete();
  }

  void _checkCodeComplete() {
    final complete = _enteredCode.length == 4;
    if (complete != _isCodeComplete) {
      setState(() {
        _isCodeComplete = complete;
      });
    }
  }

  Future<void> _onVerify() async {
    // Убираем проверку _codeSent, так как код может быть введен даже если отправка не удалась
    if (_isCodeComplete && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      try {
        final code = _enteredCode;

        // Проверка, что номер телефона не пустой
        if (_phoneNumber.isEmpty) {
          if (kDebugMode) {
            print('❌ ОШИБКА: Номер телефона пустой!');
          }
          _showErrorDialog(
            'Ошибка: номер телефона не найден. Пожалуйста, вернитесь назад и введите номер снова.',
          );
          return;
        }

        // Проверка, что код не пустой
        if (code.isEmpty || code.length != 4) {
          if (kDebugMode) {
            print('❌ ОШИБКА: Код неполный!');
          }
          _showErrorDialog('Пожалуйста, введите полный код из 4 цифр.');
          return;
        }

        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('🔐 ВЕРИФИКАЦИЯ КОДА');
          print('   Phone: $_phoneNumber');
          print('   Phone length: ${_phoneNumber.length}');
          print('   Code: $code');
          print('   Code length: ${code.length}');
          print(
            '   User status: ${_isRegistered ? "зарегистрирован" : "новый пользователь"}',
          );
          print(
            '   Endpoint: ${_isRegistered ? "/api/v1/auth/login" : "/api/v1/auth/verify-code"}',
          );
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        if (_isRegistered) {
          // Вход для зарегистрированного пользователя
          if (kDebugMode) {
            print(
              '🔵 Вызов login endpoint для зарегистрированного пользователя',
            );
          }
          final response = await _authRepository.login(_phoneNumber, code);
          if (kDebugMode) {
            print('✅ Login successful, saving token...');
          }
          // Сохраняем токен
          try {
            await _tokenStorage.saveToken(
              response.accessToken,
              response.tokenType,
            );
            if (kDebugMode) {
              print('✅ Token saved successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Token save error (continuing anyway): $e');
            }
            // Продолжаем даже если не удалось сохранить токен
          }
        } else {
          // Регистрация нового пользователя
          if (kDebugMode) {
            print('🔵 Вызов verify-code endpoint для нового пользователя');
          }
          final response = await _authRepository.verifyCode(_phoneNumber, code);
          if (kDebugMode) {
            print('✅ Verify-code successful, saving token...');
          }
          // Сохраняем токен
          try {
            await _tokenStorage.saveToken(
              response.accessToken,
              response.tokenType,
            );
            if (kDebugMode) {
              print('✅ Token saved successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Token save error (continuing anyway): $e');
            }
            // Продолжаем даже если не удалось сохранить токен
          }
        }

        if (mounted) {
          if (kDebugMode) {
            print('🔵 Navigating to MainShell...');
          }
          _buttonAnimationController.forward().then((_) {
            _buttonAnimationController.reverse();
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  MainShell.routeName,
                  (route) => false,
                );
              }
            });
          });
        }
      } on InvalidCodeException catch (e) {
        if (mounted) {
          _showErrorDialog(e.message);
          // Очищаем поля
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
          setState(() {
            _isCodeComplete = false;
          });
        }
      } on AuthException catch (e) {
        if (mounted) {
          _showErrorDialog(e.message);
        }
      } catch (e) {
        if (mounted) {
          // Логируем детали ошибки для отладки
          if (kDebugMode) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('❌ OTP VERIFY ERROR');
            print('💥 Error: $e');
            print('💥 Error Type: ${e.runtimeType}');
            print('💥 StackTrace: ${StackTrace.current}');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          }
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

    return Scaffold(
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
              // Верхняя панель
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: Color(0xFF111827),
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
                                color: const Color(0xFF1565C0).withOpacity(0.3),
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
                      // Заголовок
                      Text(
                            appState.t('otp_title'),
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
                            appState.t('otp_subtitle'),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 400.ms)
                          .slideY(begin: -0.2, end: 0),
                      if (_phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_android,
                                        color: Color(0xFF1565C0),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appState.t('otp_sent_to'),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _phoneNumber,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Информация о тестовом режиме
                                  if (kDebugMode &&
                                      _phoneNumber == '+998900000000') ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFFF9800,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            color: Color(0xFFFF9800),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Тестовый режим: используйте код 1234',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange.shade900,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                      const SizedBox(height: 40),
                      // OTP поля
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          return _OtpDigitBox(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            index: index,
                            onChanged: (value) => _onDigitChanged(value, index),
                            delay: (600 + index * 100).ms,
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      // Кнопка повтора отправки с таймером
                      Center(
                        child: _resendCountdown > 0 && _resendTimer != null
                            ? RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  children: [
                                    TextSpan(text: appState.t('resend_in')),
                                    TextSpan(
                                      text:
                                          ' $_resendCountdown ${appState.t('seconds')}',
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : TextButton(
                                onPressed:
                                    (_resendCountdown == 0 ||
                                            _resendTimer == null) &&
                                        !_isLoading &&
                                        _phoneNumber.isNotEmpty
                                    ? _resendCode
                                    : null,
                                child: Text(
                                  appState.t('resend_code'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        (_resendCountdown == 0 ||
                                                _resendTimer == null) &&
                                            !_isLoading &&
                                            _phoneNumber.isNotEmpty
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                      ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),
                    ],
                  ),
                ),
              ),
              // Кнопка подтверждения
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child:
                    ScaleTransition(
                          scale: _buttonScaleAnimation,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isCodeComplete && !_isLoading)
                                  ? _onVerify
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isCodeComplete
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFFE5E7EB),
                                foregroundColor: _isCodeComplete
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: _isCodeComplete ? 4 : 0,
                                shadowColor: const Color(
                                  0xFF1565C0,
                                ).withOpacity(0.3),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          appState.t('verify'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        if (_isCodeComplete) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                                Icons.check_circle,
                                                size: 20,
                                              )
                                              .animate(
                                                onPlay: (controller) {
                                                  controller.repeat();
                                                },
                                              )
                                              .scale(
                                                begin: const Offset(1, 1),
                                                end: const Offset(1.1, 1.1),
                                                duration: 600.ms,
                                                curve: Curves.easeInOut,
                                              )
                                              .then()
                                              .scale(
                                                begin: const Offset(1.1, 1.1),
                                                end: const Offset(1, 1),
                                                duration: 600.ms,
                                              ),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 1200.ms)
                        .slideY(begin: 0.3, end: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.controller,
    required this.focusNode,
    required this.index,
    required this.onChanged,
    required this.delay,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int index;
  final ValueChanged<String> onChanged;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
          width: 64,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFF1565C0),
                  width: 2.5,
                ),
              ),
            ),
            onChanged: onChanged,
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: delay)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          delay: delay,
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
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
