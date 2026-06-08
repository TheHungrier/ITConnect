import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/views/auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;

  int _realPage = 1000;
  Timer? _timer;

  final List<String> _slides = const [
    'assets/images/slide_1.png',
    'assets/images/slide_2.png',
    'assets/images/slide_3.png',
  ];

  static const Color _primaryColor = Color(0xFF1565C0);
  static const Color _titleColor = Color(0xFF0D2240);
  static const Color _subTextColor = Color(0xFF6B82A0);

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _realPage);

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients) return;

      _realPage++;

      _pageController.animateToPage(
        _realPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showAboutDialog() {
    _showInfoDialog(
      title: 'Giới thiệu ITConnect',
      icon: Icons.info_outline_rounded,
      content:
          'ITConnect là ứng dụng hỗ trợ sinh viên theo dõi, đăng ký hoạt động, điểm danh QR và quản lý điểm rèn luyện trong quá trình học tập.',
    );
  }

  void _showHelpDialog() {
    _showInfoDialog(
      title: 'Trợ giúp',
      icon: Icons.help_outline_rounded,
      content:
          'Nếu quên thông tin đăng nhập hoặc gặp lỗi khi sử dụng ứng dụng, sinh viên vui lòng liên hệ quản trị viên hoặc khoa để được hỗ trợ.',
    );
  }

  void _showPolicyDialog() {
    _showInfoDialog(
      title: 'Chính sách',
      icon: Icons.privacy_tip_outlined,
      content:
          'Ứng dụng chỉ sử dụng thông tin sinh viên để phục vụ đăng ký hoạt động, điểm danh, thông báo và quản lý điểm rèn luyện trong hệ thống ITConnect.',
    );
  }

  void _showInfoDialog({
    required String title,
    required IconData icon,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _primaryColor, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(
              color: _subTextColor,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Đóng',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      color: Colors.white,
      elevation: 10,
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Icon(
        Icons.more_vert_rounded,
        color: Colors.white.withOpacity(0.88),
        size: 36,
      ),
      onSelected: (value) {
        if (value == 'about') {
          _showAboutDialog();
        } else if (value == 'help') {
          _showHelpDialog();
        } else if (value == 'policy') {
          _showPolicyDialog();
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 'about',
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _primaryColor,
                  size: 21,
                ),
                SizedBox(width: 10),
                Text(
                  'Giới thiệu',
                  style: TextStyle(
                    color: _titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'help',
            child: Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: _primaryColor,
                  size: 21,
                ),
                SizedBox(width: 10),
                Text(
                  'Trợ giúp',
                  style: TextStyle(
                    color: _titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'policy',
            child: Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: _primaryColor,
                  size: 21,
                ),
                SizedBox(width: 10),
                Text(
                  'Chính sách',
                  style: TextStyle(
                    color: _titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final slideIndex = index % _slides.length;

              return Image.asset(
                _slides[slideIndex],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              );
            },
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.04),
                      Colors.black.withOpacity(0.32),
                      Colors.black.withOpacity(0.62),
                    ],
                    stops: const [0.0, 0.50, 0.76, 1.0],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: _buildMoreMenu(),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0072FF).withOpacity(0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _goToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 12),
                        Text(
                          'ĐĂNG NHẬP',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
