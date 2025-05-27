import 'package:flutter/material.dart';

class HomeFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const HomeFeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    this.backgroundColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? Color(0xFF8B4513),
              (backgroundColor ?? Color(0xFF8B4513)).withOpacity(0.8),
              backgroundColor ?? Color(0xFF8B4513),
            ],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // 木頭紋理效果
          image: DecorationImage(
            image: NetworkImage('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZGVmcz4KICAgIDxwYXR0ZXJuIGlkPSJ3b29kIiB4PSIwIiB5PSIwIiB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIHBhdHRlcm5Vbml0cz0idXNlclNwYWNlT25Vc2UiPgogICAgICA8cmVjdCB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIGZpbGw9InRyYW5zcGFyZW50Ii8+CiAgICAgIDxsaW5lIHgxPSIwIiB5MT0iNSIgeDI9IjIwIiB5Mj0iNSIgc3Ryb2tlPSJyZ2JhKDAsIDAsIDAsIDAuMSkiIHN0cm9rZS13aWR0aD0iMSIvPgogICAgICA8bGluZSB4MT0iMCIgeTE9IjE1IiB4Mj0iMjAiIHkyPSIxNSIgc3Ryb2tlPSJyZ2JhKDAsIDAsIDAsIDAuMSkiIHN0cm9rZS13aWR0aD0iMSIvPgogICAgPC9wYXR0ZXJuPgogIDwvZGVmcz4KICA8cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0idXJsKCN3b29kKSIvPgo8L3N2Zz4K'),
            opacity: 0.2,
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
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
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
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
