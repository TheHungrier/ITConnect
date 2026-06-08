import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../repositories/notification_repository.dart';

class AdminAttendanceDetailScreen extends StatefulWidget {
  final String activityId;
  final String initialTitle;

  const AdminAttendanceDetailScreen({
    super.key,
    required this.activityId,
    required this.initialTitle,
  });

  @override
  State<AdminAttendanceDetailScreen> createState() =>
      _AdminAttendanceDetailScreenState();
}

class _AdminAttendanceDetailScreenState
    extends State<AdminAttendanceDetailScreen> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBackground = Color(0xFFF4F8FF);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _selectedFilter = 'all';

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

  String get _selectedFilterTitle {
    switch (_selectedFilter) {
      case 'attended':
        return 'Đã điểm danh';
      case 'waiting':
        return 'Chờ xử lý';
      case 'absent':
        return 'Vắng';
      default:
        return 'Tất cả sinh viên';
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchActivity() {
    return _db.collection('activities').doc(widget.activityId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchRegistrations() {
    return _db
        .collectionGroup('myActivities')
        .where('activityId', isEqualTo: widget.activityId)
        .snapshots();
  }

  Future<void> _approveAttendance({
    required DocumentReference<Map<String, dynamic>> registrationRef,
    required String userId,
    required String activityId,
    required String activityTitle,
  }) async {
    if (userId.trim().isEmpty) {
      _showMessage(
        'Không tìm thấy sinh viên để duyệt điểm danh',
        isError: true,
      );
      return;
    }

    try {
      await registrationRef.set({
        'attended': true,
        'status': 'approved',
        'attendanceApproved': true,
        'attendanceRejected': false,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMessage(
        'Đã duyệt minh chứng. Điểm sẽ được cộng khi chốt điểm danh.',
      );
    } catch (e) {
      _showMessage('Lỗi duyệt điểm danh: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _watchActivity(),
              builder: (context, activitySnapshot) {
                if (activitySnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !activitySnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                if (activitySnapshot.hasError) {
                  return _errorView(
                    'Không tải được hoạt động.\n${activitySnapshot.error}',
                  );
                }

                if (!activitySnapshot.hasData ||
                    !activitySnapshot.data!.exists) {
                  return _emptyView(
                    icon: Icons.event_busy_rounded,
                    title: 'Hoạt động không tồn tại',
                    message: 'Không tìm thấy dữ liệu hoạt động này.',
                  );
                }

                final activityData = activitySnapshot.data!.data() ?? {};
                return _buildAttendanceContent(activityData);
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
        left: 16,
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
          _headerIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Danh sách điểm danh',
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

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildAttendanceContent(Map<String, dynamic> activityData) {
    final activityTitle = _string(
      activityData['title'],
      fallback: widget.initialTitle.isEmpty ? 'Hoạt động' : widget.initialTitle,
    );

    final finalized = activityData['attendanceFinalized'] == true;
    final endAt = _date(activityData['endAt']);
    final hasEnded = DateTime.now().isAfter(endAt);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _watchRegistrations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return _errorView('Không tải được danh sách.\n${snapshot.error}');
        }

        final allDocs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          return _string(data['status']) != 'cancelled';
        }).toList();

        final attendedCount = allDocs.where(_isAttendedRegistration).length;
        final absentCount = allDocs.where(_isAbsentRegistration).length;
        final waitingCount = allDocs.length - attendedCount - absentCount;

        final filteredDocs = allDocs.where((doc) {
          if (_selectedFilter == 'attended') {
            return _isAttendedRegistration(doc);
          }

          if (_selectedFilter == 'waiting') {
            return _isWaitingRegistration(doc);
          }

          if (_selectedFilter == 'absent') {
            return _isAbsentRegistration(doc);
          }

          return true;
        }).toList();

        return Column(
          children: [
            _buildSelectedActivitySummary(
              title: activityTitle,
              total: allDocs.length,
              attended: attendedCount,
              waiting: waitingCount,
              absent: absentCount,
              hasEnded: hasEnded,
              finalized: finalized,
            ),
            _buildFilterButton(),
            Expanded(
              child: filteredDocs.isEmpty
                  ? _emptyView(
                      icon: Icons.people_outline_rounded,
                      title: 'Không có dữ liệu',
                      message: 'Không có sinh viên trong bộ lọc này.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        return _buildRegistrationCard(filteredDocs[index]);
                      },
                    ),
            ),
            _buildFinalizeButton(
              activityId: widget.activityId,
              activityTitle: activityTitle,
              registrations: allDocs,
              finalized: finalized,
              hasEnded: hasEnded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedActivitySummary({
    required String title,
    required int total,
    required int attended,
    required int waiting,
    required int absent,
    required bool hasEnded,
    required bool finalized,
  }) {
    final statusText = finalized
        ? 'Đã chốt điểm danh'
        : hasEnded
        ? 'Có thể chốt điểm danh'
        : 'Hoạt động chưa kết thúc';

    final statusColor = finalized
        ? Colors.green
        : hasEnded
        ? Colors.red
        : Colors.orange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withOpacity(0.28)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  title: 'Tổng đăng ký',
                  value: total.toString(),
                  color: primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryItem(
                  title: 'Đã điểm danh',
                  value: attended.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  title: 'Chờ xử lý',
                  value: waiting.toString(),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryItem(
                  title: 'Vắng',
                  value: absent.toString(),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textColor,
              fontSize: 11.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _showFilterBottomSheet,
          child: Container(
            width: double.infinity,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDark ? 0.18 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedFilterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: _subTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFilterBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.white.withOpacity(0.16)
                        : const Color(0xFFD5E0EF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Lọc danh sách',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _filterSheetItem(
                  sheetContext: sheetContext,
                  value: 'all',
                  title: 'Tất cả sinh viên',
                ),
                _filterSheetItem(
                  sheetContext: sheetContext,
                  value: 'attended',
                  title: 'Đã điểm danh',
                ),
                _filterSheetItem(
                  sheetContext: sheetContext,
                  value: 'waiting',
                  title: 'Chờ xử lý',
                ),
                _filterSheetItem(
                  sheetContext: sheetContext,
                  value: 'absent',
                  title: 'Vắng',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterSheetItem({
    required BuildContext sheetContext,
    required String value,
    required String title,
  }) {
    final selected = _selectedFilter == value;

    return Material(
      color: selected ? primaryBlue.withOpacity(0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(sheetContext);

          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? primaryBlue : _textColor,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final userId = doc.reference.parent.parent?.id ?? '';
    final attended = data['attended'] == true;
    final status = _string(data['status'], fallback: 'upcoming');
    final registeredAt = _date(data['registeredAt']);

    final points = _int(data['points']);
    final penaltyPoints = _int(data['penaltyPoints']);

    if (userId.isEmpty) {
      return _buildRegistrationCardContent(
        registrationRef: doc.reference,
        userId: userId,
        data: data,
        userData: const {},
        attended: attended,
        status: status,
        registeredAt: registeredAt,
        points: points,
        penaltyPoints: penaltyPoints,
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _db.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? {};

        return _buildRegistrationCardContent(
          registrationRef: doc.reference,
          userId: userId,
          data: data,
          userData: userData,
          attended: attended,
          status: status,
          registeredAt: registeredAt,
          points: points,
          penaltyPoints: penaltyPoints,
        );
      },
    );
  }

  Widget _buildRegistrationCardContent({
    required DocumentReference<Map<String, dynamic>> registrationRef,
    required String userId,
    required Map<String, dynamic> data,
    required Map<String, dynamic> userData,
    required bool attended,
    required String status,
    required DateTime registeredAt,
    required int points,
    required int penaltyPoints,
  }) {
    final studentName = _string(
      userData['name'],
      fallback: _string(data['userName'], fallback: 'Sinh viên'),
    );

    final studentId = _string(
      userData['studentId'],
      fallback: _string(data['studentId']),
    );

    final email = _string(
      userData['email'],
      fallback: _string(data['userEmail']),
    );

    final proofUrl = _string(data['proofUrl']);
    final proofType = _string(data['proofType'], fallback: 'image');

    final checkedInAt = data['checkedInAt'] is Timestamp
        ? (data['checkedInAt'] as Timestamp).toDate()
        : null;

    final proofUploadedAt = data['proofUploadedAt'] is Timestamp
        ? (data['proofUploadedAt'] as Timestamp).toDate()
        : null;

    final canApprove =
        proofUrl.isNotEmpty &&
        (status == 'pending_review' || status == 'rejected');

    final canReject =
        proofUrl.isNotEmpty &&
        (status == 'pending_review' || status == 'approved');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _studentAvatar(studentName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentId.isNotEmpty ? studentId : 'Chưa có MSSV',
                  style: TextStyle(
                    color: _subTextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _registrationStatusBadge(
                      status: status,
                      attended: attended,
                    ),
                    if (status == 'completed')
                      _miniInfoBadge(
                        icon: Icons.star_rounded,
                        text: '+$points điểm',
                        color: Colors.green,
                      ),
                    if (status == 'absent' || penaltyPoints > 0)
                      _miniInfoBadge(
                        icon: Icons.remove_circle_rounded,
                        text: '-${penaltyPoints > 0 ? penaltyPoints : 6} điểm',
                        color: Colors.red,
                      ),
                    _miniInfoBadge(
                      icon: Icons.schedule_rounded,
                      text: 'ĐK ${_formatDate(registeredAt)}',
                      color: primaryBlue,
                    ),
                    if (checkedInAt != null)
                      _miniInfoBadge(
                        icon: Icons.qr_code_scanner_rounded,
                        text: 'Gửi MC ${_formatDate(checkedInAt)}',
                        color: Colors.orange,
                      ),
                    if (proofUrl.isNotEmpty)
                      _miniActionBadge(
                        icon: proofType == 'video'
                            ? Icons.play_circle_fill_rounded
                            : Icons.image_rounded,
                        text: 'Xem minh chứng',
                        color: primaryBlue,
                        onTap: () {
                          _showProofDialog(
                            proofUrl: proofUrl,
                            proofType: proofType,
                            studentName: studentName,
                            proofUploadedAt: proofUploadedAt,
                          );
                        },
                      ),
                    if (canApprove)
                      _miniActionBadge(
                        icon: Icons.check_circle_rounded,
                        text: 'Duyệt',
                        color: Colors.green,
                        onTap: () {
                          _approveAttendance(
                            registrationRef: registrationRef,
                            userId: userId,
                            activityId: widget.activityId,
                            activityTitle: _string(
                              data['title'],
                              fallback: widget.initialTitle,
                            ),
                          );
                        },
                      ),
                    if (canReject)
                      _miniActionBadge(
                        icon: Icons.block_rounded,
                        text: 'Từ chối',
                        color: Colors.red,
                        onTap: () {
                          _showRejectDialog(
                            registrationRef: registrationRef,
                            userId: userId,
                            activityId: widget.activityId,
                            activityTitle: _string(
                              data['title'],
                              fallback: widget.initialTitle,
                            ),
                            studentName: studentName,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton({
    required String activityId,
    required String activityTitle,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
    required bool finalized,
    required bool hasEnded,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
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
        height: 50,
        child: ElevatedButton.icon(
          onPressed: finalized || registrations.isEmpty
              ? null
              : () {
                  if (!hasEnded) {
                    _showNotEndedDialog();
                    return;
                  }

                  if (_hasPendingReview(registrations)) {
                    _showMessage(
                      'Còn minh chứng đang chờ xử lý. Vui lòng duyệt hoặc từ chối trước khi chốt.',
                      isError: true,
                    );
                    return;
                  }

                  _showFinalizeDialog(
                    activityId: activityId,
                    activityTitle: activityTitle,
                    registrations: registrations,
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: finalized ? Colors.grey : primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(
            finalized ? Icons.check_circle_rounded : Icons.fact_check_rounded,
          ),
          label: Text(
            finalized ? 'Đã chốt điểm danh' : 'Chốt điểm danh',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Future<void> _showNotEndedDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Hoạt động chưa kết thúc',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Hoạt động chưa kết thúc. Bạn chỉ nên chốt điểm danh sau khi hoạt động kết thúc.',
            style: TextStyle(
              color: _subTextColor,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFinalizeDialog({
    required String activityId,
    required String activityTitle,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
  }) async {
    final waitingCount = registrations.where(_isWaitingRegistration).length;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Chốt điểm danh',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w900),
          ),
          content: Text(
            waitingCount > 0
                ? 'Có $waitingCount sinh viên chưa được duyệt. Sau khi chốt, các sinh viên chưa hoàn tất hoặc bị từ chối sẽ bị đánh dấu vắng và trừ 6 điểm rèn luyện.'
                : 'Tất cả minh chứng đã được xử lý. Bạn muốn chốt điểm danh hoạt động này? Sau khi chốt, hệ thống mới cộng/trừ điểm chính thức.',
            style: TextStyle(
              color: _subTextColor,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _finalizeAttendance(
                  activityId: activityId,
                  activityTitle: activityTitle,
                  registrations: registrations,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Chốt',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _finalizeAttendance({
    required String activityId,
    required String activityTitle,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
  }) async {
    try {
      final batch = _db.batch();

      int absentCount = 0;
      int completedCount = 0;

      final notifications = <_AttendanceFinalizeNotification>[];

      for (final doc in registrations) {
        final data = doc.data();

        final status = _string(data['status'], fallback: 'upcoming');
        final userId = doc.reference.parent.parent?.id ?? '';

        if (status == 'cancelled') continue;

        if (status == 'completed') {
          completedCount++;

          batch.set(doc.reference, {
            'attended': true,
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else if (status == 'approved') {
          completedCount++;

          batch.set(doc.reference, {
            'attended': true,
            'status': 'completed',
            'attendanceFinalized': true,
            'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          absentCount++;

          final reason = status == 'rejected'
              ? 'Minh chứng điểm danh không hợp lệ.'
              : 'Bạn chưa hoàn tất điểm danh cho hoạt động này.';

          batch.set(doc.reference, {
            'attended': false,
            'status': 'absent',
            'penaltyPoints': 6,
            'attendanceFinalized': true,
            'absentAt': FieldValue.serverTimestamp(),
            'rejectReason': reason,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (userId.trim().isNotEmpty) {
            notifications.add(
              _AttendanceFinalizeNotification(
                targetUserId: userId,
                reason: reason,
              ),
            );
          }
        }
      }

      final activityRef = _db.collection('activities').doc(activityId);

      batch.set(activityRef, {
        'attendanceFinalized': true,
        'attendanceFinalizedAt': FieldValue.serverTimestamp(),
        'isCheckInOpen': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final notificationRef = _db
          .collection('adminNotifications')
          .doc('activity_ended_$activityId');

      batch.set(notificationRef, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      for (final notification in notifications) {
        try {
          await NotificationRepository().createAttendanceRejectedNotification(
            targetUserId: notification.targetUserId,
            activityId: activityId,
            activityTitle: activityTitle,
            reason: notification.reason,
          );
        } catch (_) {}
      }

      if (!mounted) return;

      _showMessage(
        absentCount > 0
            ? 'Đã chốt điểm danh. Hoàn thành $completedCount sinh viên, vắng $absentCount sinh viên.'
            : 'Đã chốt điểm danh. Hoàn thành $completedCount sinh viên.',
      );
    } catch (e) {
      _showMessage('Lỗi chốt điểm danh: $e', isError: true);
    }
  }

  Future<void> _showRejectDialog({
    required DocumentReference<Map<String, dynamic>> registrationRef,
    required String userId,
    required String activityId,
    required String activityTitle,
    required String studentName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Từ chối điểm danh',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Minh chứng của sinh viên "$studentName" sẽ được đánh dấu từ chối. Điểm chỉ bị trừ sau khi bạn chốt điểm danh.',
            style: TextStyle(
              color: _subTextColor,
              height: 1.45,
              fontWeight: FontWeight.w600,
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Từ chối',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _rejectAttendance(
      registrationRef: registrationRef,
      userId: userId,
      activityId: activityId,
      activityTitle: activityTitle,
      reason: 'Minh chứng điểm danh không hợp lệ.',
    );
  }

  Future<void> _rejectAttendance({
    required DocumentReference<Map<String, dynamic>> registrationRef,
    required String userId,
    required String activityId,
    required String activityTitle,
    required String reason,
  }) async {
    if (userId.trim().isEmpty) {
      _showMessage(
        'Không tìm thấy sinh viên để từ chối điểm danh',
        isError: true,
      );
      return;
    }

    try {
      await registrationRef.set({
        'attended': false,
        'status': 'rejected',
        'attendanceApproved': false,
        'attendanceRejected': true,
        'rejectReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMessage('Đã từ chối minh chứng. Điểm sẽ bị trừ khi chốt điểm danh.');
    } catch (e) {
      _showMessage('Lỗi từ chối điểm danh: $e', isError: true);
    }
  }

  bool _isAttendedRegistration(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status = _string(data['status']);
    return status == 'approved' || status == 'completed';
  }

  bool _isAbsentRegistration(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = _string(data['status']);
    return status == 'absent';
  }

  bool _isWaitingRegistration(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final status = _string(data['status']);

    return status != 'approved' &&
        status != 'completed' &&
        status != 'absent' &&
        status != 'cancelled';
  }

  bool _hasPendingReview(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
  ) {
    return registrations.any((doc) {
      final status = _string(doc.data()['status']);
      return status == 'pending_review';
    });
  }

  Widget _studentAvatar(String name) {
    final initial = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(16),
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

  Widget _registrationStatusBadge({
    required String status,
    required bool attended,
  }) {
    if (status == 'completed') {
      return _miniInfoBadge(
        icon: Icons.check_circle_rounded,
        text: 'Đã chốt',
        color: Colors.green,
      );
    }

    if (status == 'approved') {
      return _miniInfoBadge(
        icon: Icons.verified_rounded,
        text: 'Đã duyệt',
        color: Colors.green,
      );
    }

    if (status == 'rejected') {
      return _miniInfoBadge(
        icon: Icons.block_rounded,
        text: 'Từ chối',
        color: Colors.red,
      );
    }

    if (status == 'absent') {
      return _miniInfoBadge(
        icon: Icons.cancel_rounded,
        text: 'Vắng',
        color: Colors.red,
      );
    }

    if (status == 'pending_review') {
      return _miniInfoBadge(
        icon: Icons.pending_actions_rounded,
        text: 'Chờ duyệt',
        color: Colors.orange,
      );
    }

    return _miniInfoBadge(
      icon: Icons.hourglass_bottom_rounded,
      text: 'Chưa điểm danh',
      color: Colors.orange,
    );
  }

  Widget _miniInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniActionBadge({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          text,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(_isDark ? 0.18 : 0.10),
          foregroundColor: color,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: color.withOpacity(0.35)),
          ),
        ),
      ),
    );
  }

  Future<void> _showProofDialog({
    required String proofUrl,
    required String proofType,
    required String studentName,
    required DateTime? proofUploadedAt,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final maxDialogHeight = screenHeight * 0.86;
        final maxProofHeight = screenHeight * 0.48;

        return Dialog(
          backgroundColor: _cardColor,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Minh chứng - $studentName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                proofType == 'video'
                                    ? Icons.videocam_rounded
                                    : Icons.image_rounded,
                                color: primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  proofType == 'video'
                                      ? 'Minh chứng video'
                                      : 'Minh chứng hình ảnh',
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (proofUploadedAt != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              'Gửi lúc: ${_formatDate(proofUploadedAt)}',
                              style: TextStyle(
                                color: _subTextColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          proofType == 'video'
                              ? _proofVideoPlaceholder(proofUrl)
                              : _proofImage(
                                  proofUrl,
                                  maxHeight: maxProofHeight,
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
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _proofImage(String proofUrl, {required double maxHeight}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            proofUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: primaryBlue),
                ),
              );
            },
            errorBuilder: (_, __, ___) {
              return Container(
                width: double.infinity,
                height: 220,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_rounded,
                      color: primaryBlue,
                      size: 42,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Không tải được ảnh minh chứng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _proofVideoPlaceholder(String proofUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: primaryBlue,
            size: 54,
          ),
          const SizedBox(height: 10),
          Text(
            'Minh chứng dạng video',
            style: TextStyle(
              color: _textColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hiện tại màn admin hiển thị link video. Nếu cần phát video trực tiếp trong app thì thêm package video_player sau.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _subTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            proofUrl,
            textAlign: TextAlign.center,
            style: TextStyle(color: _subTextColor, fontSize: 11, height: 1.35),
          ),
        ],
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(26),
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
            const SizedBox(height: 6),
            Text(
              message,
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

class _AttendanceFinalizeNotification {
  final String targetUserId;
  final String reason;

  _AttendanceFinalizeNotification({
    required this.targetUserId,
    required this.reason,
  });
}
