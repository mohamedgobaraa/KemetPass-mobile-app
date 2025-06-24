import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.4:8000";
  
  // Get user token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }
  
  // Get user ID from SharedPreferences
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
  
  // Get appropriate headers for API requests
  static Future<Map<String, String>> getHeaders() async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final userId = await getUserId();
    if (userId != null) {
      headers['User-ID'] = userId;
    }
    
    return headers;
  }
  
  // Login method
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting to login with email: $email');
      
      // تحقق من إمكانية الوصول للخادم قبل محاولة تسجيل الدخول
      try {
        final pingResponse = await http.get(Uri.parse('$baseUrl/ping')).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Server connection timed out');
          }
        );
        
        if (pingResponse.statusCode != 200) {
          print('Server is not reachable. Status: ${pingResponse.statusCode}');
          // اذا لم نستطع الوصول للخادم، نتحقق إذا كان هذا المستخدم قد سجل دخوله من قبل
          final prefs = await SharedPreferences.getInstance();
          final storedEmail = prefs.getString('email');
          
          if (storedEmail == email) {
            print('Using cached credentials for email: $email');
            return {
              'success': true,
              'message': 'Logged in using cached credentials (offline mode)',
              'token': 'offline_token',
            };
          }
        }
      } catch (e) {
        print('Error checking server availability: $e');
        // اذا لم نستطع الوصول للخادم، نتحقق إذا كان هذا المستخدم قد سجل دخوله من قبل
        final prefs = await SharedPreferences.getInstance();
        final storedEmail = prefs.getString('email');
        
        if (storedEmail == email) {
          print('Using cached credentials for email: $email');
          return {
            'success': true,
            'message': 'Logged in using cached credentials (offline mode)',
            'token': 'offline_token',
          };
        }
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      print('Login result: $responseData');
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // استخراج بيانات المستخدم من الاستجابة، مع مراعاة الهيكل الصحيح
        var userData = responseData['user'];
        if (userData != null) {
          // حفظ بيانات المستخدم في التخزين المحلي
          final prefs = await SharedPreferences.getInstance();
          
          // استخراج معرف المستخدم (id بدلاً من userId)
          final userId = userData['id']?.toString();
          if (userId != null) {
            await prefs.setString('user_id', userId);
          }
          
          // إنشاء رمز مميز افتراضي إذا لم يكن موجوداً في الاستجابة
          final token = responseData['token'] ?? 'session_token_${DateTime.now().millisecondsSinceEpoch}';
          await prefs.setString('user_token', token);
          
          // حفظ البريد الإلكتروني والبيانات الأخرى
          await prefs.setString('email', email);
          
          // حفظ بيانات الملف الشخصي الأخرى
          if (userData['firstName'] != null) {
            await prefs.setString('firstName', userData['firstName']);
          }
          if (userData['secondName'] != null) {
            await prefs.setString('secondName', userData['secondName']);
          }
          if (userData['username'] != null) {
            await prefs.setString('username', userData['username']);
          }
          if (userData['phone'] != null) {
            await prefs.setString('phone', userData['phone']);
          }
          if (userData['country'] != null) {
            await prefs.setString('country', userData['country']);
          }
          if (userData['language'] != null) {
            await prefs.setString('language', userData['language']);
          }
          if (userData['profileImageUrl'] != null) {
            await prefs.setString('profileImageUrl', userData['profileImageUrl']);
          }
          
          // حفظ البيانات الكاملة للمستخدم كـ JSON
          await prefs.setString('user_profile', jsonEncode(userData));
          
          return {
            'success': true,
            'message': 'Login successful',
            'token': token,
            'userId': userId,
          };
        } else {
          // الاستجابة ناجحة ولكن لا توجد بيانات للمستخدم
          print('Login response missing user data');
          return {
            'success': false,
            'message': 'Invalid server response: missing user data',
          };
        }
      } else {
        // الاستجابة فاشلة
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Login failed: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Logout method
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_token');
      await prefs.remove('user_id');
      return true;
    } catch (e) {
      print('Logout error: ${e.toString()}');
      return false;
    }
  }
  
  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile({bool useLocalOnly = false}) async {
    try {
      print('=== getUserProfile Debug Info ===');
      print('useLocalOnly: $useLocalOnly');
      
      // Check if we have local profile data
      final prefs = await SharedPreferences.getInstance();
      final userProfileJson = prefs.getString('user_profile');
      final userId = await getUserId();
      final token = await getToken();
      
      print('Current User ID: $userId');
      print('Current Token: $token');
      print('Local Profile Data: ${userProfileJson != null ? 'Available' : 'Not Available'}');
      
      if (userProfileJson != null && useLocalOnly) {
        print('Using local profile data due to useLocalOnly flag');
        try {
          final localProfile = jsonDecode(userProfileJson);
          return {
            'success': true,
            'profile': localProfile,
          };
        } catch (e) {
          print('Error parsing local profile: $e');
        }
      }
      
      if (userId == null) {
        print('getUserProfile: No user ID found');
        return {
          'success': false,
          'message': 'Not logged in',
        };
      }
      
      try {
        // Check server availability
        print('Checking server availability...');
        final pingResponse = await http.get(Uri.parse('$baseUrl/ping')).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Server connection timed out');
          }
        );
        
        print('Ping response status: ${pingResponse.statusCode}');
        
        if (pingResponse.statusCode != 200) {
          print('Server is not reachable. Using local profile data.');
          return await _getLocalUserProfile();
        }
        
        print('Server is available, fetching profile for userId: $userId');
        
        // Get headers with both token and user ID
        final headers = await getHeaders();
        
        // Ensure user ID is properly formatted
        final formattedUserId = userId.toString().trim();
        headers['User-ID'] = formattedUserId;
        
        // Add authorization header if token exists
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        
        // Add session cookie if available
        final sessionCookie = prefs.getString('session_cookie');
        if (sessionCookie != null) {
          headers['Cookie'] = 'session=$sessionCookie';
        }
        
        print('Request URL: $baseUrl/get_profile');
        print('Request Headers: $headers');
        
        final response = await http.get(
          Uri.parse('$baseUrl/get_profile'),
          headers: headers,
        ).timeout(const Duration(seconds: 8));
        
        print('Response Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
        
        // Store session cookie if received
        final setCookie = response.headers['set-cookie'];
        if (setCookie != null) {
          final sessionMatch = RegExp(r'session=([^;]+)').firstMatch(setCookie);
          if (sessionMatch != null) {
            await prefs.setString('session_cookie', sessionMatch.group(1)!);
          }
        }
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('Profile API response data: $responseData');
          
          if (responseData['success']) {
            final profile = responseData['profile'];
            
            // Handle profile image URL
            if (profile['profileImageUrl'] != null && profile['profileImageUrl'].toString().isNotEmpty) {
              String fullImageUrl = getValidImageUrl(profile['profileImageUrl']);
              profile['profileImageUrl'] = fullImageUrl;
              print('Profile image URL: $fullImageUrl');
              
              // Store image URL locally
              await prefs.setString('profileImageUrl', fullImageUrl);
            } else {
              print('No profile image URL in response');
            }
            
            // Store profile data locally
            await prefs.setString('user_profile', jsonEncode(profile));
            
            return {
              'success': true,
              'profile': profile,
            };
          } else {
            print('Server responded with failure: ${responseData['error']}');
            return await _getLocalUserProfile();
          }
        } else if (response.statusCode == 404) {
          print('Profile not found (404). User might not exist or be deleted.');
          print('User ID used in request: $formattedUserId');
          
          // Try to re-login if we get a 404
          final email = prefs.getString('email');
          final password = prefs.getString('password');
          
          if (email != null && password != null) {
            print('Attempting to re-login...');
            final loginResult = await login(email, password);
            if (loginResult['success']) {
              print('Re-login successful, retrying profile fetch...');
              return getUserProfile(useLocalOnly: useLocalOnly);
            }
          }
          
          return {
            'success': false,
            'message': 'Profile not found. Please try logging in again.',
          };
        } else {
          print('Server responded with status code: ${response.statusCode}');
          return await _getLocalUserProfile();
        }
      } catch (e) {
        print('Error fetching profile from server: $e');
        print('Stack trace: ${StackTrace.current}');
        return await _getLocalUserProfile();
      }
    } catch (e) {
      print('General error in getUserProfile: $e');
      print('Stack trace: ${StackTrace.current}');
      return await _getLocalUserProfile();
    }
  }

  // Get the local user profile from SharedPreferences
  static Future<Map<String, dynamic>> _getLocalUserProfile() async {
    print('Getting local user profile');
    try {
      // محاولة استرجاع البيانات الكاملة للمستخدم من التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      
      // محاولة قراءة كل بيانات المستخدم المخزنة كـ JSON
      final userProfileJson = prefs.getString('user_profile');
      if (userProfileJson != null && userProfileJson.isNotEmpty) {
        try {
          final Map<String, dynamic> userProfile = jsonDecode(userProfileJson);
          return {
            'success': true,
            'profile': {
              'userId': userProfile['id']?.toString() ?? prefs.getString('user_id') ?? '',
              'firstName': userProfile['firstName'] ?? prefs.getString('firstName') ?? '',
              'secondName': userProfile['secondName'] ?? prefs.getString('secondName') ?? '',
              'username': userProfile['username'] ?? prefs.getString('username') ?? '',
              'email': userProfile['email'] ?? prefs.getString('email') ?? '',
              'phone': userProfile['phone'] ?? prefs.getString('phone') ?? '',
              'country': userProfile['country'] ?? prefs.getString('country') ?? '',
              'language': userProfile['language'] ?? prefs.getString('language') ?? '',
              'profileImageUrl': _formatProfileImageUrl(userProfile['profile_picture'] ?? prefs.getString('profileImageUrl') ?? ''),
            }
          };
        } catch (e) {
          print('Error parsing user profile JSON: $e');
          // إذا فشل التحليل، نستخدم البيانات الفردية
        }
      }
      
      // استرجاع البيانات الفردية المخزنة
      final userId = prefs.getString('user_id') ?? '';
      final firstName = prefs.getString('firstName') ?? '';
      final secondName = prefs.getString('secondName') ?? '';
      final username = prefs.getString('username') ?? '';
      final email = prefs.getString('email') ?? '';
      final phone = prefs.getString('phone') ?? '';
      final country = prefs.getString('country') ?? '';
      final language = prefs.getString('language') ?? '';
      final profileImageUrl = prefs.getString('profileImageUrl') ?? '';
      
      // بناء كائن الملف الشخصي من البيانات المخزنة
      Map<String, dynamic> profile = {
        'userId': userId,
        'firstName': firstName,
        'secondName': secondName,
        'username': username,
        'email': email,
        'phone': phone, 
        'country': country,
        'language': language,
        'profileImageUrl': _formatProfileImageUrl(profileImageUrl),
      };
      
      // إذا كان البريد الإلكتروني موجوداً، نحفظ الملف الشخصي كـ JSON للاستخدام المستقبلي
      if (email.isNotEmpty) {
        await prefs.setString('user_profile', jsonEncode({
          'id': userId,
          'firstName': firstName,
          'secondName': secondName,
          'username': username,
          'email': email,
          'phone': phone,
          'country': country,
          'language': language,
          'profile_picture': profileImageUrl,
        }));
      }
      
      return {
        'success': true,
        'profile': profile,
      };
    } catch (e) {
      print('Error getting local user profile: $e');
      return {
        'success': false,
        'error': e.toString(),
        'profile': {
          'userId': '',
          'firstName': '',
          'secondName': '',
          'username': 'User',
          'email': '',
          'phone': '',
          'country': '',
          'language': 'English',
          'profileImageUrl': '',
        }
      };
    }
  }
  
  // Get image URL from server or ensure asset path is correct
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'assets/images/default_profile.png';
    }
    
    // Check if it's already a full URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // Check if it's an asset path
    if (imagePath.startsWith('assets/')) {
      return imagePath;
    }
    
    // Otherwise assume it's a server path and construct full URL
    return '$baseUrl/images/$imagePath';
  }
  
  // إضافة دالة مساعدة للتحقق من URL الصورة
  static String getValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == "null") {
      return '';
    }
    
    // تنظيف المسار من أي أحرف غير مرغوب فيها
    String cleanedUrl = imageUrl.trim();
    
    // إذا كان المسار يبدأ بـ http فهو صالح بالفعل
    if (cleanedUrl.startsWith('http')) {
      return cleanedUrl;
    }
    
    // If it starts with 'uploads/', construct the URL with baseUrl
    if (cleanedUrl.startsWith('uploads/')) {
      return '$baseUrl/$cleanedUrl';
    }
    
    // إذا كان المسار يبدأ بـ / نحذفه
    if (cleanedUrl.startsWith('/')) {
      cleanedUrl = cleanedUrl.substring(1);
    }
    
    // وإلا، نضيف baseUrl - هذا احتياطي فقط إذا عاد الخادم مسارًا نسبيًا
    String fullUrl = baseUrl;
    if (!fullUrl.endsWith('/') && !cleanedUrl.startsWith('/')) {
      fullUrl += '/';
    }
    fullUrl += cleanedUrl;
    
    return fullUrl;
  }
  
  // Helper method to format profile image URL
  static String _formatProfileImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == "null") {
      return '';
    }
    
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    if (imageUrl.startsWith('assets/')) {
      return imageUrl;
    }
    
    // If it starts with 'uploads/', construct the URL with baseUrl
    if (imageUrl.startsWith('uploads/')) {
      return '$baseUrl/$imageUrl';
    }
    
    // تنظيف المسار من أي أحرف غير مرغوب فيها
    String cleanedUrl = imageUrl.trim();
    
    // إذا كان المسار يبدأ بـ / نحذفه
    if (cleanedUrl.startsWith('/')) {
      cleanedUrl = cleanedUrl.substring(1);
    }
    
    // بناء العنوان الكامل للصورة
    String fullUrl = baseUrl;
    if (!fullUrl.endsWith('/') && !cleanedUrl.startsWith('/')) {
      fullUrl += '/';
    }
    fullUrl += cleanedUrl;
    
    return fullUrl;
  }
  
  // Authentication Methods
  static Future<Map<String, dynamic>> register(String email, String password, String username, {String? firstName, String? secondName}) async {
    // Store user data in shared preferences to retrieve later if needed
    final prefs = await SharedPreferences.getInstance();
    
    // If firstName and secondName aren't provided, extract them from the form fields directly
    final actualFirstName = firstName ?? '';
    final actualSecondName = secondName ?? '';
    
    await prefs.setString('email', email);
    await prefs.setString('username', username);
    await prefs.setString('firstName', actualFirstName);
    await prefs.setString('secondName', actualSecondName);
    
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
        'firstName': actualFirstName,
        'secondName': actualSecondName,
      }),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success'] == true) {
      await prefs.setString('user_id', data['user_id'].toString());
      return {'success': true, 'user_id': data['user_id']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Unknown error'};
    }
  }
  
  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String secondName,
    required String username,
    required String email,
    required String phone,
    required String country,
    required String language,
    String? profileImageUrl,
    File? profileImageFile,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not logged in'
        };
      }

      final headers = await getHeaders();
      headers['User-ID'] = userId.toString();

      // إذا كان هناك ملف صورة، نستخدم MultipartRequest
      if (profileImageFile != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/update_profile'),
        );
        
        // إضافة الرؤوس
        request.headers.addAll({
          'User-ID': userId.toString(),
          // لا نضيف Content-Type هنا لأن MultipartRequest سيضبطه تلقائيًا
        });
        
        // إضافة البيانات النصية
        request.fields['userId'] = userId.toString();
        request.fields['firstName'] = firstName;
        request.fields['secondName'] = secondName;
        request.fields['username'] = username;
        request.fields['email'] = email;
        request.fields['phone'] = phone;
        request.fields['country'] = country;
        request.fields['language'] = language;
        
        // إضافة ملف الصورة
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          profileImageFile.path,
        ));
        
        // إرسال الطلب
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          // تخزين المعلومات المحدثة في SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', firstName);
          await prefs.setString('secondName', secondName);
          await prefs.setString('username', username);
          await prefs.setString('email', email);
          await prefs.setString('phone', phone);
          await prefs.setString('country', country);
          await prefs.setString('language', language);
          
          // تحديث مسار الصورة محليًا إذا كان موجودًا في الاستجابة
          try {
            final data = jsonDecode(response.body);
            if (data['profileImageUrl'] != null) {
              final fullImageUrl = getValidImageUrl(data['profileImageUrl']);
              await prefs.setString('profileImageUrl', fullImageUrl);
            }
          } catch (e) {
            print("Error parsing profile image URL: $e");
          }
          
          return {'success': true};
        } else {
          return {
            'success': false,
            'error': 'Failed to update profile: ${response.statusCode}'
          };
        }
      } else {
        // استخدام الطريقة القديمة إذا لم تكن هناك صورة للتحميل
        final response = await http.post(
          Uri.parse('$baseUrl/update_profile'),
          headers: headers,
          body: jsonEncode({
            'userId': userId,
            'firstName': firstName,
            'secondName': secondName,
            'username': username,
            'email': email,
            'phone': phone,
            'country': country,
            'language': language,
            'profileImageUrl': profileImageUrl,
          }),
        );

        if (response.statusCode == 200) {
          // تخزين المعلومات المحدثة في SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', firstName);
          await prefs.setString('secondName', secondName);
          await prefs.setString('username', username);
          await prefs.setString('email', email);
          await prefs.setString('phone', phone);
          await prefs.setString('country', country);
          await prefs.setString('language', language);
          
          if (profileImageUrl != null) {
            await prefs.setString('profileImageUrl', profileImageUrl);
          }

          return {'success': true};
        } else {
          return {
            'success': false,
            'error': 'Failed to update profile: ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      print("Update profile error: ${e.toString()}");
      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}'
      };
    }
  }
  
  // دالة جديدة لتحميل صورة الملف الشخصي
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not logged in'
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_profile_image'),
      );
      
      request.headers['User-ID'] = userId.toString();
      request.fields['userId'] = userId.toString();
      
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['profileImageUrl'] != null) {
          final fullImageUrl = getValidImageUrl(data['profileImageUrl']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profileImageUrl', fullImageUrl);
          return {'success': true, 'profileImageUrl': fullImageUrl};
        }
        return {'success': true, 'profileImageUrl': data['profileImageUrl']};
      } else {
        return {
          'success': false,
          'error': 'Failed to upload profile image: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}'
      };
    }
  }
  
  // Feature Methods
  static Future<Map<String, dynamic>> chatWithBot(String question, String context) async {
    final userId = await getUserId();
    
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'context': context,
      }),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return {'success': true, 'response': data['response']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Unknown error'};
    }
  }
  
  static Future<Map<String, dynamic>> predictWhereIAm(File imageFile) async {
    final userId = await getUserId();
    
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict_where_im'));
    
    request.files.add(await http.MultipartFile.fromPath(
      'file', 
      imageFile.path,
    ));
    
    final headers = await getHeaders();
    request.headers.addAll(headers);
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return {'success': true, 'place': data['place']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Unknown error'};
    }
  }
  
  static Future<Map<String, dynamic>> translateHieroglyphics(List<File> imageFiles) async {
    final userId = await getUserId();
    
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/translate_hieroglyphic'));
    
    for (var file in imageFiles) {
      request.files.add(await http.MultipartFile.fromPath(
        'files', 
        file.path,
      ));
    }
    
    final headers = await getHeaders();
    request.headers.addAll(headers);
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return {
        'success': true, 
        'translation': data['translation'],
        'classes': data['classes'],
      };
    } else {
      return {'success': false, 'error': data['error'] ?? 'Unknown error'};
    }
  }
  
  // Saved Items Methods
  static Future<Map<String, dynamic>> getSavedItems([String? type]) async {
    final userId = await getUserId();
    if (userId == null) {
      return {'success': false, 'error': 'Not logged in'};
    }
    
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl/get_saves${type != null ? '?type=$type' : ''}');
    
    final response = await http.get(uri, headers: headers);
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success'] == true) {
      return {'success': true, 'saves': data['saves']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Unknown error'};
    }
  }
  
  static Future<bool> deleteSavedItem(int saveId) async {
    final userId = await getUserId();
    if (userId == null) {
      return false;
    }
    
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_save/$saveId'),
      headers: headers,
    );
    
    return response.statusCode == 200;
  }
  
  // Chat History Methods
  static Future<Map<String, dynamic>> getChatHistory([int limit = 50]) async {
    final userId = await getUserId();
    if (userId == null) {
      return {'success': false, 'error': 'Not logged in'};
    }
    
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat_history?limit=$limit'),
      headers: headers,
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success'] == true) {
      return {'success': true, 'history': data['history']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Unknown error'};
    }
  }
  
  // Community Methods
  
  // Upload a post to the server
  static Future<Map<String, dynamic>> uploadPost(Map<String, dynamic> postData, {String? imagePath}) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {'success': false, 'error': 'Not logged in'};
      }
      
      final headers = await getHeaders();
      
      // If there's an image, use MultipartRequest
      if (imagePath != null && imagePath.isNotEmpty && !imagePath.startsWith('http') && !imagePath.startsWith('assets/')) {
        final request = http.MultipartRequest(
          'POST', 
          Uri.parse('$baseUrl/posts')
        );
        
        // Add headers
        request.headers.addAll(headers);
        
        // Add post data
        request.fields['postId'] = postData['id'].toString();
        request.fields['userId'] = userId;
        request.fields['content'] = postData['content'];
        request.fields['username'] = postData['username'];
        request.fields['createdAt'] = postData['createdAt'];
        
        // Add image file
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ));
        }
        
        // Send request
        final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'data': jsonDecode(response.body)};
        } else {
          return {'success': false, 'error': 'Failed to upload post: ${response.statusCode}'};
        }
      } else {
        // No image, use regular POST request
        final response = await http.post(
          Uri.parse('$baseUrl/posts'),
          headers: headers,
          body: jsonEncode(postData),
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'data': jsonDecode(response.body)};
        } else {
          return {'success': false, 'error': 'Failed to upload post: ${response.statusCode}'};
        }
      }
    } catch (e) {
      print("Error uploading post: $e");
      return {'success': false, 'error': 'Error uploading post: ${e.toString()}'};
    }
  }
  
  // Sync local posts to server
  static Future<Map<String, dynamic>> synchronizeOfflinePosts(List<Map<String, dynamic>> localPosts) async {
    if (localPosts.isEmpty) {
      return {'success': true, 'message': 'No posts to synchronize', 'syncedPosts': []};
    }
    
    print("Starting synchronization of ${localPosts.length} offline posts...");
    
    List<String> syncedPostIds = [];
    List<Map<String, dynamic>> failedPosts = [];
    
    try {
      // Check server availability
      final pingResponse = await http.get(
        Uri.parse('$baseUrl/ping'),
      ).timeout(const Duration(seconds: 3));
      
      if (pingResponse.statusCode != 200) {
        return {
          'success': false, 
          'message': 'Server not available', 
          'syncedPosts': syncedPostIds,
          'failedPosts': localPosts
        };
      }
      
      // Try to upload each post
      for (var post in localPosts) {
        String? imagePath;
        
        // Get the first image if available
        if (post['images'] != null && post['images'].isNotEmpty) {
          imagePath = post['images'][0];
        }
        
        // Try to upload post
        final result = await uploadPost(post, imagePath: imagePath);
        
        if (result['success']) {
          syncedPostIds.add(post['id']);
          print("Successfully synced post: ${post['id']}");
        } else {
          failedPosts.add(post);
          print("Failed to sync post: ${post['id']} - ${result['error']}");
        }
      }
      
      return {
        'success': true,
        'message': 'Synchronized ${syncedPostIds.length} posts, failed ${failedPosts.length} posts',
        'syncedPosts': syncedPostIds,
        'failedPosts': failedPosts
      };
    } catch (e) {
      print("Error during synchronization: $e");
      return {
        'success': false,
        'message': 'Synchronization error: ${e.toString()}',
        'syncedPosts': syncedPostIds,
        'failedPosts': localPosts
      };
    }
  }

  // API-specific helper method for profile image URLs
  static String getProfileImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == "null") {
      return '';
    }
    
    // If it's already a complete URL, return it
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    // Special case for uploads (how the server seems to store profile images)
    if (imageUrl.contains('uploads/')) {
      // If it starts with a slash, remove it
      String cleaned = imageUrl;
      if (cleaned.startsWith('/')) {
        cleaned = cleaned.substring(1);
      }
      
      // Build the full URL
      return '$baseUrl/$cleaned';
    }
    
    // Default case - just prepend the base URL
    return '$baseUrl/uploads/$imageUrl';
  }
} 