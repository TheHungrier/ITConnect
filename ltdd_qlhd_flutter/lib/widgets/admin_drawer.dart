import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/app_theme_controller.dart';
import '../views/auth/login_screen.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;

  final VoidCallback? onTapDashboard;
  final VoidCallback? onTapManageActivities;
  final VoidCallback? onTapManageNews;
  final VoidCallback? onTapAttendance;
  final VoidCallback? onTapFeedbacks;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    this.onTapDashboard,
    this.onTapManageActivities,
    this.onTapManageNews,
    this.onTapAttendance,
    this.onTapFeedbacks,
  });

  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _cardColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF1E293B) : Colors.white;
  }

  Color _textColor(BuildContext context) {
    return _isDark(context) ? Colors.white : const Color(0xFF0F172A);
  }

  Color _subTextColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
  }

  Color _dividerColor(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE2E8F0);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchAdminProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  String _shortName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'Admin';
    if (parts.length == 1) return parts.first;

    return '${parts[parts.length - 2]} ${parts.last}';
  }

  String _adminNameFromData(Map<String, dynamic>? data) {
    final name = data?['name']?.toString().trim() ?? '';

    if (name.isEmpty) return 'Admin';

    return _shortName(name);
  }

  String _adminAvatarFromData(Map<String, dynamic>? data) {
    final avatar = data?['avatar']?.toString().trim() ?? '';
    final avatarUrl = data?['avatarUrl']?.toString().trim() ?? '';

    if (avatar.isNotEmpty) return avatar;

    return avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _cardColor(context),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _watchAdminProfile(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final adminName = _adminNameFromData(data);
          final avatarUrl = _adminAvatarFromData(data);

          return Column(
            children: [
              _buildHeader(context, adminName, avatarUrl),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _drawerItem(
                      context: context,
                      index: 0,
                      icon: Icons.dashboard_rounded,
                      title: 'Tổng quan',
                      onTap: onTapDashboard,
                    ),
                    _drawerItem(
                      context: context,
                      index: 1,
                      icon: Icons.event_note_rounded,
                      title: 'Quản lý hoạt động',
                      onTap: onTapManageActivities,
                    ),
                    _drawerItem(
                      context: context,
                      index: 2,
                      icon: Icons.article_rounded,
                      title: 'Quản lý tin tức',
                      onTap: onTapManageNews,
                    ),
                    _drawerItem(
                      context: context,
                      index: 3,
                      icon: Icons.fact_check_rounded,
                      title: 'Quản lý điểm danh',
                      onTap: onTapAttendance,
                    ),
                    _drawerItem(
                      context: context,
                      index: 4,
                      icon: Icons.feedback_rounded,
                      title: 'Góp ý sinh viên',
                      onTap: onTapFeedbacks,
                    ),
                    const SizedBox(height: 10),
                    Divider(color: _dividerColor(context)),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                      child: Text(
                        'Cài đặt',
                        style: TextStyle(
                          color: _subTextColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _themeSwitch(context),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: _logoutItem(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String adminName,
    String avatarUrl,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 22,
        left: 18,
        right: 18,
        bottom: 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          _adminAvatar(avatarUrl, size: 60, whiteBg: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quản trị ITConnect',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminAvatar(
    String avatarUrl, {
    required double size,
    required bool whiteBg,
  }) {
    final hasAvatar = avatarUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: hasAvatar ? EdgeInsets.zero : const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: whiteBg ? Colors.white : Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: whiteBg ? Colors.white : Colors.white.withOpacity(0.35),
        ),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _adminIcon(whiteBg);
                },
              )
            : _adminIcon(whiteBg),
      ),
    );
  }

  Widget _adminIcon(bool whiteBg) {
    return Icon(
      Icons.person_rounded,
      color: whiteBg ? primaryBlue : Colors.white,
      size: 28,
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    final isSelected = selectedIndex == index;
    final isDark = _isDark(context);

    final Color itemColor = isSelected ? primaryBlue : _textColor(context);

    final Color bgColor = isSelected
        ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD))
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 0,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryBlue.withOpacity(0.14)
                : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: itemColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap ?? () => Navigator.pop(context),
      ),
    );
  }

  Widget _themeSwitch(BuildContext context) {
    final isDark = _isDark(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, _) {
        final isDarkMode = mode == ThemeMode.dark;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            dense: true,
            minLeadingWidth: 0,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: primaryBlue,
                size: 20,
              ),
            ),
            title: Text(
              'Giao diện tối',
              style: TextStyle(
                color: _textColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            trailing: Switch(
              value: isDarkMode,
              activeColor: primaryBlue,
              onChanged: (value) {
                AppThemeController.setDarkMode(value);
              },
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _logoutItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 0,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () async {
          Navigator.pop(context);

          await FirebaseAuth.instance.signOut();

          if (!context.mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
    );
  }
}
