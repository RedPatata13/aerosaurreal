import 'package:flutter/material.dart';

class AqiCard extends StatelessWidget {
  final Color background;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final VoidCallback onInfo;
  final String valueLabel;
  final int aqiValue;
  final double percent;
  final String percentText;
  final Color ringColor;
  final double shiftTextPercent;
  final double shiftRingPercent;

  const AqiCard({
    super.key,
    required this.background,
    required this.titleStyle,
    required this.bodyStyle,
    required this.onInfo,
    required this.valueLabel,
    required this.aqiValue,
    required this.percent,
    required this.percentText,
    required this.ringColor,
    this.shiftTextPercent = 0.05,
    this.shiftRingPercent = 0.07,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final shiftTextLeft = -(screenWidth * shiftTextPercent);
    final shiftRingLeft = -(screenWidth * shiftRingPercent);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 22, 20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.air, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Air Quality Index',
                          style: bodyStyle,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onInfo,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Transform.translate(
                  offset: Offset(shiftTextLeft, 0),
                  child: Center(
                    child: Text(
                      valueLabel,
                      style: titleStyle.copyWith(
                        fontSize: (titleStyle.fontSize ?? 16) + 6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Transform.translate(
                  offset: Offset(shiftTextLeft, 0),
                  child: Center(
                    child: Text(
                      'AQI: $aqiValue',
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: (bodyStyle.fontSize ?? 14) + 2,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.translate(
            offset: Offset(shiftRingLeft, 0),
            child: _PercentRing(
              percentText: percentText,
              ringColor: ringColor,
              percent: percent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentRing extends StatelessWidget {
  final String percentText;
  final Color ringColor;
  final double percent;

  const _PercentRing({
    required this.percentText,
    required this.ringColor,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: CircularProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              strokeWidth: 7.5,
              backgroundColor: ringColor.withValues(alpha: 0.25),
              color: ringColor,
            ),
          ),
          Text(
            percentText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

