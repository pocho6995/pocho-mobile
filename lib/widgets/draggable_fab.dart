import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Перетаскиваемая плавающая кнопка с сохранением позиции
class DraggableFAB extends StatefulWidget {
  const DraggableFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.badge,
    this.badgeColor,
    this.storageKey = 'draggable_fab_position',
  });

  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? badge;
  final Color? badgeColor;
  final String storageKey;

  @override
  State<DraggableFAB> createState() => _DraggableFABState();
}

class _DraggableFABState extends State<DraggableFAB> {
  Offset? _position;
  bool _isDragging = false;
  bool _isPositionLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble('${widget.storageKey}_x');
      final y = prefs.getDouble('${widget.storageKey}_y');
      
      if (mounted) {
        setState(() {
          if (x != null && y != null) {
            _position = Offset(x, y);
          }
          _isPositionLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPositionLoaded = true;
        });
      }
    }
  }

  Future<void> _savePosition(Offset position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${widget.storageKey}_x', position.dx);
      await prefs.setDouble('${widget.storageKey}_y', position.dy);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  void _updatePosition(Offset newPosition, Size screenSize) {
    // Ограничиваем позицию в пределах экрана
    final fabSize = 56.0; // Размер FAB
    final padding = 16.0;
    
    double x = newPosition.dx.clamp(
      padding,
      screenSize.width - fabSize - padding,
    );
    double y = newPosition.dy.clamp(
      padding,
      screenSize.height - fabSize - padding,
    );

    final updatedPosition = Offset(x, y);
    setState(() {
      _position = updatedPosition;
    });
    
    _savePosition(updatedPosition);
  }

  Offset _getDefaultPosition(Size screenSize) {
    return Offset(
      screenSize.width - 80,
      screenSize.height - 200,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Используем сохраненную позицию или позицию по умолчанию
    final position = _position ?? _getDefaultPosition(screenSize);
    
    // Если позиция еще не загружена, показываем в позиции по умолчанию
    if (!_isPositionLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _position == null) {
          setState(() {
            _position = _getDefaultPosition(screenSize);
          });
        }
      });
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          final currentPosition = _position ?? _getDefaultPosition(screenSize);
          final newPosition = currentPosition + details.delta;
          _updatePosition(newPosition, screenSize);
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isDragging ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDragging ? 0.3 : 0.2),
                    blurRadius: _isDragging ? 20 : 12,
                    offset: Offset(0, _isDragging ? 8 : 4),
                    spreadRadius: _isDragging ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor ?? Colors.grey.shade700,
                      size: 24,
                    ),
                  ),
                  if (widget.badge != null && widget.badge!.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: widget.badgeColor ?? Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          widget.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

