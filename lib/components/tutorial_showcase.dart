import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

Widget wrapTutorialShowcase({
  required Widget child,
  required GlobalKey? showcaseKey,
  required String title,
  required String description,
  ShapeBorder? shapeBorder,
}) {
  if (showcaseKey == null) return child;

  return Showcase.withWidget(
    key: showcaseKey,
    targetShapeBorder:
        shapeBorder ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
    overlayOpacity: 0.82,
    toolTipMargin: 22,
    targetTooltipGap: 18,
    container: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ShowcaseView.get().next(force: true),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2230),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD2D9E3),
                height: 1.4,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    ),
    child: child,
  );
}
