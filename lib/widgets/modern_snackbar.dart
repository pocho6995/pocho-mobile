import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Типы уведомлений
enum SnackBarType {
  success,
  error,
  info,
  warning,
}

/// Современный кастомный SnackBar
class ModernSnackBar {
  /// Показать уведомление
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    Color? backgroundColor,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _ModernSnackBarWidget(
        message: message,
        type: type,
        duration: duration,
        icon: icon,
        backgroundColor: backgroundColor,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Автоматически удаляем через указанное время
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Показать уведомление об успехе
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
    );
  }

  /// Показать уведомление об ошибке
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
    );
  }

  /// Показать информационное уведомление
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
    );
  }

  /// Показать предупреждение
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
    );
  }
}

class _ModernSnackBarWidget extends StatefulWidget {
  const _ModernSnackBarWidget({
    required this.message,
    required this.type,
    required this.duration,
    this.icon,
    this.backgroundColor,
    required this.onDismiss,
  });

  final String message;
  final SnackBarType type;
  final Duration duration;
  final IconData? icon;
  final Color? backgroundColor;
  final VoidCallback onDismiss;

  @override
  State<_ModernSnackBarWidget> createState() => _ModernSnackBarWidgetState();
}

class _ModernSnackBarWidgetState extends State<_ModernSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();

    // Автоматически скрываем через указанное время
    Future.delayed(widget.duration, () {
      if (mounted && !_isDismissed) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDismissed) return;
    setState(() {
      _isDismissed = true;
    });
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }

    switch (widget.type) {
      case SnackBarType.success:
        return const Color(0xFF10B981);
      case SnackBarType.error:
        return const Color(0xFFEF4444);
      case SnackBarType.warning:
        return const Color(0xFFF59E0B);
      case SnackBarType.info:
        return const Color(0xFF1565C0);
    }
  }

  IconData _getIcon() {
    if (widget.icon != null) {
      return widget.icon!;
    }

    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }

  List<Color> _getGradientColors() {
    final baseColor = _getBackgroundColor();
    return [
      baseColor,
      baseColor.withOpacity(0.8),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    
    return Positioned(
      top: safePadding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: _controller,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getGradientColors(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getBackgroundColor().withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Иконка
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Текст
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Кнопка закрытия
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.2, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

