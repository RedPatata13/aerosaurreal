import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double horizontalPadding = 12 * 2;
    final double itemWidth = (width - horizontalPadding) / 3;
    final double circleDiameter = 85;
    final double iconSize = 28;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final List<String> pageNames = ["Dashboard", "Monitoring", "Insights"];

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 12 + currentIndex * itemWidth + (itemWidth / 2),
        end: 12 + currentIndex * itemWidth + (itemWidth / 2),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, animatedNotchCenter, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: BottomNavClipper(
                notchCenter: animatedNotchCenter,
                notchRadius: circleDiameter / 2,
              ),
              child: Container(height: 80, color: colors.primary),
            ),

            SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_icons.length, (index) {
                  final bool isActive = index == currentIndex;

                  return GestureDetector(
                    onTap: () => onTap(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: isActive ? -20 : 0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, value),
                              child: Icon(
                                _icons[index],
                                size: iconSize,
                                color: isActive
                                    ? colors.primary
                                    : colors.onPrimary.withOpacity(0.7),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isActive ? 1 : 0,
                          child: isActive
                              ? Text(
                                  pageNames[index],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

final List<IconData> _icons = [
  Icons.dashboard_rounded,
  Icons.bar_chart_rounded,
  Icons.insights_rounded,
];

class BottomNavClipper extends CustomClipper<Path> {
  final double notchCenter;
  final double notchRadius;
  final double cornerRadius;

  BottomNavClipper({
    required this.notchCenter,
    required this.notchRadius,
    this.cornerRadius = 20,
  });

  @override
  Path getClip(Size size) {
    final Path path = Path();

    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.lineTo(notchCenter - notchRadius - 10, 0);
    path.quadraticBezierTo(
      notchCenter - notchRadius,
      0,
      notchCenter - notchRadius + 5,
      10,
    );
    path.arcToPoint(
      Offset(notchCenter + notchRadius - 5, 10),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      notchCenter + notchRadius,
      0,
      notchCenter + notchRadius + 10,
      0,
    );

    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant BottomNavClipper oldClipper) {
    return oldClipper.notchCenter != notchCenter;
  }
}
