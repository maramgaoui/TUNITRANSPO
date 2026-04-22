import 'package:flutter/material.dart';

class TimeText extends StatelessWidget {
  final String time;
  final TextStyle? style;

  const TimeText(this.time, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(time, style: style),
    );
  }
}
