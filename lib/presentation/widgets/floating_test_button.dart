import 'package:flutter/material.dart';
import '../../common/navigation_service.dart';
import '../../network_inspector.dart';

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

  void _handleLongPress(BuildContext context) {
    final navigatorContext = NavigationService.currentContext;
    if (navigatorContext == null) {
      print('⚠️ NavigationService.currentContext is null');
      return;
    }
    print('🟢 Using navigatorContext for bottom sheet');
    showModalBottomSheet(
      context: navigatorContext,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                NetworkInspector.showTouchIndicators
                    ? Icons.touch_app
                    : Icons.touch_app_outlined,
                color: NetworkInspector.showTouchIndicators
                    ? Colors.purple
                    : Colors.grey,
              ),
              title: Text(
                NetworkInspector.showTouchIndicators
                    ? 'Touch Indicators ON'
                    : 'Touch Indicators OFF',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: NetworkInspector.showTouchIndicators
                      ? Colors.purple
                      : Colors.grey,
                ),
              ),
              subtitle: const Text('Toggle visual feedback for touches'),
              onTap: () {
                Navigator.pop(ctx);
                NetworkInspector.toggleTouchIndicators();
                setState(() {});
                ScaffoldMessenger.of(navigatorContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      NetworkInspector.showTouchIndicators
                          ? 'Touch indicators enabled'
                          : 'Touch indicators disabled',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_ethernet, color: Colors.orange),
              title: const Text(
                'Select Environment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                NetworkInspector.selectedEnvironment?.name ?? 'None',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showEnvironmentPicker(navigatorContext);
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnvironmentPicker(BuildContext context) {
    final environments = NetworkInspector.availableEnvironments;
    if (environments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No environments configured'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: const Row(
                children: [
                  Icon(Icons.settings_ethernet, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Select Environment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (NetworkInspector.selectedEnvironment != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NetworkInspector.selectedEnvironment!.color.withOpacity(0.3),
                      NetworkInspector.selectedEnvironment!.color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: NetworkInspector.selectedEnvironment!.color.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: NetworkInspector.selectedEnvironment!.color,
                      radius: 16,
                      child: Text(
                        NetworkInspector.selectedEnvironment!.name.substring(0, 2).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            NetworkInspector.selectedEnvironment!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            NetworkInspector.selectedEnvironment!.baseUrl,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: environments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final env = environments[index];
                  final isSelected = env == NetworkInspector.selectedEnvironment;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        NetworkInspector.selectEnvironment(index);
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${env.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? env.color.withOpacity(0.3) : Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? env.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: env.color,
                              radius: 16,
                              child: Text(
                                env.name.substring(0, 2).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    env.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    env.baseUrl,
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
        onLongPress: () => _handleLongPress(context),
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