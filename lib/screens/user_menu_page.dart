import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/modern_dialog.dart';
import '../di/injection_container.dart' as di;
import '../repositories/auth_repository.dart';
import '../services/token_storage.dart';
import 'auth/phone_auth_screen.dart';
import 'profile_page.dart';
import 'profile/delete_account_page.dart';
import 'global_chat/global_chat_page.dart';

class UserMenuPage extends StatefulWidget {
  const UserMenuPage({super.key});

  static const String routeName = '/user_menu';

  @override
  State<UserMenuPage> createState() => _UserMenuPageState();
}

class _UserMenuPageState extends State<UserMenuPage> {
  late final AuthRepository _authRepository;
  late final TokenStorage _tokenStorage;

  @override
  void initState() {
    super.initState();
    _authRepository = di.getIt<AuthRepository>();
    _tokenStorage = di.getIt<TokenStorage>();
  }

  Future<void> _handleLogout() async {
    // Показываем диалог подтверждения
    final shouldLogout = await ModernDialog.show<bool>(
      context: context,
      title: 'Выход',
      content: 'Вы уверены, что хотите выйти?',
      icon: Icons.logout_rounded,
      iconColor: Colors.red,
      primaryAction: DialogAction(
        label: 'Выйти',
        onPressed: () {},
        isDestructive: true,
        returnValue: true,
      ),
      secondaryAction: DialogAction(
        label: 'Отмена',
        onPressed: () {},
        returnValue: false,
      ),
    );

    if (shouldLogout != true) {
      debugPrint('Logout cancelled by user');
      return;
    }

    debugPrint('Starting logout process...');

    try {
      // Вызываем logout на сервере
      await _authRepository.logout();
      debugPrint('Logout API call successful');
    } catch (e) {
      debugPrint('Logout API error (ignored): $e');
      // Игнорируем ошибки logout
    }

    // Удаляем токен локально
    await _tokenStorage.clearToken();
    debugPrint('Token cleared from local storage');

    // Переходим на экран авторизации
    if (mounted) {
      debugPrint('Navigating to auth screen...');
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(PhoneAuthScreen.routeName, (route) => false);
    } else {
      debugPrint('Widget not mounted, cannot navigate');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                        'Меню',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.2, end: 0),
                  const Spacer(),
                  IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.2 : 0.05,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .scale(delay: 200.ms),
                ],
              ),
            ),
            // Профиль пользователя с балансом
            Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: isSmallScreen ? 56 : 64,
                            height: isSmallScreen ? 56 : 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: isSmallScreen ? 28 : 32,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Водитель PoCho',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Text(
                                  '+998 ** *** ** **',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      // Баланс
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Заголовок "Баланс" по центру
                            Text(
                              'Баланс',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            // Иконка и сумма в одной строке
                            Row(
                              children: [
                                // Иконка кошелька
                                Container(
                                  padding: EdgeInsets.all(
                                    isSmallScreen ? 10 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 12 : 16),
                                // Сумма
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '1 000 000 сум',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 22 : 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.8,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            // Меню
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _MenuSection(
                    title: 'Основное',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline,
                        title: 'Профиль',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pushNamed(ProfilePage.routeName);
                        },
                      ),
                      _MenuItem(
                        icon: Icons.favorite_outline,
                        title: appState.t('favorites'),
                        onTap: () {
                          Navigator.of(context).pop();
                          // TODO: перейти на избранное
                        },
                      ),
                      _MenuItem(
                        icon: Icons.history,
                        title: 'История',
                        onTap: () {
                          // TODO: открыть историю
                        },
                      ),
                      _MenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Глобальный чат',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pushNamed(GlobalChatPage.routeName);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _MenuSection(
                    title: 'Настройки',
                    items: [
                      _MenuItem(
                        icon: Icons.language,
                        title: appState.t('language'),
                        subtitle: appState.language == AppLanguage.ru
                            ? appState.t('russian')
                            : appState.t('uzbek'),
                        onTap: () {
                          appState.toggleLanguage();
                        },
                      ),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Уведомления',
                        onTap: () {
                          // TODO: открыть настройки уведомлений
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _MenuSection(
                    title: 'Помощь',
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline,
                        title: 'Помощь и поддержка',
                        onTap: () {
                          // TODO: открыть помощь
                        },
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        title: 'О приложении',
                        onTap: () {
                          // TODO: открыть информацию
                        },
                      ),
                      _MenuItem(
                        icon: Icons.description_outlined,
                        title: 'Пользовательское соглашение',
                        onTap: () {
                          // TODO: открыть соглашение
                        },
                      ),
                      _MenuItem(
                        icon: Icons.delete_forever_outlined,
                        title: appState.t('delete_account_title'),
                        iconColor: Colors.red,
                        textColor: Colors.red,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            DeleteAccountPage.routeName,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Выход
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;

                      return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: _MenuItem(
                              icon: Icons.logout,
                              title: 'Выйти',
                              iconColor: Colors.red,
                              textColor: Colors.red,
                              onTap: _handleLogout,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 600.ms)
                          .slideY(begin: 0.2, end: 0);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      item,
                      if (index < items.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 56,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade200,
                        ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF1565C0)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          textColor ??
                          (isDark ? Colors.white : const Color(0xFF111827)),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
