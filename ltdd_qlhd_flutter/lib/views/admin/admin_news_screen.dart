import 'package:flutter/material.dart';

import '../../controllers/admin_news_controller.dart';
import '../../models/news_model.dart';
import '../../widgets/admin_drawer.dart';
import 'admin_attendance_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_news_form_screen.dart';
import 'faculty_dashboard_screen.dart';
import 'manage_activities_screen.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBackground = Color(0xFFF4F8FF);

  final AdminNewsController _controller = AdminNewsController();
  final TextEditingController _searchController = TextEditingController();

  String _keyword = '';
  String _filter = 'all';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF0F172A) : lightBackground;

  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;

  Color get _textColor => _isDark ? Colors.white : const Color(0xFF0F172A);

  Color get _subTextColor =>
      _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  Color get _softBlue =>
      _isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD);

  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddNews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminNewsFormScreen()),
    );
  }

  void _openEditNews(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminNewsFormScreen(news: news)),
    );
  }

  List<NewsModel> _filteredNews(List<NewsModel> newsList) {
    final keyword = _keyword.trim().toLowerCase();

    return newsList.where((news) {
      final matchFilter =
          _filter == 'all' ||
          (_filter == 'important' && news.isImportant) ||
          (_filter == 'normal' && !news.isImportant);

      final searchableText = [
        news.title,
        news.summary,
        news.content,
        news.category,
      ].join(' ').toLowerCase();

      final matchKeyword = keyword.isEmpty || searchableText.contains(keyword);

      return matchFilter && matchKeyword;
    }).toList();
  }

  Future<void> _deleteNews(NewsModel news) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Xóa tin tức?',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Bạn có chắc muốn xóa tin "${news.title}" không?',
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: _subTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Xóa',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _controller.deleteNews(news.id);

      if (!mounted) return;

      _showMessage('Đã xóa tin tức');
    } catch (e) {
      _showMessage('Lỗi xóa tin tức: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      drawer: AdminDrawer(
        selectedIndex: 2,
        onTapDashboard: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FacultyDashboardScreen()),
          );
        },
        onTapManageActivities: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ManageActivitiesScreen()),
          );
        },
        onTapManageNews: () {
          Navigator.pop(context);
        },
        onTapAttendance: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
          );
        },
        onTapFeedbacks: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
          );
        },
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<NewsModel>>(
              stream: _controller.getNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return _emptyBox(
                    icon: Icons.error_outline_rounded,
                    title: 'Không tải được tin tức',
                    message: snapshot.error.toString(),
                  );
                }

                final newsList = snapshot.data ?? [];
                final filteredNews = _filteredNews(newsList);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _buildSearchBox(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _buildFilterTabs(),
                      ),
                    ),
                    if (newsList.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _emptyBox(
                          icon: Icons.article_outlined,
                          title: 'Chưa có tin tức',
                          message: 'Bấm nút + để thêm tin tức mới.',
                        ),
                      )
                    else if (filteredNews.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _emptyBox(
                          icon: Icons.search_off_rounded,
                          title: 'Không tìm thấy tin tức',
                          message: 'Thử đổi từ khóa hoặc bộ lọc khác.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        sliver: SliverList.separated(
                          itemCount: filteredNews.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildNewsCard(filteredNews[index]);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: _openAddNews,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8,
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
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Quản lý tin tức',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
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

  Widget _buildSearchBox() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.18 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _keyword = value;
          });
        },
        cursorColor: primaryBlue,
        style: TextStyle(
          color: _textColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm theo tiêu đề, tóm tắt, danh mục...',
          hintStyle: TextStyle(
            color: _subTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue),
          suffixIcon: _keyword.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _keyword = '';
                    });
                  },
                  icon: Icon(Icons.close_rounded, color: _subTextColor),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF111827) : const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          _filterButton('Tất cả', 'all'),
          _filterButton('Quan trọng', 'important'),
          _filterButton('Thường', 'normal'),
        ],
      ),
    );
  }

  Widget _filterButton(String text, String value) {
    final selected = _filter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filter = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : _subTextColor,
              fontSize: 12.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsModel news) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.22 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _newsImage(news),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title.trim().isEmpty ? 'Không có tiêu đề' : news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16.5,
                      height: 1.28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.summary.trim().isEmpty
                        ? 'Chưa có tóm tắt tin tức.'
                        : news.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _subTextColor,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: _subTextColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatDate(news.createdAt),
                          style: TextStyle(
                            color: _subTextColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.edit_rounded,
                      title: 'Sửa',
                      color: Colors.orange,
                      onTap: () => _openEditNews(news),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.delete_rounded,
                      title: 'Xóa',
                      color: Colors.red,
                      onTap: () => _deleteNews(news),
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

  Widget _newsImage(NewsModel news) {
    final hasImage = news.imageUrl.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 158,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              news.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imageFallback(),
            )
          else
            _imageFallback(),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Colors.black.withOpacity(0.42),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _solidBadge(news.category, primaryBlue),
          ),
          if (news.isImportant)
            Positioned(
              top: 12,
              right: 12,
              child: _solidBadge('Quan trọng', const Color(0xFFD32F2F)),
            ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: 158,
      decoration: BoxDecoration(
        gradient: _isDark
            ? const LinearGradient(
                colors: [Color(0xFF102A43), Color(0xFF1E3A5F)],
              )
            : const LinearGradient(
                colors: [Color(0xFFEAF5FF), Color(0xFFBBDEFB)],
              ),
      ),
      child: const Center(
        child: Icon(Icons.article_rounded, color: primaryBlue, size: 44),
      ),
    );
  }

  Widget _solidBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text.trim().isEmpty ? 'Tin tức' : text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyBox({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.18 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: primaryBlue, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _subTextColor,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa có ngày tạo';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    return '$day/$month/$year';
  }
}
