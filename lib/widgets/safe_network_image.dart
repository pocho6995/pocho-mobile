import 'package:flutter/material.dart';

/// Безопасный виджет для отображения сетевых изображений с обработкой ошибок
class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    // Если URL пустой или null, показываем placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    Widget imageWidget = Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder(context);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget(context);
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
      ),
      child: Icon(
        Icons.image_outlined,
        size: (height != null && width != null)
            ? (height! < width! ? height! * 0.3 : width! * 0.3)
            : 48,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        size: (height != null && width != null)
            ? (height! < width! ? height! * 0.3 : width! * 0.3)
            : 48,
        color: Colors.grey.shade400,
      ),
    );
  }
}

/// Безопасный виджет для отображения аватара пользователя
class SafeAvatar extends StatefulWidget {
  const SafeAvatar({
    super.key,
    required this.imageUrl,
    this.radius,
    this.backgroundColor,
    this.placeholderText,
    this.placeholderIcon,
  });

  final String? imageUrl;
  final double? radius;
  final Color? backgroundColor;
  final String? placeholderText;
  final IconData? placeholderIcon;

  @override
  State<SafeAvatar> createState() => _SafeAvatarState();
}

class _SafeAvatarState extends State<SafeAvatar> {
  bool _hasError = false;

  @override
  void didUpdateWidget(SafeAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Сбрасываем ошибку при изменении URL
    if (oldWidget.imageUrl != widget.imageUrl) {
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImageUrl =
        widget.imageUrl != null && widget.imageUrl!.isNotEmpty && !_hasError;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? Colors.grey.shade300,
      backgroundImage: hasImageUrl ? NetworkImage(widget.imageUrl!) : null,
      onBackgroundImageError: hasImageUrl
          ? (exception, stackTrace) {
              // Обрабатываем ошибку загрузки изображения
              if (mounted) {
                setState(() {
                  _hasError = true;
                });
              }
            }
          : null,
      child: hasImageUrl ? null : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (widget.placeholderText != null && widget.placeholderText!.isNotEmpty) {
      return Text(
        widget.placeholderText![0].toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: widget.radius != null ? widget.radius! * 0.6 : 20,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (widget.placeholderIcon != null) {
      return Icon(
        widget.placeholderIcon,
        size: widget.radius != null ? widget.radius! * 0.6 : 20,
        color: Colors.grey.shade600,
      );
    }

    return Icon(
      Icons.person_outline,
      size: widget.radius != null ? widget.radius! * 0.6 : 20,
      color: Colors.grey.shade600,
    );
  }
}

/// Безопасный виджет для отображения изображения в контейнере с DecorationImage
class SafeDecorationImageContainer extends StatelessWidget {
  const SafeDecorationImageContainer({
    super.key,
    required this.imageUrl,
    required this.child,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.gradient,
  });

  final String? imageUrl;
  final Widget child;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    // Если URL пустой или null, показываем placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return Stack(
      children: [
        // Фоновое изображение с обработкой ошибок
        Positioned.fill(
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: Image.network(
              imageUrl!,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget(context);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholder(context);
              },
            ),
          ),
        ),
        // Дочерний виджет поверх изображения
        child,
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade200, Colors.grey.shade300],
            ),
      ),
      child: child,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade200, Colors.grey.shade300],
            ),
      ),
      child: Stack(
        children: [
          // Иконка по центру при ошибке
          if (gradient != null)
            Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
