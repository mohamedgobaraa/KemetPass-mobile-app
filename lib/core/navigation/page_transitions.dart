import 'package:flutter/material.dart';

// Collection of custom page transitions for the app
class KemetPageTransitions {
  // Slide transition from right to left (for forward navigation)
  static Widget slideTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  // Fade transition
  static Widget fadeTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  // Scale transition
  static Widget scaleTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  // Rotate transition
  static Widget rotateTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  // Combined fade and slide transition
  static Widget fadeSlideTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) {
    const begin = Offset(0.0, 0.3);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: offsetAnimation,
        child: child,
      ),
    );
  }

  // Egyptian themed "sand" transition (simulates sand reveal)
  static Widget sandTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.transparent,
              ],
              stops: [animation.value, animation.value + 0.2],
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  // Egyptian themed "pyramid" transition (reveals from center)
  static Widget pyramidTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipPath(
          clipper: PyramidClipper(animation.value),
          child: child,
        );
      },
      child: child,
    );
  }

  // Egyptian themed "scroll" transition (simulates unrolling a papyrus)
  static Widget scrollTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Custom page route that uses the specified transition
  static PageRouteBuilder<T> customPageRoute<T>({
    required Widget page,
    required Function transitionBuilder,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return transitionBuilder(context, animation, secondaryAnimation, child);
      },
      transitionDuration: duration,
    );
  }

  // Preset routes for common transitions

  // Standard forward navigation (slide from right)
  static Route<T> forwardRoute<T>(Widget page) {
    return customPageRoute<T>(
      page: page,
      transitionBuilder: slideTransition,
    );
  }

  // Fade transition for modal pages
  static Route<T> fadeRoute<T>(Widget page) {
    return customPageRoute<T>(
      page: page,
      transitionBuilder: fadeTransition,
    );
  }

  // Egyptian themed sand transition
  static Route<T> sandRoute<T>(Widget page) {
    return customPageRoute<T>(
      page: page,
      transitionBuilder: sandTransition,
      duration: const Duration(milliseconds: 800),
    );
  }

  // Egyptian themed pyramid transition
  static Route<T> pyramidRoute<T>(Widget page) {
    return customPageRoute<T>(
      page: page,
      transitionBuilder: pyramidTransition,
      duration: const Duration(milliseconds: 800),
    );
  }

  // Egyptian themed scroll transition
  static Route<T> scrollRoute<T>(Widget page) {
    return customPageRoute<T>(
      page: page,
      transitionBuilder: scrollTransition,
      duration: const Duration(milliseconds: 800),
    );
  }
}

// Custom clipper for pyramid transition
class PyramidClipper extends CustomClipper<Path> {
  final double progress;

  PyramidClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final height = size.height * progress;

    path.moveTo(centerX, 0);
    path.lineTo(centerX + (size.width / 2) * progress, height);
    path.lineTo(centerX - (size.width / 2) * progress, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(PyramidClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

// Extension methods for Navigator to use custom transitions
extension NavigatorExtensions on Navigator {
  // Navigate with a slide transition
  static Future<T?> slideTransition<T extends Object?>(
      BuildContext context,
      Widget page
      ) {
    return Navigator.of(context).push(KemetPageTransitions.forwardRoute<T>(page));
  }

  // Navigate with a fade transition
  static Future<T?> fadeTransition<T extends Object?>(
      BuildContext context,
      Widget page
      ) {
    return Navigator.of(context).push(KemetPageTransitions.fadeRoute<T>(page));
  }

  // Navigate with a sand transition
  static Future<T?> sandTransition<T extends Object?>(
      BuildContext context,
      Widget page
      ) {
    return Navigator.of(context).push(KemetPageTransitions.sandRoute<T>(page));
  }

  // Navigate with a pyramid transition
  static Future<T?> pyramidTransition<T extends Object?>(
      BuildContext context,
      Widget page
      ) {
    return Navigator.of(context).push(KemetPageTransitions.pyramidRoute<T>(page));
  }

  // Navigate with a scroll transition
  static Future<T?> scrollTransition<T extends Object?>(
      BuildContext context,
      Widget page
      ) {
    return Navigator.of(context).push(KemetPageTransitions.scrollRoute<T>(page));
  }
}

// Hero tag generation utility to ensure unique tags
class HeroTags {
  // Generate a unique tag for the specified screen and item
  static String generate(String screen, String itemId) {
    return '${screen}_${itemId}';
  }

  // Predefined constants for common screens to avoid typos
  static const String PROFILE = 'profile';
  static const String COMMUNITY = 'community';
  static const String CHAT = 'chat';
  static const String FEATURE = 'feature';
  static const String IMAGE = 'image';
  static const String TITLE = 'title';
  static const String LOGO = 'logo';
}

// Hero widgets that can be used throughout the app
class KemetHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final Duration duration;

  const KemetHero({
    required this.tag,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
          BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext,
          ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: child,
            );
          },
          child: child,
        );
      },
      transitionOnUserGestures: true,
      child: child,
    );
  }
}
