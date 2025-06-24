import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

const Color backgroundColor = Color(0xFFFEFFD2);
const Color secondaryColor = Color(0xFFFFEEA9);
const Color primaryColor = Color(0xFFFFBF78);
const Color accentColor = Color(0xFFFF7D29);
const Color inactiveIconColor = Colors.grey;

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Add form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Keeping original controllers
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  String? userId;
  String? profileImageUrl;
  File? _image;
  bool _isLoading = false;

  String? _selectedCountry;
  String? _selectedLanguage;
  final List<String> _countries = [
    'Egypt',
    'USA',
    'Canada',
    'France',
    'Germany',
    'Japan',
    'Brazil',
    'India',
    'Australia'
  ];
  final List<String> _languages = [
    'English',
    'Arabic',
    'French',
    'Spanish',
    'German',
    'Chinese'
  ];

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
      final id = await ApiService.getUserId();
      if (id != null) {
        userId = id;
        
        // استخدام getUserProfile للحصول على بيانات المستخدم الفعلية
        final userProfile = await ApiService.getUserProfile();
        
        if (userProfile['success']) {
          final profile = userProfile['profile'];
          setState(() {
            _firstNameController.text = profile['firstName'] ?? '';
            _secondNameController.text = profile['secondName'] ?? '';
            _usernameController.text = profile['username'] ?? '';
            _emailController.text = profile['email'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _selectedCountry = profile['country'] ?? _countries[0];
            _selectedLanguage = profile['language'] ?? _languages[0];
            profileImageUrl = profile['profileImageUrl'];
            
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading profile: ${userProfile['error']}")),
          );
        }
      } else {
        // Not logged in - handle this case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: ${e.toString()}")),
      );
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      
      // تحميل الصورة إلى الخادم
      setState(() {
        _isLoading = true;
      });
      
      try {
        final result = await ApiService.uploadProfileImage(_image!);
        
        setState(() {
          _isLoading = false;
          if (result['success'] && result['profileImageUrl'] != null) {
            profileImageUrl = result['profileImageUrl'];
          }
        });
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile picture uploaded successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload profile picture: ${result['error']}")),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading profile picture: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await ApiService.updateProfile(
          firstName: _firstNameController.text,
          secondName: _secondNameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          country: _selectedCountry ?? _countries[0],
          language: _selectedLanguage ?? _languages[0],
          profileImageUrl: profileImageUrl,
          profileImageFile: _image,  // إضافة ملف الصورة إلى الطلب
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile updated successfully")),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update profile: ${result['error']}")),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildProfileImage() {
    // إذا كان المستخدم قد اختار صورة جديدة، نعرضها أولاً
    if (_image != null) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage: FileImage(_image!),
      );
    }
    
    // إذا لم تكن هناك صورة نهائيًا
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: Icon(Icons.person, size: 50, color: primaryColor),
      );
    }
    
    // استخدام الصورة الشخصية من الخادم
    try {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(profileImageUrl!),
        onBackgroundImageError: (_, __) {
          // في حالة حدوث خطأ في تحميل الصورة، لا نعيد قيمة هنا (دالة من نوع void)
          print('خطأ في تحميل الصورة');
        },
        child: null, // سيظهر فقط إذا فشل تحميل الصورة
      );
    } catch (e) {
      // في حالة حدوث أي خطأ آخر، نعرض الأيقونة الافتراضية
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: Icon(Icons.error_outline, size: 50, color: Colors.red),
      );
    }
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Enhanced Header Section
              Container(
                padding: EdgeInsets.only(top: 50.0, bottom: 20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryColor, accentColor],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 8),
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
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 8),
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
                    SizedBox(height: 20),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _uploadImage,
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
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Change Picture',
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
              // Form Fields with Enhanced Design
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ProfileTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    ProfileTextField(
                      controller: _secondNameController,
                      label: 'Second Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    ProfileTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 16),
                    ProfileTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    ProfileTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        items: _countries.map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Country',
                          prefixIcon: Icon(Icons.public, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(style: BorderStyle.none),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        items: _languages.map((language) {
                          return DropdownMenuItem(
                            value: language,
                            child: Text(language),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Language',
                          prefixIcon: Icon(Icons.language, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(style: BorderStyle.none),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ProfileTextField(
                      controller: _passwordController,
                      label: 'New Password',
                      obscureText: true,
                      icon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),
              // Enhanced Update Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Save",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController controller;
  final bool enabled;
  final IconData? icon;

  const ProfileTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(style: BorderStyle.none),
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
      ),
    );
  }
}
