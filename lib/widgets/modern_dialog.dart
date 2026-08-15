import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Современный диалог с красивым дизайном
class ModernDialog extends StatelessWidget {
  const ModernDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.icon,
    this.iconColor,
    this.primaryAction,
    this.secondaryAction,
    this.showCloseButton = true,
  });

  final String title;
  final String? content;
  final Widget? contentWidget;
  final IconData? icon;
  final Color? iconColor;
  final DialogAction? primaryAction;
  final DialogAction? secondaryAction;
  final bool showCloseButton;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    IconData? icon,
    Color? iconColor,
    DialogAction? primaryAction,
    DialogAction? secondaryAction,
    bool showCloseButton = true,
    bool barrierDismissible = true,
  }) {
    // После await context часто уже disposed — не падаем.
    if (!context.mounted) {
      return Future<T?>.value(null);
    }

    final navigator = Navigator.maybeOf(context);
    if (navigator == null) {
      return Future<T?>.value(null);
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => ModernDialog(
        title: title,
        content: content,
        contentWidget: contentWidget,
        icon: icon,
        iconColor: iconColor,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
        showCloseButton: showCloseButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок с иконкой
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (iconColor ?? const Color(0xFF6366F1)),
                            (iconColor ?? const Color(0xFF8B5CF6)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (iconColor ?? const Color(0xFF6366F1))
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (showCloseButton)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ),
            // Контент
            if (content != null || contentWidget != null)
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, contentWidget != null ? 20 : 28),
                child: contentWidget ?? Text(
                  content!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.6,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            // Кнопки
            if (primaryAction != null || secondaryAction != null)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Row(
                  children: [
                    if (secondaryAction != null) ...[
                      Expanded(
                        child: _DialogButton(
                          action: secondaryAction!,
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (primaryAction != null)
                      Expanded(
                        flex: secondaryAction != null ? 1 : 1,
                        child: _DialogButton(
                          action: primaryAction!,
                          isPrimary: true,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 200.ms);
  }
}

class DialogAction {
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.color,
    this.isDestructive = false,
    this.returnValue,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isDestructive;
  final dynamic returnValue; // Значение, которое будет возвращено при нажатии
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.action,
    required this.isPrimary,
  });

  final DialogAction action;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final buttonColor = action.isDestructive
        ? Colors.red
        : (action.color ?? const Color(0xFF1565C0));

    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              buttonColor,
              buttonColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            action.onPressed();
            // Если returnValue - функция, вызываем её, иначе возвращаем значение
            dynamic value;
            if (action.returnValue != null && action.returnValue is Function) {
              value = (action.returnValue as Function)();
            } else {
              value = action.returnValue;
            }
            Navigator.of(context).pop(value);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            action.label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: () {
          action.onPressed();
          Navigator.of(context).pop(action.returnValue);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: buttonColor,
            width: 1.5,
          ),
        ),
        child: Text(
          action.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: buttonColor,
          ),
        ),
      );
    }
  }
}




