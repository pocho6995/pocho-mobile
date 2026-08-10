import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Расширяющаяся плавающая кнопка с дополнительными действиями
class ExpandingFAB extends StatefulWidget {
  const ExpandingFAB({
    super.key,
    required this.onFiltersTap,
    required this.onMapTap,
    this.bottomNavigationBarHeight = 80,
  });

  final VoidCallback onFiltersTap;
  final VoidCallback onMapTap;
  final double bottomNavigationBarHeight;

  @override
  State<ExpandingFAB> createState() => _ExpandingFABState();
}

class _ExpandingFABState extends State<ExpandingFAB>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onActionTap(VoidCallback action) {
    _toggleExpansion();
    Future.delayed(const Duration(milliseconds: 150), () {
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    const double fabSize = 56.0;
    const double fabPadding = 16.0; // Горизонтальный отступ от края

    // Получаем отступы SafeArea
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    // Точный расчет высоты навигации на основе реальных размеров:
    // Padding контейнера: 8px top + 8px bottom = 16px
    // Padding элемента (vertical): 4-6px (верх + низ) = 8-12px, берем 10px
    // Иконка с padding: padding 6-7px*2 + размер 20-24px = 32-38px, берем 35px
    // Отступ между иконкой и текстом: 3-4px, берем 3.5px
    // Текст: 9-11px, берем 10px
    // Итого контент элемента: 10 + 35 + 3.5 + 10 = 58.5px ≈ 59px
    // Общая высота навигации: 16px (padding контейнера) + 59px (контент) = 75px
    const double navContainerPadding = 16.0;
    const double navItemContentHeight = 59.0;
    const double totalNavHeight = navContainerPadding + navItemContentHeight;

    // Отступ от навигации (12px между кнопками и навигацией)
    const double spacingFromNav = 12.0;

    // Вычисляем позицию: SafeArea bottom + высота навигации + отступ
    // bottomNavigationBar находится поверх body, поэтому нужно учесть его высоту
    final bottomOffset = safeAreaBottom + totalNavHeight + spacingFromNav;

    return Stack(
      children: [
        // Затемнение фона при расширении
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpansion,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ).animate().fadeIn(duration: 200.ms),

        // Кнопка "Показать на карте"
        if (_isExpanded)
          Positioned(
            left: fabPadding,
            bottom: bottomOffset + 80,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Tooltip(
                message: 'На карте',
                child: _ActionButton(
                  icon: Icons.map_rounded,
                  label: 'На карте',
                  onTap: () => _onActionTap(widget.onMapTap),
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ),
          ),

        // Кнопка "Фильтры"
        if (_isExpanded)
          Positioned(
            left: fabPadding,
            bottom: bottomOffset + 160,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Tooltip(
                message: 'Фильтры',
                child: _ActionButton(
                  icon: Icons.tune_rounded,
                  label: 'Фильтры',
                  onTap: () => _onActionTap(widget.onFiltersTap),
                  color: const Color(0xFF1565C0),
                ),
              ),
            ),
          ),

        // Основная кнопка (слева, напротив кнопки ИИ помощника справа)
        Positioned(
          left: fabPadding,
          bottom: bottomOffset,
          child: GestureDetector(
            onTap: _toggleExpansion,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: Container(
                width: fabSize,
                height: fabSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isExpanded ? Icons.close : Icons.add,
                  color: const Color(0xFF1565C0),
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет кнопки действия (круглая с иконкой)
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label; // Оставляем для подсказки, но не отображаем
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
