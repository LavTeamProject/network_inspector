
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../network_inspector.dart';


class TouchIndicator extends StatefulWidget {
  final Widget child;
  final double indicatorSize;
  final Color indicatorColor;
  final Widget? indicator;
  final bool forceInReleaseMode;

  const TouchIndicator({
    Key? key,
    required this.child,
    this.indicator,
    this.indicatorSize = 40.0,
    this.indicatorColor = Colors.blueGrey,
    this.forceInReleaseMode = false,
  }) : super(key: key);

  @override
  _TouchIndicatorState createState() => _TouchIndicatorState();
}

class _TouchIndicatorState extends State<TouchIndicator> {
  bool _enabled = NetworkInspector.showTouchIndicators;
  Map<int, Offset> touchPositions = <int, Offset>{};

  @override
  void initState() {
    super.initState();
    NetworkInspector.onTouchIndicatorsChanged((show) {
      if (mounted) {
        setState(() {
          _enabled = show;
        });
      }
    });
  }

  Iterable<Widget> buildTouchIndicators() sync* {
    if (touchPositions.isNotEmpty) {
      for (var touchPosition in touchPositions.values) {
        yield Positioned.directional(
          start: touchPosition.dx - widget.indicatorSize / 2,
          top: touchPosition.dy - widget.indicatorSize / 2,
          textDirection: TextDirection.ltr,
          child: widget.indicator != null
              ? widget.indicator!
              : Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.indicatorColor.withOpacity(0.3),
            ),
            child: Icon(
              Icons.fingerprint,
              size: widget.indicatorSize,
              color: widget.indicatorColor.withOpacity(0.9),
            ),
          ),
        );
      }
    }
  }

  void savePointerPosition(int index, Offset position) {
    if (!mounted) return;
    setState(() {
      touchPositions[index] = position;
    });
  }

  void clearPointerPosition(int index) {
    if (!mounted) return;
    setState(() {
      touchPositions.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if ((kReleaseMode && !widget.forceInReleaseMode) || !_enabled) {
      return widget.child;
    }

    var children = [
      widget.child,
      ...buildTouchIndicators(),
    ];
    return Listener(
      onPointerDown: (opm) {
        savePointerPosition(opm.pointer, opm.position);
      },
      onPointerMove: (opm) {
        savePointerPosition(opm.pointer, opm.position);
      },
      onPointerCancel: (opc) {
        clearPointerPosition(opc.pointer);
      },
      onPointerUp: (opc) {
        clearPointerPosition(opc.pointer);
      },
      child: Stack(children: children),
    );
  }
}