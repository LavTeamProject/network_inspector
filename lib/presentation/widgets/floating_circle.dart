import 'package:flutter/material.dart';

class FloatingCircleWidget extends StatefulWidget {
  const FloatingCircleWidget({
    super.key,
    required this.onActivityTap,
  });

  final VoidCallback onActivityTap;

  @override
  State<FloatingCircleWidget> createState() => _FloatingCircleWidgetState();
}

class _FloatingCircleWidgetState extends State<FloatingCircleWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  Offset _dragOffset = const Offset(300, 200); // ✅ Начальная позиция
  final double _circleSize = 50.0;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size; // ✅ Получаем размер экрана

    return Stack( // ✅ Оборачиваем в Stack
      children: [
        Positioned(
          left: (_dragOffset.dx).clamp(0.0, screenSize.width - _circleSize),
          top: (_dragOffset.dy).clamp(0.0, screenSize.height - _circleSize),
          child: GestureDetector(
            onPanStart: (_) => _scaleController.reverse(),
            onPanUpdate: (details) {
              setState(() {
                _dragOffset += details.delta;
              });
            },
            onPanEnd: (_) {
              _snapToEdge(screenSize);
              _scaleController.forward();
            },
            onLongPress: widget.onActivityTap,
            child: AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.95 + (_scaleController.value * 0.05),
                  child: Container(
                    width: _circleSize,
                    height: _circleSize,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Colors.red, Colors.redAccent],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.network_check,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _snapToEdge(Size screenSize) {
    final margin = 16.0;
    final centerX = _dragOffset.dx + _circleSize / 2;
    final centerY = _dragOffset.dy + _circleSize / 2;

    double newX = centerX < screenSize.width / 2
        ? margin
        : screenSize.width - _circleSize - margin;

    double newY;
    if (centerY < screenSize.height / 3) {
      newY = margin;
    } else if (centerY > screenSize.height * 2 / 3) {
      newY = screenSize.height - _circleSize - margin;
    } else {
      newY = (screenSize.height - _circleSize) / 2;
    }

    setState(() {
      _dragOffset = Offset(newX, newY);
    });
  }
}
