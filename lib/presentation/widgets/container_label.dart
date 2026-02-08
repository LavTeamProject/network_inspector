import 'package:flutter/material.dart';

class ContainerLabel extends StatelessWidget {
  final String? text;
  final Color color;
  final Color textColor;
  final EdgeInsets padding;
  final double borderRadius;


  const ContainerLabel({
    this.text,
    this.color = Colors.grey,
    this.textColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    this.borderRadius = 8,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: color,
      ),
      child: Text(
        text ?? 'N/A',
        style:
            Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
      ),
    );
  }
}
