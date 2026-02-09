import 'package:flutter/material.dart';
import '../../common/navigation_service.dart';
import '../../network_inspector_config.dart';
import '../pages/activity_page.dart';

class FloatingTestButton extends StatefulWidget {
  const FloatingTestButton({super.key});

  @override
  State<FloatingTestButton> createState() => _FloatingTestButtonState();
}

class _FloatingTestButtonState extends State<FloatingTestButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;
  Offset _position = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!_isDragging) {
      NavigationService.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => ActivityPage()),
      );
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size screenSize) {
    setState(() {
      _position += details.delta;

      // Keep button within screen bounds
      _position = Offset(
        _position.dx.clamp(0, screenSize.width - 56),
        _position.dy.clamp(0, screenSize.height - 56),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 FloatingTestButton build: enabled=${NetworkInspectorConfig.isTestButtonEnabled}');
    if (!NetworkInspectorConfig.isTestButtonEnabled) {
      print('🔴 FloatingTestButton disabled');
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final alignment = NetworkInspectorConfig.buttonAlignment;
    final margin = NetworkInspectorConfig.buttonMargin;
    print('📏 screenSize=$screenSize alignment=$alignment margin=$margin');

    // Calculate initial position based on alignment
    if (_position == Offset.zero) {
      _position = _calculateInitialPosition(alignment, screenSize, margin);
      print('📍 initial position=$_position');
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: _onTap,
        onPanStart: _onPanStart,
        onPanUpdate: (details) => _onPanUpdate(details, screenSize),
        onPanEnd: _onPanEnd,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTapDown: (_) => _animationController.forward(),
                    onTapUp: (_) {
                      _animationController.reverse();
                      _onTap();
                    },
                    onTapCancel: () => _animationController.reverse(),
                    child: Center(child: NetworkInspectorConfig.customButton),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Offset _calculateInitialPosition(
    Alignment alignment,
    Size screenSize,
    double margin,
  ) {
    final padding = MediaQuery.of(context).padding;
    print('📐 padding: $padding');
    // Use if-else because Alignment cannot be used in switch
    if (alignment == Alignment.topLeft) {
      return Offset(margin, margin + padding.top);
    } else if (alignment == Alignment.topRight) {
      return Offset(screenSize.width - 56 - margin, margin + padding.top);
    } else if (alignment == Alignment.bottomLeft) {
      return Offset(margin, screenSize.height - 56 - margin - padding.bottom);
    } else if (alignment == Alignment.bottomRight) {
      return Offset(
        screenSize.width - 56 - margin,
        screenSize.height - 56 - margin - padding.bottom,
      );
    } else if (alignment == Alignment.center) {
      return Offset(
        (screenSize.width - 56) / 2,
        (screenSize.height - 56) / 2,
      );
    } else {
      // default bottomRight
      return Offset(
        screenSize.width - 56 - margin,
        screenSize.height - 56 - margin - padding.bottom,
      );
    }
  }
}

class NetworkInspectorOverlay extends StatelessWidget {
  const NetworkInspectorOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    print('🟦 NetworkInspectorOverlay build');
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const FloatingTestButton(),
      ],
    );
  }
}