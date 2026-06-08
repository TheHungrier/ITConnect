import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/admin_drawer.dart';
import 'admin_attendance_screen.dart';
import 'admin_news_screen.dart';
import 'faculty_dashboard_screen.dart';
import 'manage_activities_screen.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBackground = Color(0xFFF4F8FF);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _selectedStatus = 'pending';

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

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchFeedbacks() {
    return _db
        .collection('feedbacks')
        .where('status', isEqualTo: _selectedStatus)
        .snapshots();
  }

  Future<void> _markRead(String feedbackId) async {
    if (feedbackId.trim().isEmpty) return;

    try {
      await _db.collection('feedbacks').doc(feedbackId).set({
        'status': 'resolved',
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMessage('Đã đánh dấu góp ý là đã đọc');
    } catch (e) {
      _showMessage('Lỗi cập nhật góp ý: $e', isError: true);
    }
  }

  Future<void> _markUnread(String feedbackId) async {
    if (feedbackId.trim().isEmpty) return;

    try {
      await _db.collection('feedbacks').doc(feedbackId).set({
        'status': 'pending',
        'readAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMessage('Đã chuyển góp ý về chưa đọc');
    } catch (e) {
      _showMessage('Lỗi cập nhật góp ý: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      drawer: AdminDrawer(
        selectedIndex: 4,
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
          );
        },
        onTapFeedbacks: () {
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildStatusFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _watchFeedbacks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return _errorView('Không tải được góp ý.\n${snapshot.error}');
                }

                final docs = [...(snapshot.data?.docs ?? [])];

                docs.sort((a, b) {
                  final aDate = _date(a.data()['createdAt']);
                  final bDate = _date(b.data()['createdAt']);

                  return bDate.compareTo(aDate);
                });

                if (docs.isEmpty) {
                  return _emptyView();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _buildFeedbackCard(docs[index]);
                  },
                );
              },
            ),
          ),
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
              'Góp ý sinh viên',
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

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF111827) : const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            _tabButton(
              title: 'Chưa đọc',
              value: 'pending',
              icon: Icons.mark_email_unread_rounded,
            ),
            _tabButton(
              title: 'Đã đọc',
              value: 'resolved',
              icon: Icons.mark_email_read_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final selected = _selectedStatus == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : _subTextColor,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : _subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyView() {
    final isUnread = _selectedStatus == 'pending';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                isUnread
                    ? Icons.feedback_outlined
                    : Icons.check_circle_outline_rounded,
                color: primaryBlue,
                size: 38,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isUnread ? 'Không có góp ý chưa đọc' : 'Chưa có góp ý đã đọc',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isUnread
                  ? 'Góp ý mới của sinh viên sẽ xuất hiện tại đây.'
                  : 'Các góp ý đã được admin đọc sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _subTextColor,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final userName = _string(data['userName'], fallback: 'Sinh viên');
    final studentId = _string(data['studentId']);
    final userEmail = _string(data['userEmail']);
    final type = _string(data['type'], fallback: 'Góp ý');
    final content = _string(data['content']);
    final status = _string(data['status'], fallback: 'pending');
    final createdAt = _date(data['createdAt']);

    final isRead = status == 'resolved';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.22 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardTopInfo(
                  userName: userName,
                  studentId: studentId,
                  createdAt: createdAt,
                  isRead: isRead,
                ),
                const SizedBox(height: 14),
                _infoLine(
                  icon: Icons.category_rounded,
                  label: 'Loại góp ý',
                  value: type,
                  color: Colors.deepPurple,
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoLine(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: userEmail,
                    color: primaryBlue,
                  ),
                ],
                const SizedBox(height: 14),
                _contentBox(content),
              ],
            ),
          ),
          Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: isRead ? _markUnreadButton(doc.id) : _markReadButton(doc.id),
          ),
        ],
      ),
    );
  }

  Widget _cardTopInfo({
    required String userName,
    required String studentId,
    required DateTime createdAt,
    required bool isRead,
  }) {
    return Row(
      children: [
        _avatarBox(userName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                studentId.isNotEmpty
                    ? '$studentId • ${_formatDate(createdAt)}'
                    : _formatDate(createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _subTextColor,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _statusBadge(isRead),
      ],
    );
  }

  Widget _avatarBox(String name) {
    final initial = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool isRead) {
    final color = isRead ? Colors.green : Colors.orange;
    final text = isRead ? 'Đã đọc' : 'Chưa đọc';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: _subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textColor,
              fontSize: 12.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _contentBox(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        content.trim().isEmpty ? 'Không có nội dung.' : content.trim(),
        style: TextStyle(
          color: _textColor,
          fontSize: 13.5,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _markReadButton(String feedbackId) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () {
          _showReadDialog(feedbackId);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.mark_email_read_rounded, size: 19),
        label: const Text(
          'Đánh dấu đã đọc',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _markUnreadButton(String feedbackId) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () {
          _showUnreadDialog(feedbackId);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.mark_email_unread_rounded, size: 19),
        label: const Text(
          'Đánh dấu chưa đọc',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Future<void> _showReadDialog(String feedbackId) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Đánh dấu đã đọc?',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Góp ý này sẽ được chuyển sang danh sách đã đọc.',
            style: TextStyle(
              color: _subTextColor,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: _subTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _markRead(feedbackId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUnreadDialog(String feedbackId) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Đánh dấu chưa đọc?',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Góp ý này sẽ được chuyển về danh sách chưa đọc.',
            style: TextStyle(
              color: _subTextColor,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: _subTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _markUnread(feedbackId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
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

  String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString() ?? '';

    return text.trim().isEmpty ? fallback : text.trim();
  }

  DateTime _date(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) {
      return 'Chưa có thời gian';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
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
}
