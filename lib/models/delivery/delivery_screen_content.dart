/// Контент экрана «По регионам Узбекистана» (карточка, кнопка, сервисный сбор).
/// Загружается с GET /api/v1/regions/delivery-screen-content.
class DeliveryScreenContent {
  DeliveryScreenContent({
    required this.cardTitle,
    required this.deliveryTime,
    required this.priceFromLabel,
    required this.serviceFeeText,
    required this.buttonLabel,
  });

  final String cardTitle;
  final String deliveryTime;
  final String priceFromLabel;
  final String serviceFeeText;
  final String buttonLabel;

  factory DeliveryScreenContent.fromJson(Map<String, dynamic> json) {
    return DeliveryScreenContent(
      cardTitle: json['card_title'] as String? ?? 'По регионам Узбекистана',
      deliveryTime: json['delivery_time'] as String? ?? '1-3 дня',
      priceFromLabel: json['price_from_label'] as String? ?? 'от 4500 сум',
      serviceFeeText:
          json['service_fee_text'] as String? ??
          'В стоимость включен сервисный сбор в размере 0% (вместо 3%) от суммы заказа',
      buttonLabel: json['button_label'] as String? ?? 'Перейти к форме заказа',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_title': cardTitle,
      'delivery_time': deliveryTime,
      'price_from_label': priceFromLabel,
      'service_fee_text': serviceFeeText,
      'button_label': buttonLabel,
    };
  }

  /// Значения по умолчанию при отсутствии API или ошибке
  static DeliveryScreenContent get defaults => DeliveryScreenContent(
    cardTitle: 'По регионам Узбекистана',
    deliveryTime: '1-3 дня',
    priceFromLabel: 'от 4500 сум',
    serviceFeeText:
        'В стоимость включен сервисный сбор в размере 0% (вместо 3%) от суммы заказа',
    buttonLabel: 'Перейти к форме заказа',
  );
}
