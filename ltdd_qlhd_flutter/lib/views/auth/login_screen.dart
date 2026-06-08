import 'package:flutter/material.dart';

import '../../controllers/login_controller.dart';
import '../admin/faculty_dashboard_screen.dart';
import '../student/home_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  final LoginController _loginController = LoginController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _hasSavedLoginInfo = false;

  String _error = '';
  String _savedAvatarUrl = '';

  static const Color _primaryColor = Color(0xFF1565C0);
  static const Color _titleColor = Color(0xFF0D2240);
  static const Color _subTextColor = Color(0xFF6B82A0);
  static const Color _inputBackground = Color(0xFFF4F8FF);
  static const Color _hintColor = Color(0xFFAAB8CC);

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInfo();
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLoginInfo() async {
    final savedLoginId = await _loginController.loadSavedLoginId();
    final savedAvatarUrl = await _loginController.loadSavedAvatarUrl();

    if (!mounted) return;

    setState(() {
      if (savedLoginId.isNotEmpty) {
        _loginIdController.text = savedLoginId;
      }

      _savedAvatarUrl = savedAvatarUrl;
      _hasSavedLoginInfo = savedLoginId.isNotEmpty;
    });
  }

  void _goBackToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  Future<void> _clearSavedLoginInfo() async {
    await _loginController.clearSavedLoginInfo();

    if (!mounted) return;

    setState(() {
      _loginIdController.clear();
      _passwordController.clear();
      _savedAvatarUrl = '';
      _hasSavedLoginInfo = false;
      _error = '';
    });
  }

  Future<void> _askSaveLoginInfo({
    required String loginId,
    required String avatarUrl,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Lưu thông tin đăng nhập?',
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Bạn có muốn lưu mã đăng nhập cho lần đăng nhập tiếp theo không?\n\nỨng dụng chỉ lưu mã đăng nhập và ảnh đại diện, không lưu mật khẩu.',
            style: TextStyle(
              color: _subTextColor,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Không lưu',
                style: TextStyle(
                  color: _subTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _loginController.saveLoginInfo(
        loginId: loginId,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;

      setState(() {
        _savedAvatarUrl = avatarUrl;
        _hasSavedLoginInfo = true;
      });
    } else {
      await _loginController.clearSavedLoginInfo();

      if (!mounted) return;

      setState(() {
        _savedAvatarUrl = '';
        _hasSavedLoginInfo = false;
      });
    }
  }

  Future<void> _login() async {
    final loginId = _loginIdController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _error = '';
    });

    final result = await _loginController.login(
      loginId: loginId,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!result.success) {
      setState(() {
        _error = result.error ?? 'Đăng nhập thất bại';
      });
      return;
    }

    final user = result.user;

    if (user == null) {
      setState(() {
        _error = 'Không lấy được thông tin người dùng';
      });
      return;
    }

    if (user.role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FacultyDashboardScreen()),
      );
      return;
    }

    final alreadyRemembered = await _loginController.isRememberedLoginId(
      loginId,
    );

    if (alreadyRemembered) {
      await _loginController.saveLoginInfo(
        loginId: loginId,
        avatarUrl: user.avatar,
      );

      if (mounted) {
        setState(() {
          _savedAvatarUrl = user.avatar;
          _hasSavedLoginInfo = true;
        });
      }
    } else {
      await _askSaveLoginInfo(loginId: loginId, avatarUrl: user.avatar);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _showResetPasswordDialog() async {
    final resetLoginIdController = TextEditingController(
      text: _loginIdController.text.trim(),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Khôi phục mật khẩu',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nhập mã đăng nhập của bạn. Hệ thống sẽ gửi liên kết đặt lại mật khẩu qua email đã đăng ký.',
                    style: TextStyle(
                      color: _subTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: resetLoginIdController,
                    keyboardType: TextInputType.text,
                    cursorColor: _primaryColor,
                    style: const TextStyle(
                      color: _titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Nhập mã đăng nhập',
                      icon: Icons.badge_outlined,
                      borderRadius: 16,
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      color: _subTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final loginId = resetLoginIdController.text.trim();

                          setDialogState(() {
                            isSending = true;
                          });

                          final result = await _loginController
                              .sendResetPasswordByLoginId(loginId);

                          if (!mounted) return;

                          setDialogState(() {
                            isSending = false;
                          });

                          if (result.success) {
                            Navigator.pop(dialogContext);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: result.success
                                  ? _primaryColor
                                  : Colors.red,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Gửi email',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    resetLoginIdController.dispose();
  }

  void _clearErrorWhenTyping() {
    if (_error.isNotEmpty) {
      setState(() {
        _error = '';
      });
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
    double borderRadius = 18,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _hintColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: _primaryColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.4),
      ),
    );
  }

  Widget _buildLoginAvatar() {
    final bool hasSavedAvatar = _savedAvatarUrl.trim().isNotEmpty;

    if (!hasSavedAvatar) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0072FF).withOpacity(0.30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            _savedAvatarUrl,
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRightHeaderIcon() {
    if (!_hasSavedLoginInfo) {
      return const SizedBox(width: 48, height: 48);
    }

    return IconButton(
      tooltip: 'Xóa tài khoản đã lưu',
      onPressed: _clearSavedLoginInfo,
      icon: const Icon(
        Icons.logout_rounded,
        color: Color(0xFF0D47A1),
        size: 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _primaryColor,
          selectionColor: Color(0x331565C0),
          selectionHandleColor: _primaryColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _inputBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFEAF5FF),
                      Color(0xFFF7FBFF),
                      Color(0xFFFFFFFF),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2196F3).withOpacity(0.14),
                ),
              ),
            ),
            Positioned(
              top: 90,
              left: -80,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C6FF).withOpacity(0.10),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: _goBackToWelcome,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF0D47A1),
                              size: 24,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.18),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/itconnect_logo_2.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'ITConnect',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildRightHeaderIcon(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Column(
                        children: [
                          const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              color: _titleColor,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Chào mừng bạn quay lại với ITConnect',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _subTextColor,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 34),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.12),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_savedAvatarUrl.trim().isNotEmpty) ...[
                                  _buildLoginAvatar(),
                                  const SizedBox(height: 26),
                                ],
                                const Text(
                                  'Mã đăng nhập',
                                  style: TextStyle(
                                    color: _titleColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _loginIdController,
                                  keyboardType: TextInputType.text,
                                  cursorColor: _primaryColor,
                                  onChanged: (_) => _clearErrorWhenTyping(),
                                  style: const TextStyle(
                                    color: _titleColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  decoration: _inputDecoration(
                                    hintText: 'Nhập mã đăng nhập',
                                    icon: Icons.badge_outlined,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Mật khẩu',
                                  style: TextStyle(
                                    color: _titleColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscure,
                                  cursorColor: _primaryColor,
                                  onChanged: (_) => _clearErrorWhenTyping(),
                                  style: const TextStyle(
                                    color: _titleColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  decoration: _inputDecoration(
                                    hintText: 'Nhập mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: _primaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscure = !_obscure;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                if (_error.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 26),
                                Container(
                                  width: double.infinity,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00C6FF),
                                        Color(0xFF0072FF),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0072FF,
                                        ).withOpacity(0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor:
                                          Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.login_rounded,
                                                size: 23,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'ĐĂNG NHẬP',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          GestureDetector(
                            onTap: _showResetPasswordDialog,
                            child: RichText(
                              text: const TextSpan(
                                text: 'Quên thông tin đăng nhập? ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _subTextColor,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Hỗ trợ',
                                    style: TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
