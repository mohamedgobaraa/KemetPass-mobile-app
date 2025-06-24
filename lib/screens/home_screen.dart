import 'package:flutter/material.dart';
import '../widgets/trending_section.dart';
import '../widgets/features_section.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

const Color backgroundColor = Color(0xFFFEFFD2);
const Color secondaryColor = Color(0xFFFFEEA9);
const Color primaryColor = Color(0xFFFFBF78);
const Color accentColor = Color(0xFFFF7D29);
const Color inactiveIconColor = Colors.grey;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? firstName;
  String? profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = await ApiService.getUserId();
      if (userId != null) {
        // استخدام getUserProfile للحصول على البيانات الفعلية للمستخدم
        final userProfile = await ApiService.getUserProfile();
        
        if (userProfile['success']) {
          final profile = userProfile['profile'];
          setState(() {
            firstName = profile['firstName'] ?? 'User';
            profileImageUrl = profile['profileImageUrl'];
            
            print("صورة الملف الشخصي في الشاشة الرئيسية: $profileImageUrl");
            
            _isLoading = false;
          });
        } else {
          setState(() {
            firstName = "User";
            profileImageUrl = null;
            _isLoading = false;
          });
        }
      } else {
        // User is not logged in, redirect to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      setState(() {
        firstName = "User";
        profileImageUrl = null;
        _isLoading = false;
      });
      print("Error loading user data: ${e.toString()}");
    }
  }

  Widget _buildProfileImage() {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      // عرض أيقونة افتراضية إذا لم تكن هناك صورة
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.orange.shade50,
        child: Icon(Icons.person, color: accentColor, size: 30),
      );
    }
    
    // استخدام نهج بديل لعرض الصورة الشخصية لتلافي الأخطاء
    print("محاولة عرض الصورة في الصفحة الرئيسية: $profileImageUrl");
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.shade50,
        image: DecorationImage(
          image: NetworkImage(profileImageUrl!),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            print("خطأ في تحميل الصورة في الصفحة الرئيسية: $exception");
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Enhanced Header Section
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${firstName ?? 'User'} 👋',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Explore the Civilization',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        Hero(
                          tag: 'profile',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildProfileImage(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    // Enhanced Search Bar
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: accentColor, size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search civilizations...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.filter_list, color: accentColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Enhanced Features Section
            SliverPadding(
              padding: EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Latest Features',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    EnhancedFeaturesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.house, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.message, size: 22),
              label: 'Chatbot',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.users, size: 22),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.bookmark, size: 22),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.user, size: 22),
              label: 'Profile',
            ),
          ],
          currentIndex: 0,
          selectedItemColor: accentColor,
          unselectedItemColor: inactiveIconColor,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/home');
                break;
              case 1:
                Navigator.pushNamed(context, '/chat');
                break;
              case 2:
                Navigator.pushNamed(context, '/community');
                break;
              case 3:
                Navigator.pushNamed(context, '/saved');
                break;
              case 4:
                Navigator.pushNamed(context, '/profile');
                break;
            }
          },
        ),
      ),
    );
  }
}

class EnhancedFeaturesList extends StatelessWidget {
  final List<Map<String, String>> features = [
    {
      "title": "WHERE AM I",
      "description": "Upload an image to identify the place.",
      "image": 'assets/images/where_im.webp',
      "route": "/where_am_i",
    },
    {
      "title": "WHO AM I",
      "description": "Upload an image to identify the king or queen.",
      "image": 'assets/images/who_im.webp',
      "route": "/who_am_i",
    },
    {
      "title": "KNOW ME",
      "description": "Learn about kings and queens.",
      "image": 'assets/images/know_me.webp',
      "route": "/know_me",
    },
    {
      "title": "TRANSLATE",
      "description": "Hieroglyphic to known languages.",
      "image": 'assets/images/translate_to_me.webp',
      "route": "/translate_hieroglyphic",
    },
    {
      "title": "TRIP PLANNER",
      "description": "Plan your trip.",
      "image": 'assets/images/know_me.webp',
      "route": "/trip_planner",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, feature["route"]!);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: feature["title"]!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                      child: Image.asset(
                        feature["image"]!,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature["title"]!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            feature["description"]!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}