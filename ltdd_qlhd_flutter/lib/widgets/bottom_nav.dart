import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../views/student/my_activities_screen.dart';
import '../views/student/home_screen.dart';
import '../views/student/check_in_screen.dart';
import '../views/student/calendar_screen.dart';
import '../views/student/profile_screen.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({Key? key, required this.currentIndex}) : super(key: key);

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;

    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const MyActivitiesScreen();
        break;
      case 2:
        screen = const CheckInScreen();
        break;
      case 3:
        screen = const CalendarScreen();
        break;
      case 4:
        screen = const ProfileScreen();
        break;
      default:
        screen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final navBackground = AppColors.card(context);
    final activeColor = AppColors.primary(context);
    final inactiveColor = AppColors.muted(context);

    return SizedBox(
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 82,
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: navBackground,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.35)
                        : const Color(0xFF1565C0).withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _navItem(
                      context,
                      index: 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Trang chủ',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                    _navItem(
                      context,
                      index: 1,
                      icon: Icons.event_note_outlined,
                      activeIcon: Icons.event_note_rounded,
                      label: 'Hoạt động',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),

                    const Expanded(child: SizedBox()),

                    _navItem(
                      context,
                      index: 3,
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      label: 'Lịch',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                    _navItem(
                      context,
                      index: 4,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Cá nhân',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => _onTap(context, 2),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qrButton(context, active: currentIndex == 2),
                  const SizedBox(height: 2),
                  Text(
                    'Điểm danh',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.2,
                      fontWeight: currentIndex == 2
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: currentIndex == 2 ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool active = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, index),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? activeIcon : icon,
                size: active ? 24 : 22,
                color: active ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.2,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qrButton(BuildContext context, {required bool active}) {
    final isDark = AppColors.isDark(context);

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: AppColors.blueGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF0D1117) : Colors.white,
          width: 5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(active ? 0.45 : 0.30),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Icon(
        Icons.qr_code_scanner_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
