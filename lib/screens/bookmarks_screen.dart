import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/community_db_service.dart';
import 'dart:io';

class BookmarksScreen extends StatefulWidget {
  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final CommunityDbService _dbService = CommunityDbService();
  bool _isLoading = true;
  bool _isServerConnected = true;
  List<CommunityPost> _bookmarkedPosts = [];
  
  @override
  void initState() {
    super.initState();
    _checkServerAndLoadBookmarks();
  }
  
  Future<void> _checkServerAndLoadBookmarks() async {
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
          _bookmarkedPosts = [];
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showServerConnectionError();
        });
        return;
      }
      
      // Get bookmarked posts from server
      final posts = await _dbService.getBookmarkedPosts();
      
      setState(() {
        _bookmarkedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error checking server and loading bookmarks: $e");
      setState(() {
        _isLoading = false;
        _isServerConnected = false;
        _bookmarkedPosts = [];
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
          content: Text("لا يمكن الوصول للخادم. خاصية المفضلة غير متاحة بدون اتصال بالإنترنت."),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red[700],
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            textColor: Colors.white,
            onPressed: () {
              _checkServerAndLoadBookmarks();
            },
          ),
        ),
      );
    }
  }
  
  Future<void> _removeBookmark(String postId) async {
    try {
      final result = await _dbService.bookmarkPost(postId, false);
      
      if (result['success']) {
        setState(() {
          _bookmarkedPosts.removeWhere((post) => post.id == postId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تمت إزالة المنشور من المفضلة"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل إزالة المنشور من المفضلة: ${result['error']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error removing bookmark: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ في إزالة المنشور من المفضلة"),
          backgroundColor: Colors.red,
        ),
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
      // Local file image
      return Container(
        height: 200,
        color: Colors.grey.shade300,
        child: Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }
  }
  
  Widget _buildBookmarkedPostCard(CommunityPost post) {
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
                IconButton(
                  icon: Icon(
                    Icons.bookmark,
                    color: Color(0xFFFF7D29),
                    size: 20,
                  ),
                  onPressed: () => _removeBookmark(post.id),
                  constraints: BoxConstraints(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoRow(Icons.favorite, post.likes.toString()),
              ],
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
  
  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "لا توجد منشورات محفوظة",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "قم بحفظ المنشورات لعرضها هنا",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/community');
            },
            icon: Icon(Icons.explore),
            label: Text("استكشاف المجتمع"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF7D29),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
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
            "خاصية المفضلة تحتاج اتصال بالإنترنت للعمل.\nحاول الاتصال بالإنترنت وأعد المحاولة.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _checkServerAndLoadBookmarks,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Text(
          "المنشورات المحفوظة",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _isServerConnected 
              ? Icon(Icons.cloud_done, color: Colors.green)
              : Icon(Icons.cloud_off, color: Colors.red),
            onPressed: () {
              if (!_isServerConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("لا يمكن الوصول للخادم. خاصية المفضلة تتطلب اتصال بالإنترنت."),
                    action: SnackBarAction(
                      label: 'إعادة المحاولة',
                      onPressed: () {
                        _checkServerAndLoadBookmarks();
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
      body: _isLoading
        ? Center(
            child: CircularProgressIndicator(color: Color(0xFFFF7D29)),
          )
        : !_isServerConnected
          ? _buildOfflineView()
          : _bookmarkedPosts.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _checkServerAndLoadBookmarks,
                color: Color(0xFFFF7D29),
                child: ListView.builder(
                  itemCount: _bookmarkedPosts.length,
                  itemBuilder: (context, index) {
                    return _buildBookmarkedPostCard(_bookmarkedPosts[index]);
                  },
                ),
              ),
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
        currentIndex: 3,
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
              Navigator.pushNamed(context, '/community');
              break;
            case 3:
              // Already on Bookmarks page
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}

// إضافة صفحة عرض الصورة كاملة
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