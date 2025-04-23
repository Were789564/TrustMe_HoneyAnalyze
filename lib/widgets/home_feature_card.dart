import 'package:flutter/material.dart';

class HomeFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const HomeFeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        color: Colors.white.withAlpha(237),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(12),
                child: Icon(icon, color: color, size: screenWidth * 0.08),
              ),
              SizedBox(width: 22),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
