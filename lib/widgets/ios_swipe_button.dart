import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Кнопка-свайпер в стиле старых iOS
/// Требует свайпа вправо для активации
class IOSSwipeButton extends StatefulWidget {
  const IOSSwipeButton({
    super.key,
    required this.onSwipe,
    required this.text,
    this.enabled = true,
    this.isLoading = false,
    this.backgroundColor = const Color(0xFF1565C0),
    this.disabledColor = const Color(0xFFE5E7EB),
    this.textColor = Colors.white,
    this.disabledTextColor,
    this.height = 56,
    this.borderRadius = 28,
  });

  final VoidCallback onSwipe;
  final String text;
  final bool enabled;
  final bool isLoading;
  final Color backgroundColor;
  final Color disabledColor;
  final Color textColor;
  final Color? disabledTextColor;
  final double height;
  final double borderRadius;

  @override
  State<IOSSwipeButton> createState() => _IOSSwipeButtonState();
}

class _IOSSwipeButtonState extends State<IOSSwipeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragPosition = 0.0;
  bool _isDragging = false;
  double _maxDragDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled || widget.isLoading) return;
    setState(() {
      _isDragging = true;
    });
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || widget.isLoading || !_isDragging) return;

    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(0.0, _maxDragDistance);
    });

    // Вибрация при достижении 50% и 90%
    final progress = _dragPosition / _maxDragDistance;
    if ((progress > 0.5 && progress < 0.52) ||
        (progress > 0.9 && progress < 0.92)) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final progress = _dragPosition / _maxDragDistance;
    if (progress >= 0.85) {
      // Свайп завершен - активируем действие
      _controller.forward().then((_) {
        widget.onSwipe();
        // Сброс после небольшой задержки
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _reset();
          }
        });
      });
      HapticFeedback.heavyImpact();
    } else {
      // Свайп не завершен - возвращаем в исходное положение
      _reset();
      HapticFeedback.lightImpact();
    }
  }

  void _reset() {
    setState(() {
      _isDragging = false;
      _dragPosition = 0.0;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && !widget.isLoading;
    final effectiveTextColor = isEnabled
        ? widget.textColor
        : (widget.disabledTextColor ?? Colors.grey.shade500);

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDragDistance = constraints.maxWidth - widget.height - 8;

        final dragProgress = _maxDragDistance > 0
            ? (_dragPosition / _maxDragDistance).clamp(0.0, 1.0)
            : 0.0;

        final buttonColor = isEnabled
            ? widget.backgroundColor
            : widget.disabledColor;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: widget.backgroundColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Фоновый текст
              Center(
                child: AnimatedOpacity(
                  opacity: isEnabled && !_isDragging ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: effectiveTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isEnabled && !widget.isLoading) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: effectiveTextColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Свайпаемая кнопка
              AnimatedPositioned(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: _dragPosition + 4,
                top: 4,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Container(
                    width: widget.height - 8,
                    height: widget.height - 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1565C0),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.arrow_forward_rounded,
                            color: isEnabled
                                ? widget.backgroundColor
                                : Colors.grey.shade400,
                            size: 24,
                          ),
                  ),
                ),
              ),
              // Текст при свайпе
              if (_isDragging && dragProgress > 0.1)
                Center(
                  child: AnimatedOpacity(
                    opacity: dragProgress,
                    duration: Duration.zero,
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: effectiveTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

