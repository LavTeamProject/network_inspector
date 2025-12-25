import 'package:flutter/material.dart';
import '../../network_inspector.dart';

class FloatingCircleWidget extends StatefulWidget {
  final VoidCallback? onRequestsTap;
  final VoidCallback? onEnvironmentTap;

  const FloatingCircleWidget({
    super.key,
    this.onRequestsTap,
    this.onEnvironmentTap,
  });

  @override
  State<FloatingCircleWidget> createState() => _FloatingCircleWidgetState();
}

class _FloatingCircleWidgetState extends State<FloatingCircleWidget> {
  static const double _circleSize = 68;
  static const double _margin = 16;

  Offset _position = const Offset(_margin, _margin);
  bool _isMenuOpen = false;

  void _showContextMenu(BuildContext context, RenderBox circleRenderBox) async {
    if (_isMenuOpen) return;
    setState(() => _isMenuOpen = true);

    final offset = circleRenderBox.localToGlobal(Offset.zero);
    final size = circleRenderBox.size;

    final position = RelativeRect.fromLTRB(
      offset.dx + size.width,
      offset.dy,
      offset.dx + size.width + 250,
      offset.dy + size.height,
    );

    try {
      final result = await showMenu<String>(
        context: context,
        position: position,
        items: [
          PopupMenuItem(
            value: 'requests',
            child: Row(
              children: const [
                Icon(Icons.list_alt, color: Colors.blue),
                SizedBox(width: 12),
                Text('HTTP Requests', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'environment',
            child: Row(
              children: [
                const Icon(Icons.settings_ethernet, color: Colors.orange),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Environment', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      NetworkInspector.selectedEnvironment?.name ?? 'None',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'touch_indicators',
            child: Row(
              children: [
                Icon(
                  NetworkInspector.showTouchIndicators
                      ? Icons.touch_app
                      : Icons.touch_app_outlined,
                  color: NetworkInspector.showTouchIndicators
                      ? Colors.purple
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Touch Indicators',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: NetworkInspector.showTouchIndicators
                            ? Colors.purple
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      NetworkInspector.showTouchIndicators ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: NetworkInspector.showTouchIndicators
                            ? Colors.purple
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // const PopupMenuDivider(),
          // PopupMenuItem(
          //   value: 'toggle_logger',
          //   child: Row(
          //     children: [
          //       Icon(
          //         NetworkInspector.isEnabled ? Icons.stop : Icons.play_arrow,
          //         color: NetworkInspector.isEnabled ? Colors.red : Colors.green,
          //       ),
          //       const SizedBox(width: 12),
          //       Text(
          //         NetworkInspector.isEnabled ? 'Disable Logger' : 'Enable Logger',
          //         style: TextStyle(
          //           fontWeight: FontWeight.w600,
          //           color: NetworkInspector.isEnabled ? Colors.red : Colors.green,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      );

      setState(() => _isMenuOpen = false);
      if (result == null) return;

      switch (result) {
        case 'requests':
          widget.onRequestsTap?.call();
          break;
        case 'environment':
          widget.onEnvironmentTap?.call();
          break;
        case 'touch_indicators':
          NetworkInspector.toggleTouchIndicators();
          setState(() {});
          break;
        case 'toggle_logger':
          NetworkInspector.isEnabled
              ? NetworkInspector.disable()
              : NetworkInspector.enable();
          setState(() {});
          break;
      }
    } catch (_) {
      setState(() => _isMenuOpen = false);
    }
  }

  void _snapToEdge(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    final maxX = size.width - _circleSize - _margin;
    final maxY = size.height -
        _circleSize -
        padding.top -
        padding.bottom -
        _margin;

    final snapLeft = _position.dx < size.width / 2;

    setState(() {
      _position = Offset(
        snapLeft ? _margin : maxX,
        _position.dy.clamp(_margin, maxY),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentEnv = NetworkInspector.selectedEnvironment;

    return Positioned(
      left: _position.dx,
      top: _position.dy + MediaQuery.of(context).padding.top,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (_) => _snapToEdge(context),
        onTap: () {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) _showContextMenu(context, box);
        },
        child: Container(
          width: _circleSize,
          height: _circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (currentEnv?.color ?? Colors.blue).withOpacity(0.8),
                currentEnv?.color ?? Colors.blue,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: (currentEnv?.color ?? Colors.blue).withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.network_check,
                color: Colors.white,
                size: 28,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black45,
                  ),
                ],
              ),
              if (NetworkInspector.showTouchIndicators)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentEnv?.name.substring(0, 2).toUpperCase() ?? 'NI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}