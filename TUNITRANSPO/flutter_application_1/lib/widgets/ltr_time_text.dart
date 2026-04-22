import 'package:flutter/material.dart';

/// Displays time-like text in LTR direction regardless of current locale.
class LtrTimeText extends StatelessWidget {
  final String time;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const LtrTimeText(
    this.time, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  static WidgetSpan asSpan(
    String time, {
    TextStyle? style,
    PlaceholderAlignment alignment = PlaceholderAlignment.middle,
  }) {
    return WidgetSpan(
      alignment: alignment,
      child: LtrTimeText(
        time,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        time,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}
