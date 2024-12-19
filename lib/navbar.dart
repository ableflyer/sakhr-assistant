import 'package:app_frontend/classes.dart';
import 'package:app_frontend/record.dart';
import 'package:app_frontend/reminders.dart';
import 'package:app_frontend/schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home.dart';
import 'package:google_fonts/google_fonts.dart';

class NavigationManager extends StatefulWidget {
  const NavigationManager({Key? key}) : super(key: key);

  @override
  State<NavigationManager> createState() => _NavigationManagerState();
}

class _NavigationManagerState extends State<NavigationManager> {
  int _selectedIndex = 0;

  // List of screens to be managed by navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const ClassesScreen(), // Classes screen
    const RecordScreen(), // Record screen
    const RemindersScreen(), // Reminders screen
    ScheduleScreen(), // Schedule screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF00FF00),
            width: 1,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: const Color(0xFF00FF00),
          unselectedItemColor: Colors.white,
          selectedLabelStyle: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
          ),
          items: [
            _buildNavItem(Icons.home_outlined, 'Home', 0),
            _buildNavItem(Icons.school_outlined, 'Classes', 1),
            _buildNavItem(Icons.radio_button_checked, 'Record', 2),
            _buildNavItem(Icons.notifications_outlined, 'Reminders', 3),
            _buildNavItem(Icons.calendar_today_outlined, 'Schedule', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _selectedIndex == index
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FF00).withOpacity(0.5),
                    blurRadius: 20.r,
                    spreadRadius: 2.r,
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 24.sp,
        ),
      ),
      label: label,
    );
  }
}

// Update your main.dart to use NavigationManager as the home widget
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: GoogleFonts.dmMono().fontFamily,
            scaffoldBackgroundColor: Colors.black,
          ),
          home: const NavigationManager(),
        );
      },
    );
  }
}