import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

Widget wrapTutorialShowcase({
  required Widget child,
  required GlobalKey? showcaseKey,
  required String title,
  required String description,
  ShapeBorder? shapeBorder,
  TooltipPosition? tooltipPosition,
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
    tooltipPosition: tooltipPosition,
    container: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ShowcaseView.get().next(force: true),
      child: _TutorialBubble(
        title: title,
        description: description,
        tooltipPosition: tooltipPosition ?? TooltipPosition.bottom,
      ),
    ),
    child: child,
  );
}

class _TutorialBubble extends StatelessWidget {
  const _TutorialBubble({
    required this.title,
    required this.description,
    required this.tooltipPosition,
  });

  final String title;
  final String description;
  final TooltipPosition tooltipPosition;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
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
    );

    final pointer = CustomPaint(
      size: const Size(26, 12),
      painter: _TutorialBubblePointerPainter(direction: tooltipPosition),
    );

    return switch (tooltipPosition) {
      TooltipPosition.top => Column(
        mainAxisSize: MainAxisSize.min,
        children: [bubble, pointer],
      ),
      TooltipPosition.bottom => Column(
        mainAxisSize: MainAxisSize.min,
        children: [pointer, bubble],
      ),
      TooltipPosition.left => Row(
        mainAxisSize: MainAxisSize.min,
        children: [bubble, pointer],
      ),
      TooltipPosition.right => Row(
        mainAxisSize: MainAxisSize.min,
        children: [pointer, bubble],
      ),
    };
  }
}

class _TutorialBubblePointerPainter extends CustomPainter {
  const _TutorialBubblePointerPainter({required this.direction});

  final TooltipPosition direction;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    switch (direction) {
      case TooltipPosition.top:
        path
          ..moveTo(size.width / 2, size.height)
          ..lineTo(0, 0)
          ..lineTo(size.width, 0);
      case TooltipPosition.bottom:
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(0, size.height)
          ..lineTo(size.width, size.height);
      case TooltipPosition.left:
        path
          ..moveTo(size.width, size.height / 2)
          ..lineTo(0, 0)
          ..lineTo(0, size.height);
      case TooltipPosition.right:
        path
          ..moveTo(0, size.height / 2)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height);
    }

    path
      ..close();

    canvas.drawShadow(path, const Color(0x33000000), 8, false);

    final paint = Paint()..color = const Color(0xFF1A2230);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
