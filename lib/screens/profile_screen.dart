import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const Color backgroundColor = Color(0xFFFEFFD2);
const Color primaryColor = Color(0xFFFF7D29);

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username;
  String? email;
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
            username = profile['username'] ?? 'User';
            email = profile['email'] ?? 'user@example.com';
            profileImageUrl = profile['profileImageUrl'];
            
            print("صورة الملف الشخصي في شاشة العرض: $profileImageUrl");
            
            _isLoading = false;
          });
        } else {
          setState(() {
            username = "User";
            email = "user@example.com";
            profileImageUrl = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load profile data")),
          );
        }
      } else {
        // Not logged in, redirect to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      setState(() {
        username = "User";
        email = "user@example.com";
        profileImageUrl = null;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load user data: ${e.toString()}")),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await ApiService.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to sign out: ${e.toString()}")),
      );
    }
  }

  Future<void> _refreshProfileImage() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // محاولة تحميل بيانات المستخدم مرة أخرى مع طلب البيانات من الخادم
      final userProfile = await ApiService.getUserProfile(useLocalOnly: false);
      
      if (userProfile['success']) {
        final profile = userProfile['profile'];
        setState(() {
          profileImageUrl = profile['profileImageUrl'];
          print("تم إعادة تحميل صورة الملف الشخصي: $profileImageUrl");
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم إعادة تحميل صورة الملف الشخصي")),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل في إعادة تحميل صورة الملف الشخصي")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: ${e.toString()}")),
      );
    }
  }

  // دالة مباشرة لتحميل صورة المستخدم من الخادم
  Future<void> _directImageLoad() async {
    try {
      if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("معلومات عن الصورة"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("مسار الصورة:"),
                SelectableText(profileImageUrl!),
                SizedBox(height: 10),
                Text("يتم الاتصال بالخادم..."),
                SizedBox(height: 10),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Image.network(
                    profileImageUrl!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          Text("خطأ في تحميل الصورة: $error", 
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("إغلاق"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("لا توجد صورة للتحميل"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e"))
      );
    }
  }

  Widget _buildProfileImage() {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      // عرض أيقونة افتراضية إذا لم تكن هناك صورة
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.white,
        child: Icon(Icons.person, size: 60, color: primaryColor),
      );
    }
    
    // تحسين طريقة عرض الصورة الشخصية باستخدام Image.network مباشرة
    print("محاولة عرض الصورة: $profileImageUrl");
    
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.white,
      backgroundImage: NetworkImage(profileImageUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        print("خطأ في تحميل الصورة: $exception");
      },
      child: profileImageUrl == null ? Icon(Icons.person, size: 60, color: primaryColor) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Enhanced Header Section
          Container(
            padding: EdgeInsets.only(top: 50.0, bottom: 30.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.share, color: Colors.white),
                          onPressed: () {
                            // Share action
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(),
                          ),
                        ).then((_) {
                          _loadUserData();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _buildProfileImage(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Enhanced Profile Options
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildOptionGroup(
                  title: "Account",
                  options: [
                    EnhancedProfileOption(
                      icon: Icons.favorite_border,
                      title: 'Favourite',
                      onTap: () {},
                    ),
                    EnhancedProfileOption(
                      icon: Icons.download_outlined,
                      title: 'Download',
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildOptionGroup(
                  title: "Settings",
                  options: [
                    EnhancedProfileOption(
                      icon: Icons.language,
                      title: 'Language',
                      onTap: () {},
                    ),
                    EnhancedProfileOption(
                      icon: Icons.settings_outlined,
                      title: 'Profile Settings',
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildOptionGroup(
                  title: "About",
                  options: [
                    EnhancedProfileOption(
                      icon: Icons.info_outline,
                      title: 'About Us',
                      onTap: () {},
                    ),
                    EnhancedProfileOption(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      onTap: () => _signOut(context),
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house, size: 22), label: 'Home'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.message, size: 22), label: 'Chatbot'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.users, size: 22), label: 'Community'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.bookmark, size: 22), label: 'Saved'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.user, size: 22), label: 'Profile'),
        ],
        currentIndex: 4, // Set the current index to Profile
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
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
              // Already on Profile page
              break;
          }
        },
      ),
    );
  }

  Widget _buildOptionGroup({required String title, required List<Widget> options}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Column(
                children: [
                  option,
                  if (index != options.length - 1)
                    Divider(height: 1, indent: 56, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class EnhancedProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  EnhancedProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? Colors.red : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}