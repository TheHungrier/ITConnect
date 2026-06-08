import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/views/admin/admin_attendance_screen.dart';
import 'package:ltdd_qlhd_flutter/views/admin/admin_feedback_screen.dart';
import 'package:ltdd_qlhd_flutter/views/admin/admin_news_screen.dart';
import 'package:ltdd_qlhd_flutter/views/admin/faculty_dashboard_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../widgets/admin_drawer.dart';
import 'admin_activity_form_screen.dart';

class ManageActivitiesScreen extends StatefulWidget {
  const ManageActivitiesScreen({super.key});

  @override
  State<ManageActivitiesScreen> createState() => _ManageActivitiesScreenState();
}

class _ManageActivitiesScreenState extends State<ManageActivitiesScreen> {
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
      final academicYear = _string(data['academicYear']).toLowerCase();
      final semester = _string(data['semester']).toLowerCase();
      final termId = _string(data['termId']).toLowerCase();

      return title.contains(keyword) ||
          category.contains(keyword) ||
          location.contains(keyword) ||
          academicYear.contains(keyword) ||
          semester.contains(keyword) ||
          termId.contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      drawer: AdminDrawer(
        selectedIndex: 1,
        onTapDashboard: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FacultyDashboardScreen()),
          );
        },
        onTapManageActivities: () {
          Navigator.pop(context);
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
          );
        },
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildActivityList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: _openAddActivity,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _openAddActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminActivityFormScreen()),
    );
  }

  void _openEditActivity(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminActivityFormScreen(
          activityId: doc.id,
          initialData: doc.data(),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              'Quản lý hoạt động',
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
                child: _buildEmptyState(),
              )
            else if (filteredDocs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyView(
                  icon: Icons.search_off_rounded,
                  title: 'Không tìm thấy hoạt động',
                  message:
                      'Thử nhập tên hoạt động, danh mục, địa điểm hoặc học kỳ khác.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
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
          hintText: 'Tìm hoạt động, danh mục, địa điểm, học kỳ...',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: primaryBlue,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa có hoạt động',
              style: TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bấm nút + để thêm hoạt động mới.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _subTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final title = _string(data['title'], fallback: 'Hoạt động');
    final category = _formatCategory(
      _string(data['category'], fallback: 'Khác'),
    );
    final location = _string(data['location']);
    final startAt = _date(data['startAt']);
    final endAt = _date(data['endAt']);
    final currentParticipants = _int(data['currentParticipants']);
    final maxParticipants = _int(data['maxParticipants']);
    final points = _int(data['points']);
    final status = _string(data['status'], fallback: 'upcoming');
    final isCancelled = status == 'cancelled' || data['isDeleted'] == true;
    final statusText = _statusText(status);
    final statusColor = _statusColor(status);
    final qrCode = _string(data['qrCode'], fallback: doc.id);
    final imageUrl = _string(data['imageUrl']);
    final academicYear = _string(data['academicYear']);
    final semester = _string(data['semester']);
    final termText = academicYear.isNotEmpty && semester.isNotEmpty
        ? '$semester • $academicYear'
        : _string(data['termId'], fallback: 'Chưa có học kỳ');

    return Container(
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityImage(imageUrl: imageUrl, category: category),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (isCancelled) ...[
                        const SizedBox(width: 8),
                        _solidBadge('Đã hủy', Colors.red),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.school_rounded, termText, Colors.indigo),
                  const SizedBox(height: 8),
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
                        ? '$currentParticipants/$maxParticipants sinh viên • $points điểm'
                        : '$currentParticipants sinh viên • $points điểm',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.flag_rounded,
                    'Trạng thái: $statusText',
                    statusColor,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.qr_code_rounded,
                    'Mã QR: $qrCode',
                    Colors.orange,
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
                    child: _cardActionButton(
                      icon: Icons.qr_code_2_rounded,
                      title: 'Xem QR',
                      color: primaryBlue,
                      onTap: isCancelled
                          ? null
                          : () {
                              _showQrDialog(data, doc.id);
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _cardActionButton(
                      icon: Icons.edit_rounded,
                      title: 'Sửa',
                      color: Colors.orange,
                      onTap: isCancelled
                          ? null
                          : () {
                              _openEditActivity(doc);
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _cardActionButton(
                      icon: isCancelled
                          ? Icons.cancel_rounded
                          : Icons.event_busy_rounded,
                      title: isCancelled ? 'Đã hủy' : 'Hủy',
                      color: Colors.red,
                      onTap: isCancelled
                          ? null
                          : () {
                              _showCancelActivityDialog(doc.id, title);
                            },
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

  Widget _buildActivityImage({
    required String imageUrl,
    required String category,
  }) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 156,
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
                    Colors.black.withOpacity(0.45),
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
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: 156,
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

  void _showQrDialog(Map<String, dynamic> data, String activityId) {
    final title = _string(data['title'], fallback: 'Hoạt động');
    final qrCode = _string(data['qrCode'], fallback: activityId);

    final qrRawValue = _string(
      data['qrRawValue'],
      fallback:
          '{"type":"activity_checkin","activityId":"$activityId","qrCode":"$qrCode"}',
    );

    final isCheckInOpen = data['isCheckInOpen'] == true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDark ? 0.35 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _softBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mã QR điểm danh',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(Icons.close_rounded, color: _subTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _checkInStatusBadge(isCheckInOpen),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: QrImageView(
                    data: qrRawValue,
                    version: QrVersions.auto,
                    size: 230,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isCheckInOpen
                      ? 'Sinh viên mở mục Điểm danh và quét mã này.'
                      : 'Hoạt động chưa mở điểm danh. Sinh viên quét sẽ bị báo chưa mở điểm danh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _subTextColor,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _checkInStatusBadge(bool isOpen) {
    final color = isOpen ? Colors.green : Colors.orange;
    final text = isOpen ? 'Đang mở điểm danh' : 'Chưa mở điểm danh';
    final icon = isOpen
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
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

  Widget _cardActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;

    return Material(
      color: disabled ? Colors.grey.withOpacity(0.10) : color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: disabled
                  ? Colors.grey.withOpacity(0.22)
                  : color.withOpacity(0.28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: disabled ? Colors.grey : color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? Colors.grey : color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelActivityDialog(
    String activityId,
    String title,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Hủy hoạt động',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Bạn có chắc muốn hủy hoạt động "$title" không?\n\nHoạt động sẽ không còn hiển thị cho sinh viên. Các đăng ký liên quan sẽ được chuyển sang trạng thái đã hủy.',
            style: TextStyle(
              color: _subTextColor,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Không'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _cancelActivity(activityId);
              },
              child: const Text('Hủy hoạt động'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelActivity(String activityId) async {
    try {
      final activityRef = _db.collection('activities').doc(activityId);
      final activitySnapshot = await activityRef.get();

      if (!activitySnapshot.exists) {
        _showMessage('Hoạt động không tồn tại');
        return;
      }

      final activityData = activitySnapshot.data() ?? {};
      final status = _string(activityData['status']);
      final finalized = activityData['attendanceFinalized'] == true;

      if (status == 'cancelled' || activityData['isDeleted'] == true) {
        _showMessage('Hoạt động này đã được hủy trước đó');
        return;
      }

      if (finalized || status == 'completed') {
        _showMessage('Hoạt động đã hoàn thành/chốt điểm danh, không nên hủy');
        return;
      }

      final registrations = await _db
          .collectionGroup('myActivities')
          .where('activityId', isEqualTo: activityId)
          .get();

      WriteBatch batch = _db.batch();
      int count = 0;

      batch.set(activityRef, {
        'status': 'cancelled',
        'isDeleted': true,
        'registrationOpen': false,
        'isCheckInOpen': false,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      count++;

      for (final doc in registrations.docs) {
        final data = doc.data();
        final registrationStatus = _string(data['status']);

        if (registrationStatus == 'completed' ||
            registrationStatus == 'absent') {
          continue;
        }

        batch.set(doc.reference, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelReason': 'Hoạt động đã bị hủy bởi quản trị viên',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        count++;

        if (count >= 450) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      _showMessage('Đã hủy hoạt động và cập nhật đăng ký liên quan');
    } catch (e) {
      _showMessage('Lỗi hủy hoạt động: $e');
    }
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
          decoration: _cardDecoration(),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  String _formatCategory(String category) {
    final value = category.trim().toLowerCase();

    switch (value) {
      case 'workshop':
        return 'Workshop';
      case 'seminar':
        return 'Seminar';
      case 'đoàn':
      case 'doan':
        return 'Đoàn';
      case 'clb':
        return 'CLB';
      case 'học thuật':
      case 'hoc thuat':
        return 'Học thuật';
      case 'tình nguyện':
      case 'tinh nguyen':
        return 'Tình nguyện';
      default:
        if (category.trim().isEmpty) return 'Khác';
        final trimmed = category.trim();
        return trimmed[0].toUpperCase() + trimmed.substring(1);
    }
  }

  String _statusText(String status) {
    switch (status.trim().toLowerCase()) {
      case 'upcoming':
        return 'Sắp diễn ra';
      case 'ongoing':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Sắp diễn ra';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'upcoming':
        return Colors.deepPurple;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.deepPurple;
    }
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

  String _formatDateTime(DateTime value) {
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

    return '${_formatDateTime(startAt)} - $endHour:$endMinute';
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
}
