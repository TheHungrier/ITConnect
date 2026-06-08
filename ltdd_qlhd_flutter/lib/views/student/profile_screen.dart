import 'package:flutter/material.dart';

import '../../controllers/profile_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();

  bool _notificationEnabled = true;
  bool _isUpdatingNotification = false;

  bool _isDarkMode = false;
  bool _isUpdatingTheme = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = _controller.isDarkMode();
  }

  String _readUserField(
    dynamic user,
    String primaryField, {
    String? fallbackField,
    String defaultValue = 'Chưa cập nhật',
  }) {
    final primaryValue = _controller.safeString(user, primaryField);

    if (primaryValue.isNotEmpty) {
      return primaryValue;
    }

    if (fallbackField != null) {
      final fallbackValue = _controller.safeString(user, fallbackField);

      if (fallbackValue.isNotEmpty) {
        return fallbackValue;
      }
    }

    return defaultValue;
  }

  Future<void> _sendResetPasswordEmail(String email) async {
    if (email.isEmpty || email == 'Chưa cập nhật') {
      _showSnackBar('Email chưa được cập nhật', isError: true);
      return;
    }

    final result = await _controller.sendResetPasswordEmail(email);

    if (!mounted) return;

    _showSnackBar(result.message, isError: !result.success);
  }

  Future<void> _updateNotificationEnabled(bool value) async {
    if (_isUpdatingNotification) return;

    setState(() {
      _notificationEnabled = value;
      _isUpdatingNotification = true;
    });

    final result = await _controller.updateNotificationEnabled(value);

    if (!mounted) return;

    setState(() {
      _isUpdatingNotification = false;
    });

    _showSnackBar(result.message, isError: !result.success);

    if (!result.success) {
      setState(() {
        _notificationEnabled = !value;
      });
    }
  }

  Future<void> _updateDarkMode(bool value) async {
    if (_isUpdatingTheme) return;

    setState(() {
      _isDarkMode = value;
      _isUpdatingTheme = true;
    });

    final result = await _controller.updateDarkMode(value);

    if (!mounted) return;

    setState(() {
      _isUpdatingTheme = false;
    });

    _showSnackBar(result.message, isError: !result.success);

    if (!result.success) {
      setState(() {
        _isDarkMode = !value;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Đăng xuất',
            style: TextStyle(
              color: AppColors.title(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ITConnect không?',
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _controller.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : const Color(0xFF1565C0),
      ),
    );
  }

  void _showInfoSheet({
    required String title,
    required IconData icon,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider(context),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: AppColors.blueGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.title(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subtitle(context),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
      body: FutureBuilder(
        future: _controller.getCurrentUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary(context),
              ),
            );
          }

          final user = snapshot.data;

          final name = _readUserField(user, 'name', defaultValue: 'Sinh viên');

          final emailFromUser = _controller.safeString(user, 'email');
          final email = emailFromUser.isNotEmpty
              ? emailFromUser
              : _controller.currentEmail.isNotEmpty
              ? _controller.currentEmail
              : 'Chưa cập nhật';

          final phone = _readUserField(user, 'phone');

          final studentCode = _readUserField(
            user,
            'studentId',
            fallbackField: 'studentCode',
          );

          final className = _readUserField(
            user,
            'className',
            fallbackField: 'class',
          );

          final faculty = _readUserField(
            user,
            'faculty',
            defaultValue: 'Chưa cập nhật',
          );

          final avatarUrl = _readUserField(
            user,
            'avatar',
            fallbackField: 'avatarUrl',
            defaultValue: '',
          );

          _notificationEnabled = _controller.notificationEnabled(user);
          _isDarkMode = _controller.isDarkMode();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(
                  name: name,
                  studentCode: studentCode,
                  faculty: faculty,
                  avatarUrl: avatarUrl,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: _sectionTitle('Thông tin cá nhân'),
                ),
              ),
              SliverToBoxAdapter(
                child: _infoCard(
                  email: email,
                  phone: phone,
                  studentCode: studentCode,
                  className: className,
                  faculty: faculty,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: _sectionTitle('Tài khoản'),
                ),
              ),
              SliverToBoxAdapter(
                child: _menuSection(
                  children: [
                    _switchMenuItem(
                      icon: Icons.dark_mode_rounded,
                      title: 'Giao diện',
                      subtitle: _isDarkMode
                          ? 'Đang dùng chế độ tối'
                          : 'Đang dùng chế độ sáng',
                      value: _isDarkMode,
                      onChanged: _isUpdatingTheme ? null : _updateDarkMode,
                    ),
                    _menuItem(
                      icon: Icons.lock_reset_rounded,
                      title: 'Đổi mật khẩu',
                      subtitle: 'Nhận email đặt lại mật khẩu',
                      onTap: () {
                        _sendResetPasswordEmail(email);
                      },
                    ),
                    _switchMenuItem(
                      icon: Icons.notifications_active_rounded,
                      title: 'Thông báo',
                      subtitle: _notificationEnabled
                          ? 'Đang bật nhận thông báo'
                          : 'Đang tắt nhận thông báo',
                      value: _notificationEnabled,
                      onChanged: _isUpdatingNotification
                          ? null
                          : _updateNotificationEnabled,
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: _sectionTitle('Hỗ trợ'),
                ),
              ),
              SliverToBoxAdapter(
                child: _menuSection(
                  children: [
                    _menuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Trợ giúp',
                      subtitle: 'Hướng dẫn sử dụng ITConnect',
                      onTap: () {
                        _showInfoSheet(
                          title: 'Trợ giúp',
                          icon: Icons.help_outline_rounded,
                          content:
                              'Bạn có thể dùng ITConnect để xem hoạt động, đăng ký tham gia, điểm danh bằng QR và theo dõi thông báo từ nhà trường hoặc khoa.',
                        );
                      },
                    ),
                    _menuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Chính sách',
                      subtitle: 'Thông tin bảo mật và quyền riêng tư',
                      onTap: () {
                        _showInfoSheet(
                          title: 'Chính sách',
                          icon: Icons.privacy_tip_outlined,
                          content:
                              'Thông tin cá nhân của sinh viên chỉ được sử dụng cho mục đích quản lý hoạt động, điểm danh và thông báo trong hệ thống ITConnect.',
                        );
                      },
                    ),
                    _menuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Về ITConnect',
                      subtitle: 'Ứng dụng quản lý hoạt động sinh viên',
                      onTap: () {
                        _showInfoSheet(
                          title: 'Về ITConnect',
                          icon: Icons.info_outline_rounded,
                          content:
                              'ITConnect hỗ trợ sinh viên theo dõi tin tức, hoạt động, lịch tham gia, điểm danh QR và nhận thông báo realtime.',
                        );
                      },
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required String name,
    required String studentCode,
    required String faculty,
    required String avatarUrl,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00A8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.4,
              ),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white.withOpacity(0.18),
              foregroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              onForegroundImageError: avatarUrl.isNotEmpty
                  ? (_, __) {
                      debugPrint('Không tải được avatar: $avatarUrl');
                    }
                  : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      _controller.getInitial(name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MSSV: $studentCode',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  faculty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.title(context),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _infoCard({
    required String email,
    required String phone,
    required String studentCode,
    required String className,
    required String faculty,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.badge_outlined,
            title: 'Mã số sinh viên',
            value: studentCode,
          ),
          _divider(),
          _infoRow(icon: Icons.email_outlined, title: 'Email', value: email),
          _divider(),
          _infoRow(
            icon: Icons.phone_outlined,
            title: 'Số điện thoại',
            value: phone,
          ),
          _divider(),
          _infoRow(icon: Icons.groups_rounded, title: 'Lớp', value: className),
          _divider(),
          _infoRow(icon: Icons.school_outlined, title: 'Khoa', value: faculty),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.iconBox(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary(context), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.subtitle(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.title(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuSection({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _gradientIconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: _menuText(title: title, subtitle: subtitle),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: AppColors.muted(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _gradientIconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: _menuText(title: title, subtitle: subtitle),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary(context),
          ),
        ],
      ),
    );
  }

  Widget _gradientIconBox(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: AppColors.blueGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _menuText({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.title(context),
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.subtitle(context),
            fontSize: 12.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppColors.divider(context)),
    );
  }
}
