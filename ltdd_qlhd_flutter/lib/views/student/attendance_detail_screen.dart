import 'dart:io';

import 'package:flutter/material.dart';

import '../../controllers/attendance_detail_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_back_button.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final String qrRawValue;
  final String activityId;
  final String qrCode;
  final String activityTitle;
  final String activityLocation;
  final String activityTime;
  final String studentName;
  final String studentCode;
  final DateTime checkInTime;

  const AttendanceDetailScreen({
    Key? key,
    required this.qrRawValue,
    required this.activityId,
    required this.qrCode,
    required this.activityTitle,
    required this.activityLocation,
    required this.activityTime,
    required this.studentName,
    required this.studentCode,
    required this.checkInTime,
  }) : super(key: key);

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final AttendanceDetailController _controller = AttendanceDetailController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmCheckIn() async {
    final result = await _controller.confirmCheckIn(
      activityId: widget.activityId,
      qrCode: widget.qrCode,
      qrRawValue: widget.qrRawValue,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );

    if (!result.success) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.studentName.trim().isEmpty
        ? 'Sinh viên'
        : widget.studentName;

    final studentCode = widget.studentCode.trim().isEmpty
        ? 'Chưa cập nhật'
        : widget.studentCode;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(
                    children: [
                      _buildSuccessCard(studentName, studentCode),
                      const SizedBox(height: 18),
                      _buildEvidenceCard(),
                      const SizedBox(height: 20),
                      _buildConfirmButton(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00A8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          AppBackButton(),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chi tiết điểm danh',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(String studentName, String studentCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? const Color(0xFF12351F)
                  : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.isDark(context)
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFC8E6C9),
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 50,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Quét QR thành công',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Thời gian: ${_controller.formatTime(widget.checkInTime)} - ${_controller.formatDate(widget.checkInTime)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _divider(),
          _infoRow(
            icon: Icons.person_rounded,
            title: 'Sinh viên',
            value: studentName,
          ),
          _infoRow(
            icon: Icons.badge_outlined,
            title: 'MSSV',
            value: studentCode,
          ),
          _infoRow(
            icon: Icons.event_note_rounded,
            title: 'Hoạt động',
            value: widget.activityTitle.trim().isEmpty
                ? 'Chưa cập nhật'
                : widget.activityTitle,
          ),
          _infoRow(
            icon: Icons.access_time_rounded,
            title: 'Giờ hoạt động',
            value: widget.activityTime.trim().isEmpty
                ? 'Chưa cập nhật'
                : widget.activityTime,
          ),
          _infoRow(
            icon: Icons.location_on_outlined,
            title: 'Địa điểm',
            value: widget.activityLocation.trim().isEmpty
                ? 'Chưa cập nhật'
                : widget.activityLocation,
          ),
          _divider(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? const Color(0xFF12351F)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.isDark(context)
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFC8E6C9),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
                SizedBox(width: 7),
                Text(
                  'Mã QR đã được quét',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upload_file_rounded,
                color: AppColors.primary(context),
                size: 23,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Minh chứng tham gia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn nên chụp ảnh tại sự kiện. Video chỉ cần dùng khi giảng viên hoặc ban tổ chức yêu cầu.',
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          if (_controller.evidenceFile == null)
            _emptyEvidenceBox()
          else
            _selectedEvidenceBox(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _evidenceButton(
                  icon: Icons.camera_alt_rounded,
                  title: 'Chụp ảnh',
                  onTap: _controller.isSubmitting
                      ? null
                      : _controller.takePhoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _evidenceButton(
                  icon: Icons.videocam_rounded,
                  title: 'Quay video',
                  onTap: _controller.isSubmitting
                      ? null
                      : _controller.recordVideo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _controller.isSubmitting
                  ? null
                  : _controller.chooseFromGallery,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text(
                'Chọn từ thư viện',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary(context),
                side: BorderSide(color: AppColors.divider(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyEvidenceBox() {
    return Container(
      height: 145,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.iconBox(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 44,
            color: AppColors.primary(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có minh chứng',
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thêm ảnh hoặc video để xác nhận',
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedEvidenceBox() {
    final file = _controller.evidenceFile!;
    final fileName = file.name;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider(context)),
      ),
      child: Column(
        children: [
          if (!_controller.isVideo)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.file(
                File(file.path),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.iconBox(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppColors.primary(context),
                  size: 58,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _controller.isVideo
                      ? Icons.video_file_rounded
                      : Icons.image_rounded,
                  color: AppColors.primary(context),
                  size: 23,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.title(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _controller.isSubmitting
                      ? null
                      : _controller.removeEvidence,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFE65100),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidenceButton({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.muted(context),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _controller.isSubmitting ? null : _confirmCheckIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.muted(context),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _controller.isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Đang gửi minh chứng...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ],
              )
            : const Text(
                'Xác nhận điểm danh',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.iconBox(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary(context), size: 19),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.subtitle(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.title(context),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: AppColors.divider(context), height: 1),
    );
  }
}
