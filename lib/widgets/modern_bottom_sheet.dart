import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Современный bottom sheet с единым стилем
class ModernBottomSheet extends StatelessWidget {
  const ModernBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showDragHandle = true,
    this.isScrollControlled = false,
    this.maxHeight,
    this.showCloseButton = false,
  });

  final Widget child;
  final String? title;
  final bool showDragHandle;
  final bool isScrollControlled;
  final double? maxHeight;
  final bool showCloseButton;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showDragHandle = true,
    bool isScrollControlled = false,
    double? maxHeight,
    bool showCloseButton = false,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      builder: (context) => ModernBottomSheet(
        title: title,
        showDragHandle: showDragHandle,
        isScrollControlled: isScrollControlled,
        maxHeight: maxHeight,
        showCloseButton: showCloseButton,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = maxHeight ?? (screenHeight * 0.75);

    return Container(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                if (showDragHandle)
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                // Заголовок
                if (title != null || showCloseButton)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                    child: Row(
                      children: [
                        if (title != null)
                          Expanded(
                            child: Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                                letterSpacing: -0.6,
                                height: 1.2,
                              ),
                            ),
                          ),
                        if (showCloseButton)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Контент
                Flexible(child: child),
              ],
            ),
          ),
        )
        .animate()
        .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }
}

/// Вспомогательный виджет для создания списка опций в bottom sheet
class ModernBottomSheetOption extends StatelessWidget {
  const ModernBottomSheetOption({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red
        : (iconColor ?? const Color(0xFF1565C0));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? Colors.red
                            : const Color(0xFF111827),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
