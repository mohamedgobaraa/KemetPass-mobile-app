import 'package:flutter/material.dart';
import 'package:kemetpass/screens/know_me_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/where_am_i_screen.dart';
import 'screens/translate_hieroglyphic_screen.dart';
import 'screens/who_am_i_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/community_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/trip_planner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

// دالة للتحقق من حالة تسجيل الدخول (تستخدم في SplashScreen)
Future<bool> checkLoginStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // التحقق من وجود معرف المستخدم أو رمز الوصول
  String? userId = prefs.getString('user_id');
  String? token = prefs.getString('user_token');
  
  return userId != null && token != null;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KemetPass App',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: SplashScreen(), // استخدام شاشة البداية
      routes: {
        '/home': (context) => HomePage(),
        '/chat': (context) => ChatPage(),
        '/saved': (context) => BookmarksScreen(),
        '/profile': (context) => ProfileScreen(),
        '/login': (context) => LoginScreen(),
        '/where_am_i': (context) => WhereAmIScreen(),
        '/translate_hieroglyphic': (context) => TranslateHieroglyphicScreen(),
        '/who_am_i': (context) => WhoAmIScreen(),
        '/get_temp': (context) => WeatherScreen(),
        '/know_me': (context) => KnowMeScreen(),
        '/community': (context) => CommunityScreen(),
        '/bookmarks': (context) => BookmarksScreen(),
        '/trip_planner': (context) => TripPlannerScreen(),
      },
    );
  }
}
