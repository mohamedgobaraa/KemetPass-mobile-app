import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/community_db_service.dart';
import 'home_screen.dart'; // Import the HomeScreen
import 'login_screen.dart'; // Import the LoginScreen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.forward();
    
    // Initialize app and check authentication
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    try {
      // التحقق من حالة تسجيل الدخول فقط
      final userId = await ApiService.getUserId();
      
      // Delay for animation to complete
      await Future.delayed(Duration(seconds: 3));
      
      // Navigate to appropriate screen
      if (mounted) {
        if (userId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      }
    } catch (e) {
      print("Error initializing app: $e");
      // Still navigate to login screen if there's an error
      if (mounted) {
        await Future.delayed(Duration(seconds: 3));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEFFD2), // Light background color
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.explore,
                    size: 100,
                    color: Color(0xFFFF7D29),
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                'KemetPass',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7D29),
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Explore Ancient Egyptian Civilization',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7D29)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
