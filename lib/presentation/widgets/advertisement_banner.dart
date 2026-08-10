import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/advertisement.dart';
import '../../domain/usecases/advertisements/register_advertisement_view.dart';
import '../../domain/usecases/advertisements/register_advertisement_click.dart';
import '../../widgets/safe_network_image.dart';
import '../../di/injection_container.dart' as di;

/// Виджет рекламного баннера
class AdvertisementBanner extends StatefulWidget {
  const AdvertisementBanner({
    super.key,
    required this.advertisement,
    this.onTap,
    this.height,
    this.borderRadius,
  });

  final AdvertisementEntity advertisement;
  final VoidCallback? onTap;
  final double? height;
  final double? borderRadius;

  @override
  State<AdvertisementBanner> createState() => _AdvertisementBannerState();
}

class _AdvertisementBannerState extends State<AdvertisementBanner> {
  bool _hasViewed = false;
  late final RegisterAdvertisementView _registerView;
  late final RegisterAdvertisementClick _registerClick;

  @override
  void initState() {
    super.initState();
    _registerView = di.getIt<RegisterAdvertisementView>();
    _registerClick = di.getIt<RegisterAdvertisementClick>();
    // Регистрируем просмотр при первом показе
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerAdvertisementView();
    });
  }

  Future<void> _registerAdvertisementView() async {
    if (_hasViewed) return;
    
    _hasViewed = true;
    await _registerView.call(
      advertisementId: widget.advertisement.id,
      deviceType: 'mobile',
      appVersion: '1.0.0', // TODO: Получить реальную версию приложения
    );
  }

  Future<void> _handleTap() async {
    // Регистрируем клик
    await _registerClick.call(
      advertisementId: widget.advertisement.id,
      deviceType: 'mobile',
    );

    // Вызываем кастомный обработчик если есть
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    // Обрабатываем ссылку
    final linkUrl = widget.advertisement.linkUrl;
    if (linkUrl != null && linkUrl.isNotEmpty) {
      final linkType = widget.advertisement.linkType;
      
      if (linkType == 'external' || linkType == null) {
        // Внешняя ссылка
        final uri = Uri.parse(linkUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (linkType == 'internal') {
        // Внутренняя ссылка - можно обработать через Navigator
        // TODO: Реализовать навигацию по внутренним ссылкам
      } else if (linkType == 'deep_link') {
        // Deep link - можно обработать через url_launcher или роутинг
        final uri = Uri.parse(linkUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? 20.0;
    final height = widget.height ?? 120.0;

    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: _handleTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Изображение рекламы
              SafeNetworkImage(
                imageUrl: widget.advertisement.imageUrl,
                fit: BoxFit.cover,
                placeholder: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1565C0),
                        const Color(0xFF42A5F5),
                      ],
                    ),
                  ),
                ),
                errorWidget: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1565C0),
                        const Color(0xFF42A5F5),
                      ],
                    ),
                  ),
                ),
              ),
              // Градиентный оверлей для читаемости текста
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
              // Контент
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.advertisement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.advertisement.description != null &&
                        widget.advertisement.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.advertisement.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

