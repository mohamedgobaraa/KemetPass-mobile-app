import 'package:flutter/material.dart';
import 'package:kemetpass/screens/splash_screen.dart';
import 'package:kemetpass/screens/home_screen.dart';
import 'package:kemetpass/screens/login_screen.dart';
import 'package:kemetpass/screens/register_screen.dart';
import 'package:kemetpass/screens/chat_screen.dart';
import 'package:kemetpass/screens/community_screen.dart';
import 'package:kemetpass/screens/profile_screen.dart';
import 'package:kemetpass/screens/user_saves.dart';
import 'package:kemetpass/screens/bookmarks_screen.dart';
import 'package:kemetpass/screens/where_am_i_screen.dart';
import 'package:kemetpass/screens/who_am_i_screen.dart';
import 'package:kemetpass/screens/translate_hieroglyphic_screen.dart';
import 'package:kemetpass/screens/know_me_screen.dart';
import 'package:kemetpass/screens/weather_screen.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // General navigation methods
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }
  
  static Future<dynamic> navigateToReplacement(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }
  
  static Future<dynamic> navigateToAndRemoveUntil(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName, 
      (Route<dynamic> route) => false, 
      arguments: arguments
    );
  }
  
  static void goBack() {
    return navigatorKey.currentState!.pop();
  }
  
  // Helper to check if we can go back
  static bool canGoBack() {
    return navigatorKey.currentState!.canPop();
  }
}

// Route generator for named routes
class KemetRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Get arguments passed to the route
    final args = settings.arguments;

    switch (settings.name) {
      // Add your routes here following the pattern below
      case '/':
        return _buildPageRoute(settings, SplashScreen());
      case '/home':
        return _buildPageRoute(settings, HomePage());
      case '/login':
        return _buildPageRoute(settings, LoginScreen());
      case '/register':
        return _buildPageRoute(settings, RegisterScreen());
      case '/chat':
        return _buildPageRoute(settings, ChatPage());
      case '/community':
        return _buildPageRoute(settings, CommunityScreen());
      case '/profile':
        return _buildPageRoute(settings, ProfileScreen());
      case '/saved':
        return _buildPageRoute(settings, UserSavesPage());
      case '/bookmarks':
        return _buildPageRoute(settings, BookmarksScreen());
      case '/where_am_i':
        return _buildPageRoute(settings, WhereAmIScreen());
      case '/who_am_i':
        return _buildPageRoute(settings, WhoAmIScreen());
      case '/translate_hieroglyphic':
        return _buildPageRoute(settings, TranslateHieroglyphicScreen());
      case '/know_me':
        return _buildPageRoute(settings, KnowMeScreen());
      case '/get_temp':
        return _buildPageRoute(settings, WeatherScreen());
      default:
        // If there is no such named route, show an error page
        return _buildPageRoute(settings, _ErrorPage('Route not found: ${settings.name}'));
    }
  }

  // Helper method to create page routes with transitions
  static PageRouteBuilder _buildPageRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}

// Simple error page for invalid routes
class _ErrorPage extends StatelessWidget {
  final String message;

  const _ErrorPage(this.message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Error'),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}

// Wrapper Classes for Each Screen
// These classes add any necessary transition elements or animations

class SplashScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual splash screen
    // return SplashScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('SplashScreen Placeholder'),
      ),
    );
  }
}

class HomePageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual home page
    // return HomePage();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('HomePage Placeholder'),
      ),
    );
  }
}

class LoginScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual login screen
    // return LoginScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('LoginScreen Placeholder'),
      ),
    );
  }
}

class RegisterScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual register screen
    // return RegisterScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('RegisterScreen Placeholder'),
      ),
    );
  }
}

class ChatPageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual chat page
    // return ChatPage();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('ChatPage Placeholder'),
      ),
    );
  }
}

class CommunityScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual community screen
    // return CommunityScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('CommunityScreen Placeholder'),
      ),
    );
  }
}

class ProfileScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual profile screen
    // return ProfileScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('ProfileScreen Placeholder'),
      ),
    );
  }
}

class UserSavesPageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual user saves page
    // return UserSavesPage();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('UserSavesPage Placeholder'),
      ),
    );
  }
}

class BookmarksScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual bookmarks screen
    // return BookmarksScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('BookmarksScreen Placeholder'),
      ),
    );
  }
}

class WhereAmIScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual where am i screen
    // return WhereAmIScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('WhereAmIScreen Placeholder'),
      ),
    );
  }
}

class WhoAmIScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual who am i screen
    // return WhoAmIScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('WhoAmIScreen Placeholder'),
      ),
    );
  }
}

class TranslateHieroglyphicScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual translate hieroglyphic screen
    // return TranslateHieroglyphicScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('TranslateHieroglyphicScreen Placeholder'),
      ),
    );
  }
}

class KnowMeScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual know me screen
    // return KnowMeScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('KnowMeScreen Placeholder'),
      ),
    );
  }
}

class WeatherScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import your actual weather screen
    // return WeatherScreen();
    
    // Placeholder implementation
    return Scaffold(
      body: Center(
        child: Text('WeatherScreen Placeholder'),
      ),
    );
  }
}