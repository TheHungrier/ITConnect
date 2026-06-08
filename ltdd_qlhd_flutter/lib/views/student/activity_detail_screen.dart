import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/widgets/app_back_button.dart';

import '../../controllers/activity_detail_controller.dart';
import '../../models/activity_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helper.dart';

class ActivityDetailScreen extends StatefulWidget {
  final ActivityModel activity;

  const ActivityDetailScreen({Key? key, required this.activity})
    : super(key: key);

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ActivityDetailController _controller = ActivityDetailController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmRegister() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Xác nhận đăng ký',
            style: TextStyle(
              color: AppColors.title(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Bạn có muốn đăng ký tham gia hoạt động "${widget.activity.title}" không?',
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: AppColors.subtitle(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Đăng ký',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final result = await _controller.registerActivity(widget.activity);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );

    if (result.success) {
      setState(() {});
    }
  }

  Future<void> _confirmCancelRegistration() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Hủy đăng ký?',
            style: TextStyle(
              color: AppColors.title(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Bạn có chắc muốn hủy đăng ký hoạt động "${widget.activity.title}" không?',
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Không',
                style: TextStyle(
                  color: AppColors.subtitle(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Hủy đăng ký',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final result = await _controller.cancelRegistration(widget.activity);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );

    if (result.success) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final percent = _controller.getRegisterPercent(activity);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(
                    children: [
                      _buildImage(activity),
                      const SizedBox(height: 16),
                      _buildInfoCard(activity, percent),
                      const SizedBox(height: 16),
                      _buildDescriptionCard(activity),
                      const SizedBox(height: 20),
                      StreamBuilder<Map<String, dynamic>?>(
                        stream: _controller.watchMyRegistration(activity.id),
                        builder: (context, snapshot) {
                          final registrationData = snapshot.data;
                          final isRegistered = registrationData != null;

                          return _buildBottomAction(
                            isRegistered: isRegistered,
                            isFull: _controller.isFull(activity),
                            registrationData: registrationData,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
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
              'Chi tiết hoạt động',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(ActivityModel activity) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            activity.imageUrl.isNotEmpty
                ? Image.network(
                    activity.imageUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  )
                : _imageFallback(),
            Positioned.fill(
              child: Container(
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
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                activity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.isDark(context)
            ? const LinearGradient(
                colors: [Color(0xFF102A43), Color(0xFF1E3A5F)],
              )
            : const LinearGradient(
                colors: [Color(0xFFEAF5FF), Color(0xFFBBDEFB)],
              ),
      ),
      child: Center(
        child: Icon(
          Icons.event_note_rounded,
          color: AppColors.primary(context),
          size: 58,
        ),
      ),
    );
  }

  Widget _buildInfoCard(ActivityModel activity, double percent) {
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
              _badge(
                activity.category,
                AppColors.iconBox(context),
                AppColors.primary(context),
              ),
              const SizedBox(width: 8),
              _badge(
                '+${activity.points} điểm',
                AppColors.isDark(context)
                    ? const Color(0xFF12351F)
                    : const Color(0xFFE8F5E9),
                const Color(0xFF2E7D32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.calendar_month_rounded,
            'Ngày diễn ra',
            DateHelper.formatDate(activity.startAt),
          ),
          _divider(),
          _infoRow(
            Icons.access_time_rounded,
            'Thời gian',
            DateHelper.formatTimeRange(activity.startAt, activity.endAt),
          ),
          _divider(),
          _infoRow(Icons.location_on_outlined, 'Địa điểm', activity.location),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Số lượng đăng ký',
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${activity.currentParticipants}/${activity.maxParticipants}',
                style: TextStyle(
                  color: AppColors.primary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 9,
              backgroundColor: AppColors.iconBox(context),
              color: AppColors.primary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ActivityModel activity) {
    final description = activity.description.trim().isNotEmpty
        ? activity.description.trim()
        : 'Chưa có mô tả chi tiết cho hoạt động này.';

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
          Text(
            'Mô tả hoạt động',
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction({
    required bool isRegistered,
    required bool isFull,
    required Map<String, dynamic>? registrationData,
  }) {
    if (isRegistered) {
      return _buildRegisteredSection(registrationData);
    }

    if (isFull) {
      return _buildFullBox();
    }

    final now = DateTime.now();

    if (!now.isBefore(widget.activity.endAt)) {
      return _buildClosedBox('Hoạt động đã kết thúc');
    }

    if (!now.isBefore(widget.activity.startAt)) {
      return _buildClosedBox('Hoạt động đã bắt đầu, không thể đăng ký');
    }

    return _buildRegisterButton();
  }

  Widget _buildRegisteredSection(Map<String, dynamic>? registrationData) {
    final canCancel = _controller.canCancelRegistration(
      activity: widget.activity,
      registrationData: registrationData,
    );

    final message = _controller.getRegistrationMessage(
      activity: widget.activity,
      registrationData: registrationData,
    );

    final status = registrationData?['status']?.toString() ?? '';
    final attended = registrationData?['attended'] == true;
    final isAbsent = status == 'absent';
    final isCompleted = status == 'completed' || attended;

    final Color statusColor = isAbsent
        ? Colors.red
        : isCompleted
        ? const Color(0xFF2E7D32)
        : const Color(0xFF2E7D32);

    final Color backgroundColor = isAbsent
        ? AppColors.isDark(context)
              ? const Color(0xFF3B1115)
              : const Color(0xFFFFEBEE)
        : AppColors.isDark(context)
        ? const Color(0xFF12351F)
        : const Color(0xFFE8F5E9);

    final Color borderColor = isAbsent
        ? AppColors.isDark(context)
              ? const Color(0xFF7F1D1D)
              : const Color(0xFFFFCDD2)
        : AppColors.isDark(context)
        ? const Color(0xFF1B5E20)
        : const Color(0xFFC8E6C9);

    final IconData icon = isAbsent
        ? Icons.cancel_rounded
        : isCompleted
        ? Icons.verified_rounded
        : Icons.check_circle_rounded;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: statusColor, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (canCancel) ...[
          const SizedBox(height: 12),
          _buildCancelRegistrationButton(),
        ],
      ],
    );
  }

  Widget _buildCancelRegistrationButton() {
    final isLoading = _controller.isLoading;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isLoading
            ? null
            : const LinearGradient(
                colors: [Color(0xFFC62828), Color(0xFFE53935)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isLoading
            ? AppColors.isDark(context)
                  ? const Color(0xFF3B1115)
                  : const Color(0xFFFFCDD2)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFE53935,
            ).withOpacity(AppColors.isDark(context) ? 0.18 : 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _confirmCancelRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Hủy đăng ký',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }

  Widget _buildClosedBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? const Color(0xFF3B1115)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.isDark(context)
              ? const Color(0xFF7F1D1D)
              : const Color(0xFFFFCDD2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? const Color(0xFF3B1115)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.isDark(context)
              ? const Color(0xFF7F1D1D)
              : const Color(0xFFFFCDD2),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_rounded, color: Colors.redAccent, size: 22),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Hoạt động đã đủ số lượng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    final isLoading = _controller.isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _confirmRegister,
        icon: isLoading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.3,
                ),
              )
            : const Icon(Icons.how_to_reg_rounded),
        label: Text(
          isLoading ? 'Đang đăng ký...' : 'Đăng ký tham gia',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.muted(context),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
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
                maxLines: 2,
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

  Widget _badge(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppColors.divider(context)),
    );
  }
}
