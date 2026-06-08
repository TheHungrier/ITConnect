import 'dart:io';

import 'package:flutter/material.dart';

import '../../controllers/admin_news_controller.dart';
import '../../models/news_model.dart';

class AdminNewsFormScreen extends StatefulWidget {
  final NewsModel? news;

  const AdminNewsFormScreen({super.key, this.news});

  bool get isEdit => news != null;

  @override
  State<AdminNewsFormScreen> createState() => _AdminNewsFormScreenState();
}

class _AdminNewsFormScreenState extends State<AdminNewsFormScreen> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBackground = Color(0xFFF4F8FF);

  final AdminNewsController _controller = AdminNewsController();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;

  final List<String> _categories = [
    'Tin tức',
    'Thông báo',
    'Đoàn',
    'Workshop',
    'Seminar',
    'CLB',
    'Học thuật',
    'Tình nguyện',
  ];

  String _selectedCategory = 'Tin tức';
  bool _isImportant = false;
  bool _removeOldImage = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF0F172A) : lightBackground;

  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;

  Color get _textColor => _isDark ? Colors.white : const Color(0xFF0F172A);

  Color get _subTextColor =>
      _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    final news = widget.news;

    _titleController = TextEditingController(text: news?.title ?? '');
    _summaryController = TextEditingController(text: news?.summary ?? '');
    _contentController = TextEditingController(text: news?.content ?? '');

    final category = news?.category.trim();

    if (category != null && category.isNotEmpty) {
      if (!_categories.contains(category)) {
        _categories.add(category);
      }

      _selectedCategory = category;
    }

    _isImportant = news?.isImportant ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _controller.dispose();

    super.dispose();
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.isEdit) {
        await _controller.updateNews(
          oldNews: widget.news!,
          title: _titleController.text,
          summary: _summaryController.text,
          content: _contentController.text,
          category: _selectedCategory,
          isImportant: _isImportant,
          removeOldImage: _removeOldImage,
        );
      } else {
        await _controller.addNews(
          title: _titleController.text,
          summary: _summaryController.text,
          content: _contentController.text,
          category: _selectedCategory,
          isImportant: _isImportant,
        );
      }

      if (!mounted) return;

      _showMessage(widget.isEdit ? 'Đã cập nhật tin tức' : 'Đã thêm tin tức');

      Navigator.pop(context);
    } catch (e) {
      _showMessage('Lỗi lưu tin tức: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildMainCard(),
                        const SizedBox(height: 14),
                        _buildImageCard(),
                        const SizedBox(height: 14),
                        _buildSettingCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomButton(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 12,
        right: 16,
        bottom: 16,
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
          _BackButtonCard(onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isEdit ? 'Sửa tin tức' : 'Thêm tin tức',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.article_rounded, title: 'Thông tin tin tức'),
          const SizedBox(height: 14),
          _input(
            controller: _titleController,
            label: 'Tiêu đề',
            icon: Icons.title_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tiêu đề';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Danh mục',
            icon: Icons.category_rounded,
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _input(
            controller: _summaryController,
            label: 'Tóm tắt',
            icon: Icons.short_text_rounded,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tóm tắt';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          _input(
            controller: _contentController,
            label: 'Nội dung chi tiết',
            icon: Icons.description_rounded,
            maxLines: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    final oldImageUrl = widget.news?.imageUrl.trim() ?? '';

    final hasImage =
        _controller.selectedImage != null ||
        (oldImageUrl.isNotEmpty && !_removeOldImage);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.image_rounded, title: 'Ảnh tin tức'),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 170,
              width: double.infinity,
              color: _isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFEAF4FF),
              child: _buildImagePreview(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: hasImage ? 2 : 1,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _controller.isLoading
                        ? null
                        : () async {
                            await _controller.pickImageFromGallery();

                            if (!mounted) return;

                            setState(() {
                              _removeOldImage = false;
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: const BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(
                      hasImage ? 'Đổi ảnh' : 'Chọn ảnh từ thư viện',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _controller.isLoading ? null : _clearNewsImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.55)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _clearNewsImage() {
    _controller.clearSelectedImage();

    setState(() {
      _removeOldImage = true;
    });
  }

  Widget _buildImagePreview() {
    if (_controller.selectedImage != null) {
      return Image.file(
        File(_controller.selectedImage!.path),
        fit: BoxFit.cover,
      );
    }

    final oldImageUrl = widget.news?.imageUrl.trim() ?? '';

    if (oldImageUrl.isNotEmpty && !_removeOldImage) {
      return Image.network(
        oldImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _emptyImagePreview();
        },
      );
    }

    return _emptyImagePreview();
  }

  Widget _emptyImagePreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, color: _subTextColor, size: 42),
        const SizedBox(height: 8),
        Text(
          'Chưa chọn ảnh',
          style: TextStyle(color: _subTextColor, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildSettingCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.tune_rounded, title: 'Cài đặt'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: primaryBlue,
            title: Text(
              'Tin quan trọng',
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Tin quan trọng sẽ được ưu tiên hiển thị và tạo thông báo cho sinh viên',
              style: TextStyle(
                color: _subTextColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: _isImportant,
            onChanged: (value) {
              setState(() {
                _isImportant = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.3 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _controller.isLoading ? null : _saveNews,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _controller.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Text(
                  widget.isEdit ? 'Cập nhật tin tức' : 'Thêm tin tức',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _cardTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryBlue, size: 21),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: _textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.22 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _subTextColor,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: _cardColor,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: _subTextColor),
      style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _subTextColor,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _BackButtonCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButtonCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.32)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
