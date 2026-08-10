import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/region.dart';
import '../../widgets/modern_dialog.dart';
import 'driver_profile_page.dart';

class DriverRegistrationPage extends StatefulWidget {
  const DriverRegistrationPage({super.key});

  static const String routeName = '/delivery/driver-registration';

  @override
  State<DriverRegistrationPage> createState() => _DriverRegistrationPageState();
}

class _DriverRegistrationPageState extends State<DriverRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();
  
  List<Region> _regions = [];
  Region? _selectedRegion;
  bool _isLoading = false;
  bool _isLoadingRegions = true;
  final _focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Статический список регионов Узбекистана (fallback)
  static final List<Region> _defaultRegions = [
    Region(
      id: 1,
      nameUz: 'Toshkent',
      nameRu: 'Ташкент',
      nameEn: 'Tashkent',
      centerLatitude: 41.2995,
      centerLongitude: 69.2401,
      isActive: true,
      displayOrder: 1,
    ),
    Region(
      id: 2,
      nameUz: 'Samarqand',
      nameRu: 'Самарканд',
      nameEn: 'Samarkand',
      centerLatitude: 39.6542,
      centerLongitude: 66.9597,
      isActive: true,
      displayOrder: 2,
    ),
    Region(
      id: 3,
      nameUz: 'Buxoro',
      nameRu: 'Бухара',
      nameEn: 'Bukhara',
      centerLatitude: 39.7681,
      centerLongitude: 64.4556,
      isActive: true,
      displayOrder: 3,
    ),
    Region(
      id: 4,
      nameUz: 'Andijon',
      nameRu: 'Андижан',
      nameEn: 'Andijan',
      centerLatitude: 40.7833,
      centerLongitude: 72.3333,
      isActive: true,
      displayOrder: 4,
    ),
    Region(
      id: 5,
      nameUz: 'Namangan',
      nameRu: 'Наманган',
      nameEn: 'Namangan',
      centerLatitude: 40.9983,
      centerLongitude: 71.6726,
      isActive: true,
      displayOrder: 5,
    ),
    Region(
      id: 6,
      nameUz: 'Farg\'ona',
      nameRu: 'Фергана',
      nameEn: 'Fergana',
      centerLatitude: 40.3842,
      centerLongitude: 71.7842,
      isActive: true,
      displayOrder: 6,
    ),
    Region(
      id: 7,
      nameUz: 'Qashqadaryo',
      nameRu: 'Кашкадарья',
      nameEn: 'Kashkadarya',
      centerLatitude: 38.8606,
      centerLongitude: 65.7892,
      isActive: true,
      displayOrder: 7,
    ),
    Region(
      id: 8,
      nameUz: 'Surxondaryo',
      nameRu: 'Сурхандарья',
      nameEn: 'Surkhandarya',
      centerLatitude: 37.2242,
      centerLongitude: 67.2783,
      isActive: true,
      displayOrder: 8,
    ),
    Region(
      id: 9,
      nameUz: 'Qoraqalpog\'iston',
      nameRu: 'Каракалпакстан',
      nameEn: 'Karakalpakstan',
      centerLatitude: 42.4647,
      centerLongitude: 59.6142,
      isActive: true,
      displayOrder: 9,
    ),
    Region(
      id: 10,
      nameUz: 'Jizzax',
      nameRu: 'Джизак',
      nameEn: 'Jizzakh',
      centerLatitude: 40.1158,
      centerLongitude: 67.8422,
      isActive: true,
      displayOrder: 10,
    ),
    Region(
      id: 11,
      nameUz: 'Navoiy',
      nameRu: 'Навои',
      nameEn: 'Navoi',
      centerLatitude: 40.0844,
      centerLongitude: 65.3792,
      isActive: true,
      displayOrder: 11,
    ),
    Region(
      id: 12,
      nameUz: 'Sirdaryo',
      nameRu: 'Сырдарья',
      nameEn: 'Syrdarya',
      centerLatitude: 40.8433,
      centerLongitude: 68.6617,
      isActive: true,
      displayOrder: 12,
    ),
    Region(
      id: 13,
      nameUz: 'Xorazm',
      nameRu: 'Хорезм',
      nameEn: 'Khorezm',
      centerLatitude: 41.5500,
      centerLongitude: 60.6333,
      isActive: true,
      displayOrder: 13,
    ),
    Region(
      id: 14,
      nameUz: 'Toshkent viloyati',
      nameRu: 'Ташкентская область',
      nameEn: 'Tashkent Region',
      centerLatitude: 41.2667,
      centerLongitude: 69.2167,
      isActive: true,
      displayOrder: 14,
    ),
  ];

  Future<void> _loadRegions() async {
    try {
      final regions = await _deliveryRepository.getRegions(isActive: true);
      setState(() {
        _regions = regions.isNotEmpty ? regions : _defaultRegions;
        _isLoadingRegions = false;
      });
    } catch (e) {
      // Используем статический список если не удалось загрузить с сервера
      setState(() {
        _regions = _defaultRegions;
        _isLoadingRegions = false;
      });
    }
  }

  void _showRegionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Выберите регион',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded, size: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _regions.length,
                  itemBuilder: (context, index) {
                    final region = _regions[index];
                    final isSelected = _selectedRegion?.id == region.id;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedRegion = region;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [
                                          const Color(0xFF6366F1),
                                          const Color(0xFF8B5CF6),
                                        ]
                                      : [
                                          Colors.grey.shade300,
                                          Colors.grey.shade300,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.location_city_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                region.nameRu,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF111827),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRegion == null) {
      ModernDialog.show(
        context: context,
        title: 'Ошибка',
        content: 'Пожалуйста, выберите регион',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red,
        primaryAction: DialogAction(
          label: 'OK',
          onPressed: () {},
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final driver = await _deliveryRepository.registerDriver(
        phoneNumber: _phoneController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        regionId: _selectedRegion!.id,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          DriverProfilePage.routeName,
          arguments: driver,
        );
      }
    } catch (e) {
      if (mounted) {
        ModernDialog.show(
          context: context,
          title: 'Ошибка',
          content: 'Не удалось зарегистрироваться: ${e.toString()}',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(
            label: 'OK',
            onPressed: () {},
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Регистрация водителя',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
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
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingRegions
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Заголовок с иконкой
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.drive_eta_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          )
                              .animate()
                              .scale(delay: 200.ms, duration: 600.ms)
                              .then()
                              .shimmer(duration: 2000.ms),
                          const SizedBox(height: 16),
                          const Text(
                            'Станьте водителем PoCho',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 8),
                          Text(
                            'Зарабатывайте, доставляя заказы',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 400.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 32),
                    // Поля формы
                    _ModernTextField(
                      controller: _fullNameController,
                      label: 'ФИО',
                      hint: 'Иванов Иван Иванович',
                      icon: Icons.person_outline_rounded,
                      focusNode: _focusNodes[0],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите ФИО';
                        }
                        return null;
                      },
                      delay: const Duration(milliseconds: 500),
                    ),
                    const SizedBox(height: 20),
                    _ModernTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'driver@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      focusNode: _focusNodes[1],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите email';
                        }
                        if (!value.contains('@')) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                      delay: const Duration(milliseconds: 600),
                    ),
                    const SizedBox(height: 20),
                    _ModernTextField(
                      controller: _phoneController,
                      label: 'Номер телефона',
                      hint: '+998900000000',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      focusNode: _focusNodes[2],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите номер телефона';
                        }
                        return null;
                      },
                      delay: const Duration(milliseconds: 700),
                    ),
                    const SizedBox(height: 20),
                    // Регион
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Регион',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              duration: const Duration(milliseconds: 300),
                              delay: const Duration(milliseconds: 800),
                            )
                            .slideX(begin: -0.1, end: 0),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showRegionPicker,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedRegion != null
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey.shade200,
                                width: _selectedRegion != null ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xFF6366F1),
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _selectedRegion?.nameRu ?? 'Выберите регион',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedRegion != null
                                          ? const Color(0xFF111827)
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              duration: const Duration(milliseconds: 400),
                              delay: const Duration(milliseconds: 900),
                            )
                            .slideY(begin: 0.1, end: 0),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Кнопка регистрации
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerDriver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Зарегистрироваться',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          duration: const Duration(milliseconds: 400),
                          delay: const Duration(milliseconds: 900),
                        )
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1, 1),
                          delay: 900.ms,
                        ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.focusNode,
    this.validator,
    this.delay = const Duration(milliseconds: 0),
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: delay)
            .slideX(begin: -0.1, end: 0),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: delay + 100.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }
}

