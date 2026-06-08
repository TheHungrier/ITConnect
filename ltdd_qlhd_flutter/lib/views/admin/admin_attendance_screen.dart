import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/admin_drawer.dart';
import 'admin_attendance_detail_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_news_screen.dart';
import 'faculty_dashboard_screen.dart';
import 'manage_activities_screen.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBackground = Color(0xFFF4F8FF);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _keyword = '';

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
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchActivities() {
    return _db
        .collection('activities')
        .orderBy('startAt', descending: true)
        .snapshots();
  }

  void _openAttendanceDetail({
    required String activityId,
    required String activityTitle,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAttendanceDetailScreen(
          activityId: activityId,
          initialTitle: activityTitle,
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterActivities(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final keyword = _keyword.trim().toLowerCase();

    if (keyword.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data();

      final title = _string(data['title']).toLowerCase();
      final category = _string(data['category']).toLowerCase();
      final location = _string(data['location']).toLowerCase();

      return title.contains(keyword) ||
          category.contains(keyword) ||
          location.contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      drawer: AdminDrawer(
        selectedIndex: 3,
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminNewsScreen()),
          );
        },
        onTapAttendance: () {
          Navigator.pop(context);
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
          Expanded(child: _buildActivityList()),
        ],
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
              'Quản lý điểm danh',
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

  Widget _buildActivityList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _watchActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return _errorView('Không tải được hoạt động.\n${snapshot.error}');
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = _filterActivities(docs);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSearchBox(),
              ),
            ),
            if (docs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyView(
                  icon: Icons.event_busy_rounded,
                  title: 'Chưa có hoạt động',
                  message: 'Các hoạt động sẽ hiển thị tại đây.',
                ),
              )
            else if (filteredDocs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyView(
                  icon: Icons.search_off_rounded,
                  title: 'Không tìm thấy hoạt động',
                  message:
                      'Thử nhập tên hoạt động, danh mục hoặc địa điểm khác.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverList.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildActivityCard(filteredDocs[index]);
                  },
                ),
              ),
          ],
        );
      },
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
          hintText: 'Tìm hoạt động, danh mục, địa điểm...',
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

  Widget _buildActivityCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final title = _string(data['title'], fallback: 'Hoạt động');
    final category = _string(data['category'], fallback: 'Khác');
    final location = _string(data['location']);
    final startAt = _date(data['startAt']);
    final endAt = _date(data['endAt']);
    final currentParticipants = _int(data['currentParticipants']);
    final maxParticipants = _int(data['maxParticipants']);
    final isCheckInOpen = data['isCheckInOpen'] == true;
    final finalized = data['attendanceFinalized'] == true;
    final imageUrl = _string(data['imageUrl']);

    final now = DateTime.now();
    final hasEnded = now.isAfter(endAt);

    return Container(
      decoration: _cardDecoration(radius: 26),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _activityImage(
              imageUrl: imageUrl,
              category: category,
              isCheckInOpen: isCheckInOpen,
              finalized: finalized,
              hasEnded: hasEnded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16.5,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.calendar_month_rounded,
                    _formatDateTimeRange(startAt, endAt),
                    primaryBlue,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.location_on_rounded,
                    location.isEmpty ? 'Chưa có địa điểm' : location,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.people_alt_rounded,
                    maxParticipants > 0
                        ? '$currentParticipants/$maxParticipants sinh viên đăng ký'
                        : '$currentParticipants sinh viên đăng ký',
                    Colors.green,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _openAttendanceDetail(
                      activityId: doc.id,
                      activityTitle: title,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.fact_check_rounded, size: 19),
                  label: const Text(
                    'Xem danh sách điểm danh',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityImage({
    required String imageUrl,
    required String category,
    required bool isCheckInOpen,
    required bool finalized,
    required bool hasEnded,
  }) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 152,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl,
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
            child: _solidBadge(category, primaryBlue),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: finalized
                ? _solidBadge('Đã chốt', Colors.green)
                : hasEnded
                ? _solidBadge('Chờ chốt', Colors.red)
                : isCheckInOpen
                ? _solidBadge('Mở điểm danh', Colors.orange)
                : _solidBadge('Chưa mở', Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: 152,
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
        child: Icon(Icons.event_note_rounded, color: primaryBlue, size: 44),
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
        text.trim().isEmpty ? 'Khác' : text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyView({
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
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(icon, color: primaryBlue, size: 36),
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

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(_isDark ? 0.22 : 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString() ?? '';

    return text.trim().isEmpty ? fallback : text.trim();
  }

  int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime _date(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return fallback ?? DateTime.now();
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatDateTimeRange(DateTime startAt, DateTime endAt) {
    final endHour = endAt.hour.toString().padLeft(2, '0');
    final endMinute = endAt.minute.toString().padLeft(2, '0');

    return '${_formatDate(startAt)} - $endHour:$endMinute';
  }
}
