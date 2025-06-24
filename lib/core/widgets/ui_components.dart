import 'package:flutter/material.dart';
import 'dart:ui';

// Import the theme service to use color constants
import 'package:kemetpass/core/theme/theme_service.dart';

// Collection of reusable UI components for the app
class KemetUI {
  // Prevent instantiation
  KemetUI._();
  
  // ===== Cards =====
  
  // Elevated card with Egyptian-inspired design
  static Widget egyptianCard({
    required Widget child,
    double elevation = 4.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    Color? backgroundColor,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    bool addHieroglyphicBorder = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
        border: addHieroglyphicBorder
            ? Border.all(
                color: KemetColors.primary.withOpacity(0.5),
                width: 2.0,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: addHieroglyphicBorder
            ? Stack(
                children: [
                  Padding(padding: padding, child: child),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            KemetColors.primary,
                            KemetColors.secondary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(padding: padding, child: child),
      ),
    );
  }
  
  // Feature card for homepage
  static Widget featureCard({
    required String title,
    required String description,
    required String imagePath,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: egyptianCard(
        addHieroglyphicBorder: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: KemetColors.primary),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: KemetColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: KemetColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: KemetColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  // ===== Headers =====
  
  // Curved header with background image or gradient
  static Widget curvedHeader({
    required String title,
    String? subtitle,
    double height = 200.0,
    ImageProvider? backgroundImage,
    Gradient? gradient,
    Color? backgroundColor,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
    Widget? leadingIcon,
    BuildContext? context,
  }) {
    assert(backgroundImage != null || gradient != null || backgroundColor != null,
        'Either backgroundImage, gradient, or backgroundColor must be provided');
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImage != null
            ? DecorationImage(
                image: backgroundImage,
                fit: BoxFit.cover,
              )
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Optional dark overlay to ensure text visibility
          if (backgroundImage != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with optional back button and actions
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showBackButton && context != null)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: leadingIcon ?? Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                          ),
                        )
                      else if (leadingIcon != null)
                        leadingIcon,
                      if (actions != null) ...actions,
                    ],
                  ),
                  Spacer(),
                  // Title and subtitle
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: Offset(0, 2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Egyptian-styled section header
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    VoidCallback? onSeeAllPressed,
    Color textColor = Colors.black87,
    bool addDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (onSeeAllPressed != null)
                TextButton(
                  onPressed: onSeeAllPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: KemetColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (addDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KemetColors.primary,
                    KemetColors.primary.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // ===== Buttons =====
  
  // Egyptian-themed primary button
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
    double width = double.infinity,
    double height = 50,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(25)),
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: KemetColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KemetColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  // Secondary outlined button
  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    double width = double.infinity,
    double height = 50,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(25)),
  }) {
    return Container(
      width: width,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: KemetColors.primary,
          side: BorderSide(color: KemetColors.primary, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon),
              SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ===== Input Fields =====
  
  // Beautiful text field with icon
  static Widget textField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    bool filled = true,
    Color? fillColor,
    int? maxLines = 1,
    int? minLines,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: filled,
        fillColor: fillColor ?? Colors.white,
        contentPadding: contentPadding,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: KemetColors.primary) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: KemetColors.primary),
                onPressed: onSuffixIconPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: KemetColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: KemetColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: KemetColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: KemetColors.error, width: 2),
        ),
      ),
    );
  }
  
  // ===== Loading Indicators =====
  
  // Egyptian-themed loading indicator
  static Widget loadingIndicator({
    double size = 60.0,
    Color color = Colors.orange,
    bool showText = true,
    String text = 'Loading...',
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inner spinner
              SizedBox(
                width: size * 0.7,
                height: size * 0.7,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 3,
                ),
              ),
              // Outer spinner with opposite direction
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.6)),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
        ],
      ],
    );
  }
  
  // ===== Dialogs =====
  
  // Stylish dialog with Egyptian theme
  static Future<T?> showStylishDialog<T>({
    required BuildContext context,
    required Widget content,
    String? title,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useRootNavigator = true,
    bool dismissWhenScrolled = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KemetColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  width: double.infinity,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: content,
              ),
              if (actions != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Bottom sheet with Egyptian styling
  static Future<T?> showStylishBottomSheet<T>({
    required BuildContext context,
    required Widget content,
    String? title,
    double maxHeight = 0.9,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeight,
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (title != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: KemetColors.textPrimary,
                    ),
                  ),
                ),
                Divider(),
              ],
              // Content - wrapped in Flexible to avoid overflow
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // ===== Profile & User UI =====
  
  // Beautiful profile picture with optional edit button
  static Widget profilePicture({
    required String? imageUrl,
    required String username,
    double radius = 50,
    double borderWidth = 3,
    Color borderColor = Colors.white,
    bool showEditButton = false,
    VoidCallback? onEditPressed,
    Color backgroundColor = Colors.orange,
    Color editButtonColor = Colors.white,
    IconData editIcon = Icons.edit,
    EdgeInsets? margin,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty && imageUrl != "null";
    final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : "?";
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: hasImage ? Colors.transparent : backgroundColor.withOpacity(0.2),
            backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    firstLetter,
                    style: TextStyle(
                      color: backgroundColor,
                      fontWeight: FontWeight.bold,
                      fontSize: radius * 0.7,
                    ),
                  ),
          ),
          if (showEditButton && onEditPressed != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: editButtonColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: onEditPressed,
                  child: Icon(
                    editIcon,
                    size: radius * 0.4,
                    color: backgroundColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // ===== Misc UI Elements =====
  
  // Egyptian-styled divider
  static Widget egyptianDivider({
    double thickness = 1.0,
    Color color = Colors.orange,
    double indent = 0.0,
    double endIndent = 0.0,
    bool useGradient = false,
  }) {
    return Container(
      height: thickness,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: indent),
      decoration: BoxDecoration(
        gradient: useGradient
            ? LinearGradient(
                colors: [
                  color.withOpacity(0.0),
                  color,
                  color.withOpacity(0.0),
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: useGradient ? null : color,
      ),
    );
  }
  
  // Blurred glass effect container
  static Widget glassContainer({
    required Widget child,
    double borderRadius = 16.0,
    double blurAmount = 10.0,
    Color tintColor = Colors.white,
    double tintOpacity = 0.2,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(0.0),
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tintColor.withOpacity(tintOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: tintColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
  
  // Badge with count for notifications etc.
  static Widget badge({
    required Widget child,
    required int count,
    Color badgeColor = Colors.red,
    Color textColor = Colors.white,
    double size = 20,
    double offset = 12,
    bool showZero = false,
  }) {
    if (count == 0 && !showZero) {
      return child;
    }
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor,
                  fontSize: count > 99 ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Rating indicator with custom star icon
  static Widget ratingIndicator({
    required double rating,
    double size = 20,
    Color activeColor = Colors.amber,
    Color inactiveColor = Colors.grey,
    int count = 5,
    bool showValue = true,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (index) {
            final isHalf = index + 0.5 == rating.floor() + 0.5;
            final isActive = index < rating.floor();
            
            return Icon(
              isHalf ? Icons.star_half : Icons.star,
              color: isActive || isHalf ? activeColor : inactiveColor,
              size: size,
            );
          }),
        ),
        if (showValue) ...[
          SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: valueStyle ?? TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ],
    );
  }
  
  // ===== Empty States =====
  
  // Empty state widget with illustration and message
  static Widget emptyState({
    required String message,
    String? subtitle,
    IconData icon = Icons.search_off,
    double iconSize = 80,
    Color iconColor = Colors.grey,
    Widget? actionButton,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionButton != null) ...[
              SizedBox(height: 32),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }
  
  // Error state widget
  static Widget errorState({
    required String message,
    String? subtitle,
    VoidCallback? onRetry,
    IconData icon = Icons.error_outline,
    double iconSize = 80,
    Color iconColor = Colors.red,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KemetColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}