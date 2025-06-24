import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../services/community_db_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  List<CommunityPost> _posts = [];
  bool _isComposing = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _currentUsername;
  String? _currentUserImage;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isServerConnected = true;
  // Add database service instance
  final CommunityDbService _dbService = CommunityDbService();
  String? _currentUserId;
  String? _existingImageUrlForEdit; // New variable to hold existing image URL during edit
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkServerAndFetchPosts();
  }
  
  Future<void> _loadUserData() async {
    try {
      // Get user ID to identify the current user
      final userId = await ApiService.getUserId();
      print("Current user ID: $userId");
      
      if (userId != null) {
        // Force refresh profile data from server, not cache
        print("Forcing refresh of profile data for user: $userId");
        
        // First clear any existing image to avoid showing stale data
        setState(() {
          _currentUserImage = null;
          _currentUsername = null;
          _currentUserId = userId;
        });
        
        // Get fresh profile data from server with explicit no-cache flag
        final userProfile = await ApiService.getUserProfile(useLocalOnly: false);
        
        print("Profile data response: ${userProfile.toString()}");
        
        if (userProfile['success']) {
          final profile = userProfile['profile'];
          
          // Print the entire profile for debugging
          print("Full profile data: $profile");
          
          // Check if profileImageUrl exists and has a value
          final profileImageUrl = profile['profileImageUrl'];
          print("Raw profile image URL: $profileImageUrl");
          
          // Validate the image URL
          String? validImageUrl;
          if (profileImageUrl != null && 
              profileImageUrl.toString().isNotEmpty && 
              profileImageUrl.toString() != "null") {
            
            // Use specialized helper method for profile images
            validImageUrl = ApiService.getProfileImageUrl(profileImageUrl.toString());
            print("Validated profile image URL: $validImageUrl");
          }
          
          setState(() {
            _currentUsername = profile['username'] ?? profile['firstName'] ?? 'User';
            
            // Only set the image URL if it's valid
            if (validImageUrl != null && validImageUrl.isNotEmpty) {
              _currentUserImage = validImageUrl;
              print("Setting profile image: $_currentUserImage");
            } else {
              _currentUserImage = null;
              print("No valid profile image URL found");
            }
          });
        } else {
          print("Failed to get profile data for user ID: $userId");
          setState(() {
            _currentUsername = 'User';
            _currentUserImage = null;
          });
        }
      } else {
        print("No user ID available");
        setState(() {
          _currentUsername = 'User';
          _currentUserImage = null;
          _currentUserId = 'unknown_user';
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _currentUsername = 'User';
        _currentUserImage = null;
        _currentUserId = 'unknown_user';
      });
    }
  }
  
  Future<void> _checkServerAndFetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check server availability first
      final isServerAvailable = await _dbService.isServerAvailable();
      
      setState(() {
        _isServerConnected = isServerAvailable;
      });
      
      if (!isServerAvailable) {
        setState(() {
          _isLoading = false;
          _posts = [];
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showServerConnectionError();
        });
        return;
      }
      
      // Fetch posts from server
      final posts = await _dbService.getPosts();
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error checking server and fetching posts: $e");
      setState(() {
        _isLoading = false;
        _isServerConnected = false;
        _posts = [];
      });
      
      // Show error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showServerConnectionError();
      });
    }
  }
  
  void _showServerConnectionError() {
    // Only show if mounted and server not connected
    if (mounted && !_isServerConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("لا يمكن الوصول للخادم. ميزة المجتمع غير متاحة بدون اتصال بالإنترنت."),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red[700],
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            textColor: Colors.white,
            onPressed: () {
              _checkServerAndFetchPosts();
            },
          ),
        ),
      );
    }
  }
  
  Future<void> _submitPost() async {
    // اذا كان المحتوى فارغاً، ابرز مع الخروج
    if (_postController.text.isEmpty) return;
    
    // اذا لم يكن متصلاً بالخادم، ابرز مع رسالة خطأ
    if (!_isServerConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("لا يمكن إنشاء منشور بدون اتصال بالإنترنت."),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // إنشاء المنشور على الخادم مباشرة
      final result = await _dbService.createPost(_postController.text, _selectedImage);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم إنشاء المنشور بنجاح")),
        );
        
        // تحديث المنشورات لإظهار المنشور الجديد
        _checkServerAndFetchPosts();
        
        // مسح المدخلات والصورة المحددة
        setState(() {
          _postController.clear();
          _selectedImage = null;
          _isComposing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل إنشاء المنشور: ${result['error']}")),
        );
      }
    } catch (e) {
      print("Error creating post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ أثناء إنشاء المنشور. يرجى المحاولة مرة أخرى.")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        // تحديد أبعاد أقل وجودة أقل لضمان حجم ملف أصغر
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        // الحصول على معلومات الملف للتشخيص
        final fileSize = await File(image.path).length();
        print("تم اختيار صورة بحجم: ${(fileSize / 1024).toStringAsFixed(2)} كيلوبايت");
        
        setState(() {
          _selectedImage = File(image.path);
          _isComposing = true; // Automatically open compose area when image selected
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في اختيار الصورة: ${e.toString()}")),
      );
    }
  }
  
  Future<void> _likePost(String postId) async {
    // Check server connection first
    if (!_isServerConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("لا يمكن الإعجاب بالمنشورات بدون اتصال بالإنترنت."),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }
    
    // Find the post in our list
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;
    
    // Optimistically update UI
    setState(() {
      _posts[postIndex] = _posts[postIndex].copyWith(
        likes: _posts[postIndex].likes + 1,
      );
    });
    
    try {
      // Send like to server
      final result = await _dbService.likePost(postId);
      
      if (!result['success']) {
        // Revert UI update if the server request failed
        setState(() {
          _posts[postIndex] = _posts[postIndex].copyWith(
            likes: _posts[postIndex].likes - 1,
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل الإعجاب بالمنشور: ${result['error']}")),
        );
      }
    } catch (e) {
      // Revert UI update if there was an error
      setState(() {
        _posts[postIndex] = _posts[postIndex].copyWith(
          likes: _posts[postIndex].likes - 1,
        );
      });
      
      print("Error liking post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ أثناء الإعجاب بالمنشور. يرجى المحاولة مرة أخرى.")),
      );
    }
  }
  
  Widget _buildImage(String? imagePath) {
    if (imagePath == null) return SizedBox.shrink();
    
    if (imagePath.startsWith('http')) {
      // Network image
      return GestureDetector(
        onTap: () {
          // عرض الصورة بالحجم الكامل عند النقر عليها
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(imageUrl: imagePath),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 300, // ارتفاع أقصى
            minHeight: 150, // ارتفاع أدنى
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print("Error loading network image: $error");
                return Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                      color: Color(0xFFFF7D29),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else {
      // Local file image (temporarily selected before uploading)
      return GestureDetector(
        onTap: () {
          // عرض الصورة بالحجم الكامل عند النقر عليها
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(localPath: imagePath),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 300, // ارتفاع أقصى
            minHeight: 150, // ارتفاع أدنى
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print("Error loading local image: $error");
                return Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Flexible(
              child: Text(
                "KemetPass",
                style: TextStyle(
                  color: Color(0xFFFF7D29),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Flexible(
              child: Text(
                " Community",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              if (!_isServerConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("البحث غير متاح بدون اتصال بالإنترنت")),
                );
                return;
              }
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: _isServerConnected 
              ? Icon(Icons.cloud_done, color: Colors.green)
              : Icon(Icons.cloud_off, color: Colors.red),
            onPressed: () {
              if (!_isServerConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("لا يمكن الوصول للخادم. ميزة المجتمع تتطلب اتصال بالإنترنت."),
                    action: SnackBarAction(
                      label: 'إعادة المحاولة',
                      onPressed: () {
                        _checkServerAndFetchPosts();
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("متصل بالخادم"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _isComposing ? _buildComposeBar() : SizedBox.shrink(),
          Expanded(
            child: _isLoading 
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF7D29)),
                )
              : !_isServerConnected
                ? _buildOfflineView()
                : _posts.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _checkServerAndFetchPosts,
                      color: Color(0xFFFF7D29),
                      child: ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return _buildPostCard(_posts[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: (!_isComposing && _isServerConnected)
        ? FloatingActionButton(
            onPressed: () {
              setState(() {
                _isComposing = true;
              });
            },
            backgroundColor: Color(0xFFFF7D29),
            child: Icon(Icons.add),
          )
        : null,
      bottomNavigationBar: BottomNavigationBar(
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
        currentIndex: 2,
        selectedItemColor: Color(0xFFFF7D29),
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
              // Already on Community page
              break;
            case 3:
              _navigateToBookmarks();
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
  
  Widget _buildOfflineView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "لا يوجد اتصال بالإنترنت",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "ميزة المجتمع تحتاج اتصال بالإنترنت للعمل.\nحاول الاتصال بالإنترنت وأعد المحاولة.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _checkServerAndFetchPosts,
            icon: Icon(Icons.refresh),
            label: Text("التحقق من الاتصال"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF7D29),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "لا توجد منشورات بعد",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "كن أول من ينشر في مجتمع كيمت باس!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isComposing = true;
              });
            },
            icon: Icon(Icons.add),
            label: Text("إنشاء منشور جديد"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF7D29),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposeBar() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentUserAvatar(),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _postController,
                  decoration: InputDecoration(
                    hintText: "What's happening in Egypt?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
            ],
          ),
          if (_selectedImage != null)
            Container(
              height: 80,
              margin: EdgeInsets.only(top: 8),
              width: double.infinity,
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("Error displaying selected image: $error");
                            return Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image, color: Color(0xFFFF7D29)),
                      onPressed: _pickImage,
                      padding: EdgeInsets.all(0),
                      constraints: BoxConstraints(),
                      iconSize: 20,
                    ),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _isComposing = false;
                          _selectedImage = null;
                          _postController.clear();
                        });
                      },
                      padding: EdgeInsets.all(0),
                      constraints: BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  child: _isSubmitting
                    ? SizedBox(
                        width: 16,
                        height: 16, 
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text("نشر", style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF7D29),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size(60, 30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserAvatar() {
    print("Building current user avatar. Image URL: $_currentUserImage, Username: $_currentUsername");
    
    if (_currentUserImage == null || _currentUserImage!.isEmpty || _currentUserImage == "null") {
      // إذا لم تكن هناك صورة للمستخدم الحالي، نعرض دائرة بالحرف الأول من اسمه
      print("Using initial avatar for current user");
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.orange.shade50,
        child: Text(
          _currentUsername != null && _currentUsername!.isNotEmpty 
              ? _currentUsername![0].toUpperCase() 
              : "?",
          style: TextStyle(
            color: Color(0xFFFF7D29),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    } else {
      // إذا كانت هناك صورة، نتحقق أنها صالحة قبل عرضها
      print("Attempting to load image: $_currentUserImage");
      
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.orange.shade50,
        child: ClipOval(
          child: Image.network(
            _currentUserImage!,
            width: 40, 
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print("Error loading profile image: $error");
              print("Stack trace: $stackTrace");
              
              // If there's an error, return the initial avatar instead
              return Center(
                child: Text(
                  _currentUsername != null && _currentUsername!.isNotEmpty 
                      ? _currentUsername![0].toUpperCase() 
                      : "?",
                  style: TextStyle(
                    color: Color(0xFFFF7D29),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Widget _buildPostCard(CommunityPost post) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildUserAvatar(post.userImage, post.username),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      post.timeAgo,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                FutureBuilder<List<String>>(
                  future: _dbService.getBookmarkedPostIds(),
                  builder: (context, snapshot) {
                    final bookmarkedIds = snapshot.data ?? [];
                    final isBookmarked = bookmarkedIds.contains(post.id);
                    
                    return IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Color(0xFFFF7D29) : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        if (!_isServerConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("لا يمكن حفظ المنشورات بدون اتصال بالإنترنت"),
                              backgroundColor: Colors.red[700],
                            ),
                          );
                          return;
                        }
                        _bookmarkPost(post.id, !isBookmarked);
                      },
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                    );
                  }
                ),
                SizedBox(width: 5),
                // Replace Icon with PopupMenuButton
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (!_isServerConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("هذه الميزة تتطلب اتصال بالإنترنت.")),
                      );
                      return;
                    }
                    if (value == 'edit') {
                      _editPost(post);
                    } else if (value == 'delete') {
                      _confirmDeletePost(post.id);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final bool isCurrentUserPost = (_currentUserId == post.userId);
                    return <PopupMenuEntry<String>>[
                      if (isCurrentUserPost)
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blueGrey),
                              SizedBox(width: 8),
                              Text('تعديل المنشور'),
                            ],
                          ),
                        ),
                      if (isCurrentUserPost)
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('حذف المنشور'),
                            ],
                          ),
                        ),
                    ];
                  },
                  icon: Icon(Icons.more_horiz, color: Colors.grey),
                  // Adjust padding and constraints for the icon to match existing buttons
                  padding: EdgeInsets.zero,
                  splashRadius: 20,
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              post.content,
              style: TextStyle(fontSize: 15),
            ),
            if (post.images != null && post.images!.isNotEmpty) ...[
              SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 16/9, // نسبة العرض للارتفاع مناسبة للصور
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _buildImage(post.images![0]),
                ),
              ),
            ],
            SizedBox(height: 10),
            FutureBuilder<bool>(
              future: _dbService.hasUserLikedPost(post.id),
              builder: (context, snapshot) {
                final bool hasLiked = snapshot.data ?? false;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(
                      icon: hasLiked ? Icons.favorite : Icons.favorite_border,
                      color: hasLiked ? Colors.red : Colors.grey,
                      label: post.likes.toString(),
                      onPressed: () => _likePost(post.id),
                    ),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String userImage, String username) {
    if (userImage.isEmpty || userImage == "null" || userImage == "https://randomuser.me/api/portraits/lego/1.jpg") {
      // إذا كانت الصورة غير موجودة أو قيمتها الافتراضية، نعرض أيقونة افتراضية
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.orange.shade50,
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : "?",
          style: TextStyle(
            color: Color(0xFFFF7D29),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    } else {
      // إذا كانت الصورة موجودة، نعرضها
      return CircleAvatar(
        backgroundImage: NetworkImage(userImage),
        radius: 20,
        onBackgroundImageError: (exception, stackTrace) {
          // في حالة فشل تحميل الصورة
          print("Error loading user image: $exception");
        },
        backgroundColor: Colors.orange.shade50,
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.grey,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // Add a new method for bookmarking posts
  Future<void> _bookmarkPost(String postId, bool bookmark) async {
    try {
      final result = await _dbService.bookmarkPost(postId, bookmark);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookmark ? "تمت إضافة المنشور إلى المفضلة" : "تمت إزالة المنشور من المفضلة"),
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh the UI to show changes
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل ${bookmark ? 'إضافة' : 'إزالة'} المنشور: ${result['error']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error bookmarking post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ في تحديث المفضلة"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Create a new method to navigate to the bookmarks page
  Future<void> _navigateToBookmarks() async {
    // Check server availability
    final isServerAvailable = await _dbService.isServerAvailable();
    
    if (!isServerAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("لا يمكن عرض المفضلة بدون اتصال بالإنترنت"),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }
    
    // Navigate to bookmarks page
    Navigator.of(context).pushNamed('/bookmarks');
  }

  // Method to handle post editing
  void _editPost(CommunityPost post) {
    _postController.text = post.content; // Pre-fill with existing content
    // Determine if there's an existing image to display in the edit dialog
    if (post.images != null && post.images!.isNotEmpty) {
      String potentialImageUrl = post.images![0];
      if (potentialImageUrl.startsWith('http')) {
        _existingImageUrlForEdit = potentialImageUrl;
        _selectedImage = null; // No new image picked yet
      } else {
        // If it's a local path (e.g., from a previous unsynced post), set it as selected
        _selectedImage = File(potentialImageUrl);
        _existingImageUrlForEdit = null;
      }
    } else {
      _selectedImage = null;
      _existingImageUrlForEdit = null;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("تعديل المنشور"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _postController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "اكتب تعديلك هنا...",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_selectedImage != null || _existingImageUrlForEdit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Stack(
                      children: [
                        _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                _existingImageUrlForEdit!,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.grey.shade300,
                                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                                  );
                                },
                              ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                _existingImageUrlForEdit = null; // Also clear existing image
                              });
                            },
                            child: Icon(Icons.remove_circle, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  icon: Icon(Icons.image),
                  label: Text("تغيير الصورة"),
                  onPressed: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 70,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedImage = File(image.path);
                        _existingImageUrlForEdit = null; // Clear existing if new is picked
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("إلغاء"),
              onPressed: () {
                _postController.clear();
                _selectedImage = null;
                _existingImageUrlForEdit = null;
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("حفظ التعديلات"),
              onPressed: () async {
                if (_postController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("لا يمكن حفظ منشور فارغ.")),
                  );
                  return;
                }

                Navigator.of(context).pop(); // Close dialog

                setState(() {
                  _isSubmitting = true;
                });

                try {
                  print('Attempting to edit post with ID: ${post.id}');
                  final result = await _dbService.editPost(
                    post.id,
                    _postController.text,
                    _selectedImage, // Pass newly selected image
                    _existingImageUrlForEdit, // Pass existing image URL
                  );

                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("تم تعديل المنشور بنجاح")),
                    );
                    _checkServerAndFetchPosts(); // Refresh posts
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("فشل تعديل المنشور: ${result['error']}")),
                    );
                  }
                } catch (e) {
                  print("Error editing post: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("خطأ أثناء تعديل المنشور. يرجى المحاولة مرة أخرى.")),
                  );
                } finally {
                  setState(() {
                    _isSubmitting = false;
                    _postController.clear();
                    _selectedImage = null;
                    _existingImageUrlForEdit = null; // Clear after submission
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF7D29),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to confirm and delete a post
  void _confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("تأكيد الحذف"),
          content: Text("هل أنت متأكد أنك تريد حذف هذا المنشور؟"),
          actions: <Widget>[
            TextButton(
              child: Text("إلغاء"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("حذف"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                setState(() {
                  _isLoading = true; // Show loading while deleting
                });

                try {
                  print('Attempting to delete post with ID: $postId');
                  final result = await _dbService.deletePost(postId);

                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("تم حذف المنشور بنجاح")),
                    );
                    _checkServerAndFetchPosts(); // Refresh posts
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("فشل حذف المنشور: ${result['error']}")),
                    );
                  }
                } catch (e) {
                  print("Error deleting post: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("خطأ أثناء حذف المنشور. يرجى المحاولة مرة أخرى.")),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}

// إضافة Widget جديد لعرض الصورة بشكل كامل
class FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? localPath;

  const FullScreenImageViewer({Key? key, this.imageUrl, this.localPath}) 
    : assert(imageUrl != null || localPath != null),
      super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 50),
                        SizedBox(height: 16),
                        Text(
                          "فشل تحميل الصورة",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              )
            : Image.file(
                File(localPath!),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 50),
                        SizedBox(height: 16),
                        Text(
                          "فشل تحميل الصورة",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}
