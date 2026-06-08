import 'package:flutter/material.dart';

import '../../models/my_activity_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helper.dart';
import '../../widgets/app_back_button.dart';
import 'check_in_screen.dart';

class MyActivityDetailScreen extends StatelessWidget {
  final MyActivityModel activity;

  const MyActivityDetailScreen({Key? key, required this.activity})
    : super(key: key);

  void _openCheckInScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canCheckIn =
        activity.status == 'upcoming' && activity.attended == false;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                children: [
                  _buildImage(context),
                  const SizedBox(height: 16),
                  _buildInfoCard(context),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(context),
                  const SizedBox(height: 16),
                  _buildStatusCard(context),
                  const SizedBox(height: 20),
                  if (canCheckIn) _buildCheckInButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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

  Widget _buildImage(BuildContext context) {
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
                    errorBuilder: (_, __, ___) => _imageFallback(context),
                  )
                : _imageFallback(context),

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

  Widget _imageFallback(BuildContext context) {
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

  Widget _buildInfoCard(BuildContext context) {
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
            context,
            Icons.calendar_month_rounded,
            'Ngày diễn ra',
            DateHelper.formatDate(activity.startAt),
          ),

          _divider(context),

          _infoRow(
            context,
            Icons.access_time_rounded,
            'Thời gian',
            DateHelper.formatTimeRange(activity.startAt, activity.endAt),
          ),

          _divider(context),

          _infoRow(
            context,
            Icons.location_on_outlined,
            'Địa điểm',
            activity.location,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
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

  Widget _buildStatusCard(BuildContext context) {
    final bool completed = activity.status == 'completed';
    final bool attended = activity.attended;

    String text;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (!completed) {
      text = 'Bạn đã đăng ký hoạt động này';
      backgroundColor = AppColors.iconBox(context);
      textColor = AppColors.primary(context);
      icon = Icons.event_available_rounded;
    } else if (attended) {
      text = 'Bạn đã tham dự hoạt động này';
      backgroundColor = AppColors.isDark(context)
          ? const Color(0xFF12351F)
          : const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
    } else {
      text = 'Bạn đã vắng mặt hoạt động này';
      backgroundColor = AppColors.isDark(context)
          ? const Color(0xFF3B1115)
          : const Color(0xFFFFEBEE);
      textColor = Colors.redAccent;
      icon = Icons.cancel_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 23),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _openCheckInScreen(context),
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
        label: const Text(
          'Điểm danh',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
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

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppColors.divider(context)),
    );
  }
}
