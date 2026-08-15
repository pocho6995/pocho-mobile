/// Нормализация узбекских номеров телефонов для API.
class PhoneNumberUtils {
  static final RegExp uzbekE164 = RegExp(r'^\+998\d{9}$');

  /// Собирает E.164 из поля ввода (с/без префикса, с пробелами).
  /// Возвращает `null`, если номер невалиден.
  static String? normalizeUzbek(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    final withCountry = digits.startsWith('998') ? digits : '998$digits';
    if (withCountry.length != 12) return null;

    final e164 = '+$withCountry';
    if (!uzbekE164.hasMatch(e164)) return null;
    return e164;
  }

  static bool isValidUzbek(String? raw) => normalizeUzbek(raw) != null;
}
