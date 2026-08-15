import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../services/api_client.dart';
import '../utils/image_url_helper.dart';

import '../di/injection_container.dart' as di;
import '../services/profile_service.dart';
import '../models/profile/user_profile_response.dart';
import '../models/profile/profile_settings.dart';
import '../exceptions/auth_exceptions.dart';
import '../widgets/modern_dialog.dart';
import '../widgets/modern_snackbar.dart';
import '../widgets/modern_bottom_sheet.dart';
import '../widgets/safe_network_image.dart';
import '../repositories/auth_repository.dart';
import '../services/token_storage.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../services/delivery_service.dart';
import '../state/app_state.dart';
import 'support/support_tickets_page.dart';
import 'delivery/my_orders_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const String routeName = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _scrollController = ScrollController();

  late ProfileService _profileService;
  late AuthRepository _authRepository;
  late TokenStorage _tokenStorage;
  late DeliveryService _deliveryService;
  UserProfileResponse? _profileData;
  bool _isLoading = true;
  bool _isError = false;
  bool _isDriver = false;
  bool _isCheckingDriver = true;

  @override
  void initState() {
    super.initState();
    _profileService = di.getIt<ProfileService>();
    _authRepository = di.getIt<AuthRepository>();
    _tokenStorage = di.getIt<TokenStorage>();
    _deliveryService = di.getIt<DeliveryService>();
    _checkIfDriver();
    _loadProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkIfDriver() async {
    final isDriver = await _deliveryService.isRegisteredDriver();
    if (mounted) {
      setState(() {
        _isDriver = isDriver;
        _isCheckingDriver = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final profileData = await _profileService.getProfile();
      if (!mounted) return;
      setState(() {
        _profileData = profileData;
        _isLoading = false;
      });
    } on UnauthorizedException {
      // Если токен недействителен, вызываем logout и перенаправляем на авторизацию
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = false;
      });

      try {
        // Вызываем logout на сервере
        await _authRepository.logout();
      } catch (e) {
        // Игнорируем ошибки logout
      }

      // Удаляем токен локально
      await _tokenStorage.clearToken();

      // Переходим на экран авторизации
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(PhoneAuthScreen.routeName, (route) => false);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
      });
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernDialog.show(
          context: context,
          title: appState.t('profile_upload_error'),
          content: e.message,
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
      });
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernDialog.show(
          context: context,
          title: appState.t('profile_upload_error'),
          content: appState.t('profile_load_error'),
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final appState = Provider.of<AppState>(context, listen: false);
    // Показываем диалог подтверждения
    final shouldLogout = await ModernDialog.show<bool>(
      context: context,
      title: appState.t('profile_logout'),
      content: 'Вы уверены, что хотите выйти?', // TODO: добавить перевод
      icon: Icons.logout_rounded,
      iconColor: Colors.red,
      primaryAction: DialogAction(
        label: appState.t('profile_logout'),
        onPressed: () {},
        isDestructive: true,
        returnValue: true,
      ),
      secondaryAction: DialogAction(
        label: 'Отмена', // TODO: добавить перевод
        onPressed: () {},
        returnValue: false,
      ),
    );

    if (shouldLogout != true) return;

    try {
      // Вызываем logout на сервере
      await _authRepository.logout();
    } catch (e) {
      // Игнорируем ошибки logout
    }

    // Удаляем токен локально
    await _tokenStorage.clearToken();

    // Переходим на экран авторизации
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(PhoneAuthScreen.routeName, (route) => false);
    }
  }

  Future<void> _pickAvatar(String source) async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      // Выбираем источник изображения
      if (source == 'gallery') {
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 800,
          maxHeight: 800,
        );
      } else if (source == 'camera') {
        pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 800,
          maxHeight: 800,
        );
      }

      if (pickedFile == null) {
        return; // Пользователь отменил выбор
      }

      final File imageFile = File(pickedFile.path);

      // Проверяем формат файла
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        if (mounted) {
          ModernDialog.show(
            context: context,
            title: 'Ошибка',
            content: 'Поддерживаются только форматы: JPEG, PNG, WEBP',
            icon: Icons.error_outline_rounded,
          );
        }
        return;
      }

      // Показываем индикатор загрузки
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1565C0)),
          ),
        );
      }

      try {
        // Загружаем аватар на сервер
        await _profileService.uploadAvatar(imageFile);

        // Закрываем индикатор загрузки
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Перезагружаем профиль для получения обновленных данных
        await _loadProfile();

        // Показываем уведомление об успехе
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ModernSnackBar.showSuccess(
            context,
            message: appState.t('profile_avatar_updated'),
          );
        }
      } catch (e) {
        // Закрываем индикатор загрузки
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Показываем ошибку
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ModernDialog.show(
            context: context,
            title: appState.t('profile_upload_error'),
            content: e.toString().replaceAll('Exception: ', ''),
            icon: Icons.error_outline_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernDialog.show(
          context: context,
          title: appState.t('profile_upload_error'),
          content: '${appState.t('profile_image_error')}: ${e.toString()}',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _pickImage(String source, bool isPassport) async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      // Выбираем источник изображения
      if (source == 'gallery') {
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } else if (source == 'camera') {
        pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      }

      if (pickedFile == null) {
        return; // Пользователь отменил выбор
      }

      final File imageFile = File(pickedFile.path);

      // Проверяем формат файла
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        if (mounted) {
          ModernDialog.show(
            context: context,
            title: 'Ошибка',
            content: 'Поддерживаются только форматы: JPEG, PNG, WEBP',
            icon: Icons.error_outline_rounded,
          );
        }
        return;
      }

      // Показываем индикатор загрузки
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1565C0)),
          ),
        );
      }

      try {
        // Загружаем файл на сервер
        if (isPassport) {
          await _profileService.uploadPassport(imageFile);
        } else {
          await _profileService.uploadDrivingLicense(imageFile);
        }

        // Закрываем индикатор загрузки
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Перезагружаем профиль для получения обновленных данных
        await _loadProfile();

        // Показываем уведомление об успехе
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ModernSnackBar.showSuccess(
            context,
            message: isPassport
                ? appState.t('profile_passport_uploaded')
                : appState.t('profile_license_uploaded'),
          );
        }
      } catch (e) {
        // Закрываем индикатор загрузки
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Показываем ошибку
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ModernDialog.show(
            context: context,
            title: appState.t('profile_upload_error'),
            content: e.toString().replaceAll('Exception: ', ''),
            icon: Icons.error_outline_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernDialog.show(
          context: context,
          title: appState.t('profile_upload_error'),
          content: '${appState.t('profile_image_error')}: ${e.toString()}',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _showAvatarPicker(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    ModernBottomSheet.show(
      context: context,
      title: appState.t('profile_select_photo'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModernBottomSheetOption(
            icon: Icons.photo_library,
            title: appState.t('profile_gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickAvatar('gallery');
            },
          ),
          ModernBottomSheetOption(
            icon: Icons.camera_alt,
            title: appState.t('profile_camera'),
            onTap: () {
              Navigator.pop(context);
              _pickAvatar('camera');
            },
          ),
          if (_profileData?.user.avatar != null &&
              _profileData!.user.avatar!.isNotEmpty)
            ModernBottomSheetOption(
              icon: Icons.delete_outline,
              title: appState.t('profile_delete_photo'),
              iconColor: Colors.red,
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать удаление аватара через API
              },
            ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context, bool isPassport) {
    final appState = Provider.of<AppState>(context, listen: false);
    ModernBottomSheet.show(
      context: context,
      title: isPassport
          ? appState.t('profile_select_passport_photo')
          : appState.t('profile_select_license_photo'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModernBottomSheetOption(
            icon: Icons.photo_library,
            title: appState.t('profile_gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage('gallery', isPassport);
            },
          ),
          ModernBottomSheetOption(
            icon: Icons.camera_alt,
            title: appState.t('profile_camera'),
            onTap: () {
              Navigator.pop(context);
              _pickImage('camera', isPassport);
            },
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar с градиентом
          SliverAppBar(
            expandedHeight: isSmallScreen ? 320 : 360,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1565C0),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1565C0),
                      Color(0xFF42A5F5),
                      Color(0xFF90CAF9),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 12 : 16,
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 16 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        // Аватар и имя
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showAvatarPicker(context),
                              child: Stack(
                                children: [
                                  Container(
                                    width: isSmallScreen ? 80 : 100,
                                    height: isSmallScreen ? 80 : 100,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.white, Colors.white70],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child:
                                        _profileData?.user.avatar != null &&
                                            _profileData!
                                                .user
                                                .avatar!
                                                .isNotEmpty
                                        ? SafeAvatar(
                                            imageUrl: _getFullImageUrl(
                                              _profileData!.user.avatar,
                                            ),
                                            radius: isSmallScreen ? 40 : 50,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            placeholderIcon: Icons.person,
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Color(0xFF1565C0),
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: isSmallScreen ? 28 : 32,
                                      height: isSmallScreen ? 28 : 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF1565C0),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 16 : 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profileData?.user.name ??
                                        appState.t('profile_user'),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 22 : 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.workspace_premium_rounded,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _profileData?.user.level ??
                                              appState.t('profile_beginner'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        // Статистика
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 14,
                            vertical: isSmallScreen ? 12 : 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Flexible(
                                child: _StatItem(
                                  icon: Icons.local_gas_station_rounded,
                                  value:
                                      '${_profileData?.user.totalStationsVisited ?? 0}',
                                  label: appState.t('profile_stations_visited'),
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: isSmallScreen ? 35 : 40,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              Flexible(
                                child: _StatItem(
                                  icon: Icons.favorite_rounded,
                                  value:
                                      '0', // TODO: Добавить поле избранных в API
                                  label: appState.t('profile_favorites_count'),
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: isSmallScreen ? 35 : 40,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              Flexible(
                                child: _StatItem(
                                  icon: Icons.star_rounded,
                                  value:
                                      '${(_profileData?.user.rating ?? 0.0).toStringAsFixed(1)}',
                                  label: appState.t('profile_rating'),
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Контент
          SliverToBoxAdapter(
            child: _isLoading
                ? Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  )
                : _isError
                ? Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Consumer<AppState>(
                          builder: (context, appState, _) {
                            return Column(
                              children: [
                                Text(
                                  appState.t('profile_load_error'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                  ),
                                  child: Text(appState.t('profile_try_again')),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Баланс - стилизованный блок
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isSmallScreen ? 16 : 20,
                          isSmallScreen ? 16 : 20,
                          isSmallScreen ? 16 : 20,
                          isSmallScreen ? 0 : 0,
                        ),
                        child:
                            Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 20 : 24,
                                    vertical: isSmallScreen ? 18 : 22,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1565C0),
                                        Color(0xFF1976D2),
                                        Color(0xFF42A5F5),
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF1565C0,
                                        ).withOpacity(0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Заголовок "Баланс" по центру
                                      Text(
                                        'Баланс',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 14,
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
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons
                                                  .account_balance_wallet_rounded,
                                              color: Colors.white,
                                              size: isSmallScreen ? 20 : 24,
                                            ),
                                          ),
                                          SizedBox(
                                            width: isSmallScreen ? 12 : 16,
                                          ),
                                          // Сумма
                                          Expanded(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '${_formatAmount(_profileData?.user.balance ?? 0.0)} сум',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen
                                                      ? 22
                                                      : 28,
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
                                )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 200.ms)
                                .slideY(begin: 0.2, end: 0)
                                .scale(delay: 200.ms, duration: 300.ms),
                      ),
                      // Мои заказы (для водителей - заказы водителя, для пользователей - заказы доставки)
                      if (!_isCheckingDriver)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            isSmallScreen ? 16 : 20,
                            isSmallScreen ? 12 : 16,
                            isSmallScreen ? 16 : 20,
                            0,
                          ),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 0,
                            shadowColor: Colors.black.withOpacity(0.06),
                            child: InkWell(
                              onTap: () {
                                if (_isDriver) {
                                  Navigator.of(
                                    context,
                                  ).pushNamed('/delivery/driver-orders');
                                } else {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(MyOrdersPage.routeName);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 20,
                                  vertical: isSmallScreen ? 14 : 16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF1565C0,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1565C0,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long_rounded,
                                        color: Color(0xFF1565C0),
                                        size: 22,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 12 : 16),
                                    Expanded(
                                      child: Text(
                                        appState.t('profile_my_orders'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            // Основная информация
                            _buildSectionTitle(
                              appState.t('profile_main_info'),
                              isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            _buildInfoCard(
                              icon: Icons.person_outline_rounded,
                              label: appState.t('profile_name'),
                              value:
                                  _profileData?.user.name ??
                                  appState.t('profile_not_specified'),
                              isSmallScreen: isSmallScreen,
                              onEdit: () => _showEditDialog(
                                context,
                                'name',
                                _profileData?.user.name ?? '',
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            _buildInfoCard(
                              icon: Icons.phone_outlined,
                              label: appState.t('profile_phone'),
                              value:
                                  _profileData?.user.phone ??
                                  appState.t('profile_not_specified'),
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            _buildInfoCard(
                              icon: Icons.email_outlined,
                              label: appState.t('profile_email'),
                              value:
                                  _profileData?.user.email ??
                                  appState.t('profile_not_specified'),
                              isSmallScreen: isSmallScreen,
                              onEdit: () => _showEditDialog(
                                context,
                                'email',
                                _profileData?.user.email ?? '',
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            // Кнопка смены языка
                            _buildLanguageSelector(isSmallScreen),
                            // Верификация документов (скрываем для водителей)
                            if (!_isDriver && !_isCheckingDriver) ...[
                              SizedBox(height: isSmallScreen ? 24 : 32),
                              _buildSectionTitle(
                                appState.t('profile_document_verification'),
                                isSmallScreen,
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              _buildDocumentCard(
                                title: appState.t('profile_passport'),
                                icon: Icons.credit_card_rounded,
                                image: _profileData
                                    ?.profile
                                    .documents
                                    .passport
                                    .imageUrl,
                                isVerified:
                                    _profileData
                                        ?.profile
                                        .documents
                                        .passport
                                        .verified ??
                                    false,
                                onTap: () => _showImagePicker(context, true),
                                isSmallScreen: isSmallScreen,
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              _buildDocumentCard(
                                title: appState.t('profile_driving_license'),
                                icon: Icons.drive_eta_rounded,
                                image: _profileData
                                    ?.profile
                                    .documents
                                    .drivingLicense
                                    .imageUrl,
                                isVerified:
                                    _profileData
                                        ?.profile
                                        .documents
                                        .drivingLicense
                                        .verified ??
                                    false,
                                onTap: () => _showImagePicker(context, false),
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            // Настройки
                            _buildSectionTitle(
                              appState.t('profile_settings'),
                              isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            _buildNotificationSwitch(
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            // Техническая поддержка
                            Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1565C0),
                                        Color(0xFF42A5F5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF1565C0,
                                        ).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          SupportTicketsPage.routeName,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 16 : 20,
                                          vertical: isSmallScreen ? 16 : 18,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.support_agent_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              appState.t('profile_support'),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 500.ms)
                                .slideY(begin: 0.2, end: 0),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            // Кнопка выхода
                            SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _handleLogout,
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 16 : 18,
                                      ),
                                      side: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.logout_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          appState.t('profile_logout'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 600.ms)
                                .slideY(begin: 0.2, end: 0),
                            SizedBox(height: isSmallScreen ? 20 : 24),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: 4,
          height: isSmallScreen ? 18 : 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    String? image,
    required bool isVerified,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isVerified
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [
                                const Color(0xFF1565C0),
                                const Color(0xFF42A5F5),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isVerified
                                      ? Colors.green
                                      : const Color(0xFF1565C0))
                                  .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        _buildDocumentStatusBadge(
                          image: image,
                          isVerified: isVerified,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              if (image != null && image.isNotEmpty) ...[
                // Превью загруженного изображения
                Container(
                  height: isSmallScreen ? 120 : 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildDocumentImage(image),
                  ),
                ),
              ] else ...[
                // Плейсхолдер, если документ не загружен
                Container(
                  height: isSmallScreen ? 120 : 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Consumer<AppState>(
                        builder: (context, appState, _) {
                          return Column(
                            children: [
                              Text(
                                appState.t('profile_document_not_uploaded'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                appState.t('profile_click_to_upload'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(bool isSmallScreen) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: Color(0xFF1565C0),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 16 : 20),
                  Expanded(
                    child: Text(
                      appState.t('language'),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Row(
                children: [
                  Expanded(
                    child: _LanguageChip(
                      label: appState.t('russian'),
                      selected: appState.language == AppLanguage.ru,
                      onTap: () {
                        if (appState.language != AppLanguage.ru) {
                          appState.toggleLanguage();
                        }
                      },
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: _LanguageChip(
                      label: appState.t('uzbek'),
                      selected: appState.language == AppLanguage.uz,
                      onTap: () {
                        if (appState.language != AppLanguage.uz) {
                          appState.toggleLanguage();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
          ),
          SizedBox(width: isSmallScreen ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: Colors.grey.shade600,
              ),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String field,
    String currentValue,
  ) {
    final controller = TextEditingController(text: currentValue);
    final isEmail = field == 'email';
    final label = field == 'name' ? 'Имя' : 'Email';
    final icon = field == 'name'
        ? Icons.person_outline_rounded
        : Icons.email_outlined;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF1565C0),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Редактировать $label',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Поле ввода
                TextField(
                  controller: controller,
                  keyboardType: isEmail
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: 'Введите $label',
                    prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF1565C0),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 24),
                // Кнопки
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newValue = controller.text.trim();
                          if (newValue.isEmpty) {
                            ModernSnackBar.showError(
                              context,
                              message: 'Поле $label не может быть пустым',
                            );
                            return;
                          }

                          if (isEmail && !_isValidEmail(newValue)) {
                            ModernSnackBar.showError(
                              context,
                              message: 'Введите корректный email адрес',
                            );
                            return;
                          }

                          Navigator.of(context).pop();

                          try {
                            if (field == 'name') {
                              await _profileService.updateName(newValue);
                            } else {
                              await _profileService.updateEmail(newValue);
                            }

                            // Перезагружаем профиль
                            await _loadProfile();

                            if (mounted) {
                              ModernSnackBar.showSuccess(
                                context,
                                message: '$label успешно обновлен',
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ModernDialog.show(
                                context: context,
                                title: 'Ошибка',
                                content: e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                ),
                                icon: Icons.error_outline_rounded,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _getFullImageUrl(String? imageUrl) {
    return ImageUrlHelper.getFullImageUrlOrEmpty(imageUrl);
  }

  Widget _buildDocumentImage(String imageUrl) {
    final fullUrl = _getFullImageUrl(imageUrl);

    if (fullUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            size: 40,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      headers: {
        // Добавляем заголовки для загрузки изображений
        'Accept': 'image/*',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade50,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF1565C0),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('❌ IMAGE LOAD ERROR');
          print('📤 Original URL: $imageUrl');
          print('📤 Full URL: $fullUrl');
          print('💥 Error: $error');
          print('💥 Error Type: ${error.runtimeType}');
          print('💥 StackTrace: $stackTrace');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
        return Container(
          color: Colors.grey.shade50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ошибка загрузки',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (kDebugMode) ...[
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    fullUrl,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentStatusBadge({String? image, required bool isVerified}) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Определяем статус документа
        String statusText;
        IconData statusIcon;
        Color statusColor;
        Color backgroundColor;
        Color borderColor;

        if (image == null || image.isEmpty) {
          // Документ не загружен или был отклонен
          statusText = 'Не загружен'; // TODO: добавить перевод
          statusIcon = Icons.upload_file_rounded;
          statusColor = Colors.grey.shade700;
          backgroundColor = Colors.grey.shade50;
          borderColor = Colors.grey.shade200;
        } else if (isVerified) {
          // Документ верифицирован
          statusText = 'Верифицирован'; // TODO: добавить перевод
          statusIcon = Icons.check_circle_rounded;
          statusColor = Colors.green.shade700;
          backgroundColor = Colors.green.shade50;
          borderColor = Colors.green.shade200;
        } else {
          // Документ на проверке
          statusText = 'На проверке'; // TODO: добавить перевод
          statusIcon = Icons.pending_rounded;
          statusColor = Colors.orange.shade700;
          backgroundColor = Colors.orange.shade50;
          borderColor = Colors.orange.shade200;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationSwitch({required bool isSmallScreen}) {
    final isEnabled =
        _profileData?.profile.settings.notificationsEnabled ?? false;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: const Color(0xFF1565C0),
              size: 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<AppState>(
                  builder: (context, appState, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.t('notifications'),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 16,
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          isEnabled
                              ? 'Включены'
                              : 'Выключены', // TODO: добавить перевод
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) async {
              // Оптимистичное обновление UI
              if (!mounted) return;
              setState(() {
                if (_profileData != null) {
                  _profileData = UserProfileResponse(
                    user: _profileData!.user,
                    profile: ProfileData(
                      id: _profileData!.profile.id,
                      userId: _profileData!.profile.userId,
                      documents: _profileData!.profile.documents,
                      settings: ProfileSettings(
                        notificationsEnabled: value,
                        language: _profileData!.profile.settings.language,
                      ),
                      createdAt: _profileData!.profile.createdAt,
                      updatedAt: _profileData!.profile.updatedAt,
                    ),
                  );
                }
              });

              try {
                // Обновляем на сервере
                await _profileService.updateNotifications(value);

                // Показываем уведомление об успехе
                if (mounted) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  ModernSnackBar.showSuccess(
                    context,
                    message: value
                        ? appState.t('notifications_enabled')
                        : appState.t('notifications_disabled'),
                    duration: const Duration(seconds: 2),
                  );
                }
              } catch (e) {
                // В случае ошибки возвращаем переключатель в исходное состояние
                if (!mounted) return;
                setState(() {
                  if (_profileData != null) {
                    _profileData = UserProfileResponse(
                      user: _profileData!.user,
                      profile: ProfileData(
                        id: _profileData!.profile.id,
                        userId: _profileData!.profile.userId,
                        documents: _profileData!.profile.documents,
                        settings: ProfileSettings(
                          notificationsEnabled: !value,
                          language: _profileData!.profile.settings.language,
                        ),
                        createdAt: _profileData!.profile.createdAt,
                        updatedAt: _profileData!.profile.updatedAt,
                      ),
                    );
                  }
                });

                if (mounted) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  ModernSnackBar.showError(
                    context,
                    message: appState.t('profile_upload_error'),
                  );
                }
              }
            },
            activeColor: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }
}

// Виджеты для страницы профиля

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isSmallScreen,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 22),
        SizedBox(height: isSmallScreen ? 4 : 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                )
              : null,
          color: selected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
