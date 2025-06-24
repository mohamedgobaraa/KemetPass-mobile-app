import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFFFEFFD2);
const Color secondaryColor = Color(0xFFFFEEA9);
const Color primaryColor = Color(0xFFFFBF78);
const Color accentColor = Color(0xFFFF7D29);
const Color inactiveIconColor = Colors.grey;

class FeatureButton extends StatelessWidget {
  final String title;
  final IconData icon;

  const FeatureButton({
    Key? key,
    required this.title,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFF7D29),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}