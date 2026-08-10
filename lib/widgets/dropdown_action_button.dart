import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

/// Выпадающая кнопка действий в правом верхнем углу
class DropdownActionButton extends StatefulWidget {
  const DropdownActionButton({
    super.key,
    required this.onFiltersTap,
    required this.onMapTap,
    required this.onAiAssistantTap,
    this.hideDelivery = false,
  });

  final VoidCallback onFiltersTap;
  final VoidCallback onMapTap;
  final VoidCallback onAiAssistantTap;
  final bool hideDelivery;

  @override
  State<DropdownActionButton> createState() => _DropdownActionButtonState();
}

class _DropdownActionButtonState extends State<DropdownActionButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _showOverlay();
      } else {
        _animationController.reverse();
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Затемнение фона
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = false;
                });
                _animationController.reverse();
                _overlayEntry?.remove();
                _overlayEntry = null;
              },
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
          // Выпадающее меню
          Positioned(
            top: offset.dy + size.height + 8,
            right: screenWidth - offset.dx - size.width,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          _DropdownMenuItem(
                            icon: Icons.tune_rounded,
                            label: appState.t('filters'),
                            color: const Color(0xFF1565C0),
                            gradient: const [
                              Color(0xFF1565C0),
                              Color(0xFF42A5F5),
                            ],
                            onTap: () {
                              _closeMenu();
                              widget.onFiltersTap();
                            },
                          ),
                          if (!widget.hideDelivery) ...[
                            const SizedBox(height: 4),
                            _DropdownMenuItem(
                              icon: Icons.map_rounded,
                              label: appState.t('on_map'),
                              color: const Color(0xFF4CAF50),
                              gradient: const [
                                Color(0xFF4CAF50),
                                Color(0xFF81C784),
                              ],
                              onTap: () {
                                _closeMenu();
                                widget.onMapTap();
                              },
                            ),
                          ],
                          const SizedBox(height: 4),
                          _DropdownMenuItem(
                            icon: Icons.auto_awesome,
                            label: appState.t('ai_assistant'),
                            color: const Color(0xFF8B5CF6),
                            gradient: const [
                              Color(0xFF8B5CF6),
                              Color(0xFFA78BFA),
                            ],
                            onTap: () {
                              _closeMenu();
                              widget.onAiAssistantTap();
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _closeMenu() {
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: _toggleExpansion,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isExpanded
                  ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                  : [Colors.white, Colors.white],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _isExpanded
                    ? const Color(0xFF1565C0).withOpacity(0.4)
                    : Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            _isExpanded ? Icons.close_rounded : Icons.apps_rounded,
            color: _isExpanded ? Colors.white : const Color(0xFF1565C0),
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// Элемент выпадающего меню
class _DropdownMenuItem extends StatelessWidget {
  const _DropdownMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                gradient[0].withOpacity(0.1),
                gradient[1].withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: color.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
