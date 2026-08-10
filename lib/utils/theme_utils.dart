import 'package:flutter/material.dart';

/// Вспомогательные функции для работы с темами

/// Получить цвет фона в зависимости от темы
Color getBackgroundColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFF121212)
      : const Color(0xFFF5F7FB);
}

/// Получить цвет карточки в зависимости от темы
Color getCardColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFF1E1E1E)
      : Colors.white;
}

/// Получить цвет текста заголовка в зависимости от темы
Color getTitleColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF111827);
}

/// Получить цвет вторичного текста в зависимости от темы
Color getSecondaryTextColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.grey.shade400
      : Colors.grey.shade600;
}

/// Получить цвет границы в зависимости от темы
Color getBorderColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.grey.shade700
      : Colors.grey.shade300;
}

/// Получить цвет тени в зависимости от темы
Color getShadowColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.black.withOpacity(0.2)
      : Colors.black.withOpacity(0.04);
}

/// Получить цвет фона для невыбранных элементов в зависимости от темы
Color getUnselectedBackgroundColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.grey.shade800
      : Colors.grey.shade100;
}








