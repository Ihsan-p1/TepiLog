import 'package:flutter/material.dart';
import 'package:tepilog/app/theme.dart';

class MainShell extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTabChanged;

  const MainShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTabChanged,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.primary,
          selectedItemColor: Colors.white,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 22,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_border_rounded),
              activeIcon: Icon(Icons.star_rounded),
              label: 'trending',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_upload_outlined),
              activeIcon: Icon(Icons.file_upload_rounded),
              label: 'upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'profile',
            ),
          ],
        ),
      ),
    );
  }
}
