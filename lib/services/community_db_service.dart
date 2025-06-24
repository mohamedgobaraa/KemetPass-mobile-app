import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../screens/community_screen.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model class for community posts
class CommunityPost {
  final String id;
  final String userId;
  final String username;
  final String userImage;
  final String timeAgo;
  final String content;
  int likes;
  int comments;
  int shares;
  final List<String>? images;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.userImage,
    required this.timeAgo,
    required this.content,
    required this.likes,
    required this.comments,
    required this.shares,
    this.images,
    required this.createdAt,
  });
  
  // Create a new Post with updated values
  CommunityPost copyWith({
    String? id,
    String? userId,
    String? username,
    String? userImage,
    String? timeAgo,
    String? content,
    int? likes,
    int? comments,
    int? shares,
    List<String>? images,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      timeAgo: timeAgo ?? this.timeAgo,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Create a Post from JSON data (from server)
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    // Parse created date
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['createdAt']);
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    // Calculate time ago
    String timeAgo = _getTimeAgo(createdAt);
    
    // حفظ صورة المستخدم كما هي من الخادم دون إضافة صورة افتراضية
    // سيتم معالجة الصورة الافتراضية في الواجهة
    String userImage = json['userImage'] ?? '';
    
    return CommunityPost(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'User',
      userImage: userImage,
      timeAgo: timeAgo,
      content: json['content'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      images: json['images'] != null 
        ? List<String>.from(json['images']) 
        : null,
      createdAt: createdAt,
    );
  }
  
  // Helper function to calculate "time ago" string
  static String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }
}

class CommunityDbService {
  // خزن معرفات المنشورات التي قام المستخدم بتفضيلها أو مشاركتها للاستخدام في واجهة المستخدم فقط
  final String _USER_ACTIONS_KEY = 'community_user_actions';
  
  // Singleton pattern
  static final CommunityDbService _instance = CommunityDbService._internal();
  
  factory CommunityDbService() => _instance;
  
  CommunityDbService._internal();
  
  // Check if server is available
  Future<bool> isServerAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ping'),
        headers: await ApiService.getHeaders(),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      print("Server not available: $e");
      return false;
    }
  }
  
  // Get all posts from server only
  Future<List<CommunityPost>> getPosts() async {
    List<CommunityPost> posts = [];
    
    // Get posts from the server only
    try {
      if (await isServerAvailable()) {
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}/posts'),
          headers: await ApiService.getHeaders(),
        ).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] && data['posts'] != null) {
            final fetchedPosts = List<Map<String, dynamic>>.from(data['posts']);
            
            // Convert server posts to CommunityPost objects
            posts = fetchedPosts
                .map((postJson) => CommunityPost.fromJson(postJson))
                .toList();
          }
        }
      }
      
      return posts;
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }
  
  // Create a new post - send directly to server
  Future<Map<String, dynamic>> createPost(String content, File? image) async {
    try {
      if (!await isServerAvailable()) {
        return {
          'success': false,
          'error': 'Server not available. Cannot create posts while offline.'
        };
      }
      
      final userId = await ApiService.getUserId() ?? 'unknown_user';
      final userProfile = await ApiService.getUserProfile();
      
      // Prepare multipart request to send text and possibly image
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/posts'),
      );
      
      // Add headers
      final headers = await ApiService.getHeaders();
      request.headers.addAll(headers);
      
      // Add text fields
      request.fields['content'] = content;
      request.fields['userId'] = userId;
      
      // Add username if available
      if (userProfile['success']) {
        request.fields['username'] = userProfile['profile']['username'] ?? 'User';
      }
      
      // Add image if available
      if (image != null) {
        try {
          // التحقق من حجم الصورة قبل الإرسال
          final fileSize = await image.length();
          print("إرسال صورة بحجم: ${(fileSize / 1024).toStringAsFixed(2)} كيلوبايت");
          
          // إذا كان حجم الصورة كبير جداً، ننبه المستخدم
          if (fileSize > 5 * 1024 * 1024) { // أكبر من 5 ميجابايت
            return {
              'success': false,
              'error': 'Image is too large. Please choose a smaller image (less than 5MB).'
            };
          }
          
          // إضافة الصورة إلى الطلب مع تعيين وقت انتظار أطول
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            image.path,
          ));
        } catch (e) {
          print("Error processing image: $e");
          return {
            'success': false,
            'error': 'Failed to process image: ${e.toString()}'
          };
        }
      }
      
      // إرسال الطلب مع زيادة مهلة الانتظار
      try {
        final streamedResponse = await request.send()
            .timeout(const Duration(seconds: 30)); // زيادة المهلة إلى 30 ثانية
          
        final response = await http.Response.fromStream(streamedResponse)
            .timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'postId': data['postId'] ?? '',
            'message': 'Post created successfully'
          };
        } else {
          print("Failed to create post: ${response.statusCode}");
          return {
            'success': false,
            'error': 'Failed to create post. Server returned ${response.statusCode}'
          };
        }
      } on TimeoutException {
        return {
          'success': false,
          'error': 'Connection timed out. Please try again later.'
        };
      }
    } catch (e) {
      print("Error creating post: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Like a post
  Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      if (!await isServerAvailable()) {
        return {
          'success': false,
          'error': 'Server not available. Cannot like posts while offline.'
        };
      }
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/posts/${postId}/like'),
        headers: await ApiService.getHeaders(),
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        // حفظ معرف المنشور محليًا لتحديث الواجهة فقط
        await _saveUserAction('liked_posts', postId);
        
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Failed to like post. Server returned ${response.statusCode}'
        };
      }
    } catch (e) {
      print("Error liking post: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Check if user has liked a post (using local cache for UI purposes only)
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      final userLikedPosts = await _getUserActions('liked_posts');
      return userLikedPosts.contains(postId);
    } catch (e) {
      print("Error checking if user liked post: $e");
      return false;
    }
  }
  
  // Bookmark a post
  Future<Map<String, dynamic>> bookmarkPost(String postId, bool bookmark) async {
    try {
      if (!await isServerAvailable()) {
        return {
          'success': false,
          'error': 'Server not available. Cannot bookmark posts while offline.'
        };
      }
      
      final method = bookmark ? 'POST' : 'DELETE';
      final url = Uri.parse('${ApiService.baseUrl}/posts/${postId}/bookmark');
      
      final response = await http.post(
        url,
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'bookmark': bookmark}),
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        // تحديث قائمة المفضلات محليًا لتحديث الواجهة فقط
        if (bookmark) {
          await _saveUserAction('bookmarked_posts', postId);
        } else {
          await _removeUserAction('bookmarked_posts', postId);
        }
        
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Failed to ${bookmark ? 'bookmark' : 'unbookmark'} post. Server returned ${response.statusCode}'
        };
      }
    } catch (e) {
      print("Error bookmarking post: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Get bookmarked post IDs
  Future<List<String>> getBookmarkedPostIds() async {
    return await _getUserActions('bookmarked_posts');
  }
  
  // Get bookmarked posts
  Future<List<CommunityPost>> getBookmarkedPosts() async {
    try {
      if (!await isServerAvailable()) {
        print("CommunityDbService: Server not available, returning empty bookmarked posts.");
        return [];
      }
      
      final userId = await ApiService.getUserId();
      if (userId == null) {
        print("CommunityDbService: No user ID found, cannot fetch bookmarked posts.");
        return [];
      }
      
      final headers = await ApiService.getHeaders();
      headers['User-ID'] = userId.toString();

      print('CommunityDbService: Fetching bookmarked posts for userId: $userId');
      print('CommunityDbService: Request URL: ${ApiService.baseUrl}/posts/bookmarked');
      print('CommunityDbService: Request Headers: $headers');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/posts/bookmarked'),
        headers: headers,
      ).timeout(const Duration(seconds: 8));
      
      print('CommunityDbService: Bookmarked posts response status: ${response.statusCode}');
      print('CommunityDbService: Bookmarked posts response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['posts'] != null) {
          final fetchedPosts = List<Map<String, dynamic>>.from(data['posts']);
          
          // Update local bookmarks list for UI
          final bookmarkIds = fetchedPosts.map((post) => post['id'].toString()).toList();
          await _setUserActions('bookmarked_posts', bookmarkIds);
          
          return fetchedPosts
              .map((postJson) => CommunityPost.fromJson(postJson))
              .toList();
        }
      }
      
      print("CommunityDbService: Failed to fetch bookmarked posts. Status: ${response.statusCode}");
      return [];
    } catch (e) {
      print("CommunityDbService: Error fetching bookmarked posts: $e");
      return [];
    }
  }
  
  // Edit an existing post
  Future<Map<String, dynamic>> editPost(String postId, String newContent, File? newImage, String? existingImageUrl) async {
    try {
      if (!await isServerAvailable()) {
        return {
          'success': false,
          'error': 'Server not available. Cannot edit posts while offline.'
        };
      }

      final userId = await ApiService.getUserId();
      if (userId == null) {
        return {'success': false, 'error': 'User not authenticated.'};
      }

      final headers = await ApiService.getHeaders();
      
      // Determine if an image needs to be sent or removed
      bool sendNewImage = newImage != null;
      bool keepExistingImage = !sendNewImage && existingImageUrl != null && existingImageUrl.isNotEmpty;
      bool removeImage = !sendNewImage && existingImageUrl == null; // User explicitly removed it

      if (sendNewImage || keepExistingImage) {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('${ApiService.baseUrl}/posts/$postId'),
        );
        request.headers.addAll(headers);
        request.fields['content'] = newContent;
        request.fields['userId'] = userId; 
        
        if (sendNewImage) {
          final fileSize = await newImage!.length();
          if (fileSize > 5 * 1024 * 1024) { 
            return {
              'success': false,
              'error': 'Image is too large. Please choose a smaller image (less than 5MB).'
            };
          }
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            newImage.path,
          ));
        } else if (keepExistingImage) {
          // Inform the backend to keep the existing image
          request.fields['keepExistingImage'] = 'true';
          request.fields['existingImageUrl'] = existingImageUrl!;
        }

        final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Post updated successfully'};
        } else {
          return {'success': false, 'error': 'Failed to update post: ${response.statusCode}'};
        }
      } else if (removeImage) {
        // If image is explicitly removed, send a JSON request with a flag to remove it
        final response = await http.put(
          Uri.parse('${ApiService.baseUrl}/posts/$postId'),
          headers: headers,
          body: jsonEncode({
            'content': newContent,
            'userId': userId,
            'removeImage': true, // Flag to remove the image on backend
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Post updated successfully'};
        } else {
          return {'success': false, 'error': 'Failed to update post: ${response.statusCode}'};
        }
      } else {
        // No image changes, use JSON request
        final response = await http.put(
          Uri.parse('${ApiService.baseUrl}/posts/$postId'),
          headers: headers,
          body: jsonEncode({
            'content': newContent,
            'userId': userId, 
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Post updated successfully'};
        } else {
          return {'success': false, 'error': 'Failed to update post: ${response.statusCode}'};
        }
      }
    } catch (e) {
      print("Error editing post: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete an existing post
  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      if (!await isServerAvailable()) {
        return {
          'success': false,
          'error': 'Server not available. Cannot delete posts while offline.'
        };
      }

      final userId = await ApiService.getUserId();
      if (userId == null) {
        return {'success': false, 'error': 'User not authenticated.'};
      }
      
      final headers = await ApiService.getHeaders();

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/posts/$postId'),
        headers: headers,
        body: jsonEncode({'userId': userId}), // Send userId for verification on backend
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Post deleted successfully'};
      } else {
        return {'success': false, 'error': 'Failed to delete post: ${response.statusCode}'};
      }
    } catch (e) {
      print("Error deleting post: $e");
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Helper methods for user interaction caching (only for UI purposes)
  
  // Save a user action (like, bookmark)
  Future<void> _saveUserAction(String actionType, String postId) async {
    try {
      final actions = await _getUserActions(actionType);
      if (!actions.contains(postId)) {
        actions.add(postId);
        await _setUserActions(actionType, actions);
      }
    } catch (e) {
      print("Error saving user action: $e");
    }
  }
  
  // Remove a user action
  Future<void> _removeUserAction(String actionType, String postId) async {
    try {
      final actions = await _getUserActions(actionType);
      actions.remove(postId);
      await _setUserActions(actionType, actions);
    } catch (e) {
      print("Error removing user action: $e");
    }
  }
  
  // Get user actions of a specific type
  Future<List<String>> _getUserActions(String actionType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsJson = prefs.getString('${_USER_ACTIONS_KEY}_$actionType');
      
      if (actionsJson == null || actionsJson.isEmpty) {
        return [];
      }
      
      return List<String>.from(jsonDecode(actionsJson));
    } catch (e) {
      print("Error getting user actions: $e");
      return [];
    }
  }
  
  // Set user actions of a specific type
  Future<void> _setUserActions(String actionType, List<String> actions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_USER_ACTIONS_KEY}_$actionType', jsonEncode(actions));
    } catch (e) {
      print("Error setting user actions: $e");
    }
  }
} 