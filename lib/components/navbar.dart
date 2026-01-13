import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const int itemCount = 3;
  static const double navHeight = 80;
  static const double iconSize = 28;
  static const double circleDiameter = 85;
  static const double horizontalOverflow = 40;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double itemWidth = (width) / itemCount;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    double notchCenterForIndex(int index) {
      return itemWidth * index + itemWidth / 2;
    }

    final List<String> pageNames = ["Dashboard", "Monitoring", "Insights"];

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: notchCenterForIndex(currentIndex),
        end: notchCenterForIndex(currentIndex),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, animatedNotchCenter, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -horizontalOverflow,
              right: -horizontalOverflow,
              bottom: 0,
              child: ClipPath(
                clipper: BottomNavClipper(
                  notchCenter: animatedNotchCenter + horizontalOverflow,
                  notchRadius: circleDiameter / 2,
                ),
                child: Container(
                  height: navHeight,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),

            /// Nav items
            SizedBox(
              height: navHeight,
              child: Row(
                children: List.generate(itemCount, (index) {
                  final bool isActive = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
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
                                child: isActive
                                    ? Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: theme.scaffoldBackgroundColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          _icons[index],
                                          size: iconSize,
                                          color: colors.primary,
                                        ),
                                      )
                                    : Icon(
                                        _icons[index],
                                        size: iconSize,
                                        color: colors.onPrimary.withOpacity(
                                          0.7,
                                        ),
                                      ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),

                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: isActive ? -13 : 0,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, value),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isActive ? 1 : 0.6,
                                  child: Text(
                                    pageNames[index],
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isActive
                                          ? colors.onPrimary
                                          : colors.onPrimary.withOpacity(0.7),
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
    final path = Path();
    const double notchDepth = 43;
    final double notchHalfWidth = (notchRadius) * 1.25;

    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.lineTo(notchCenter - notchHalfWidth - 12, 0);

    path.cubicTo(
      notchCenter - notchHalfWidth * 0.75,
      0,
      notchCenter - notchHalfWidth * 0.75,
      notchDepth,
      notchCenter,
      notchDepth,
    );

    path.cubicTo(
      notchCenter + notchHalfWidth * 0.75,
      notchDepth,
      notchCenter + notchHalfWidth * 0.75,
      0,
      notchCenter + notchHalfWidth + 12,
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
