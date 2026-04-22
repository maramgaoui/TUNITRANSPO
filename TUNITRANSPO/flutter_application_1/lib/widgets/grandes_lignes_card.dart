import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ltr_time_text.dart';

class GrandesLignesResult {
  final String trainNumber;
  final String routeName;
  final String departureStation;
  final String arrivalStation;
  final String departureTime;
  final String arrivalTime;
  final int durationMinutes;
  final double price;
  final String operatingDaysLabel;
  final List<StopPreview> keyStops;

  const GrandesLignesResult({
    required this.trainNumber,
    required this.routeName,
    required this.departureStation,
    required this.arrivalStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.price,
    required this.operatingDaysLabel,
    required this.keyStops,
  });

  static String formatDays(List<int> days) {
    final sorted = [...days]..sort();
    if (_listEquals(sorted, const [0, 1, 2, 3, 4, 5, 6])) return 'Tous les jours';
    if (_listEquals(sorted, const [1, 2, 3, 4, 5, 6])) return 'Lun – Sam';
    if (_listEquals(sorted, const [1, 2, 3, 4, 5])) return 'Lun – Ven';
    if (_listEquals(sorted, const [0])) return 'Dim & Fetes';
    return 'Jours speciaux';
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class StopPreview {
  final String stationName;
  final String arrivalTime;

  const StopPreview({
    required this.stationName,
    required this.arrivalTime,
  });
}

class GrandesLignesCard extends StatefulWidget {
  final GrandesLignesResult result;
  final VoidCallback? onTap;

  const GrandesLignesCard({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  State<GrandesLignesCard> createState() => _GrandesLignesCardState();
}

class _GrandesLignesCardState extends State<GrandesLignesCard> {
  bool _expandedStops = false;

  int get _previewCount {
    if (widget.result.keyStops.length <= 2) return widget.result.keyStops.length;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.textLight : AppTheme.textDark;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : AppTheme.mediumGrey;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : AppTheme.lightGrey;
    final accentTeal = AppTheme.primaryTealBrand;

    final stopsToShow = _expandedStops
        ? widget.result.keyStops
        : widget.result.keyStops.take(_previewCount).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.lightGrey,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentTeal.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.train,
                        size: 18,
                        color: accentTeal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.result.routeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        widget.result.trainNumber,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: dividerColor, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TerminalBlock(
                        time: widget.result.departureTime,
                        station: widget.result.departureStation,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        alignEnd: false,
                      ),
                    ),
                    Expanded(
                      child: _TerminalBlock(
                        time: widget.result.arrivalTime,
                        station: widget.result.arrivalStation,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (stopsToShow.isNotEmpty)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _StopTimeline(
                      stops: stopsToShow,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      lineColor: accentTeal,
                    ),
                  ),
                if (widget.result.keyStops.length > _previewCount)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() => _expandedStops = !_expandedStops);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: accentTeal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        _expandedStops ? 'Voir moins' : 'Voir tous les arrets',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Divider(color: dividerColor, height: 1),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FooterInfo(
                      icon: Icons.schedule,
                      text: _formatDuration(widget.result.durationMinutes),
                      color: secondaryTextColor,
                    ),
                    _FooterInfo(
                      icon: Icons.payments_outlined,
                      text: '${widget.result.price.toStringAsFixed(3)} TND',
                      color: secondaryTextColor,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accentTeal.withValues(alpha: isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.result.operatingDaysLabel,
                        style: TextStyle(
                          color: isDark ? AppTheme.lightTeal : AppTheme.primaryTealUI,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class _TerminalBlock extends StatelessWidget {
  final String time;
  final String station;
  final Color textColor;
  final Color secondaryTextColor;
  final bool alignEnd;

  const _TerminalBlock({
    required this.time,
    required this.station,
    required this.textColor,
    required this.secondaryTextColor,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        LtrTimeText(
          time,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          station,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StopTimeline extends StatelessWidget {
  final List<StopPreview> stops;
  final Color textColor;
  final Color secondaryTextColor;
  final Color lineColor;

  const _StopTimeline({
    required this.stops,
    required this.textColor,
    required this.secondaryTextColor,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: lineColor.withValues(alpha: 0.85), width: 1.2),
        ),
      ),
      child: Column(
        children: stops
            .map(
              (stop) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _StopDot(
                      isMajorHub: _isMajorHub(stop.stationName),
                      lineColor: lineColor,
                    ),
                    const SizedBox(width: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        stop.arrivalTime,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stop.stationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  bool _isMajorHub(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized.contains('sousse') || normalized.contains('sfax');
  }
}

class _StopDot extends StatelessWidget {
  final bool isMajorHub;
  final Color lineColor;

  const _StopDot({
    required this.isMajorHub,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMajorHub ? lineColor : Colors.transparent,
        border: Border.all(color: lineColor, width: 1.5),
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FooterInfo({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
