import 'package:flutter/material.dart';

import '../../controllers/reminder_controller.dart';
import '../../models/my_activity_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_back_button.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ReminderController _controller = ReminderController();

  @override
  void initState() {
    super.initState();
    _controller.loadSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(ReminderActionResult result) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StreamBuilder<List<MyActivityModel>>(
                  stream: _controller.getMyActivities(),
                  builder: (context, snapshot) {
                    if (_controller.isLoading ||
                        snapshot.connectionState == ConnectionState.waiting) {
                      return _loadingBox();
                    }

                    if (snapshot.hasError) {
                      return _emptyBox('Lỗi tải hoạt động: ${snapshot.error}');
                    }

                    final activities = snapshot.data ?? [];
                    final upcomingActivities = _controller
                        .filterUpcomingActivities(activities);

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                            child: _buildSettingCard(activities),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                            child: _sectionTitle(
                              'Hoạt động sắp diễn ra',
                              '${upcomingActivities.length} hoạt động',
                            ),
                          ),
                        ),

                        if (upcomingActivities.isEmpty)
                          SliverToBoxAdapter(
                            child: _emptyBox(
                              'Bạn chưa có hoạt động sắp diễn ra để nhắc nhở',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                            sliver: SliverList.separated(
                              itemCount: upcomingActivities.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _activityReminderCard(
                                  upcomingActivities[index],
                                );
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
        );
      },
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
              'Nhắc nhở',
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

  Widget _buildSettingCard(List<MyActivityModel> activities) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.blueGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhắc nhở hoạt động',
                      style: TextStyle(
                        color: AppColors.title(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _controller.isReminderEnabled
                          ? 'Đang bật thông báo nhắc lịch'
                          : 'Đang tắt thông báo nhắc lịch',
                      style: TextStyle(
                        color: AppColors.subtitle(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: _controller.isReminderEnabled,
                activeColor: AppColors.primary(context),
                onChanged: (value) async {
                  final result = await _controller.setReminderEnabled(
                    value,
                    activities,
                  );
                  _showMessage(result);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nhắc trước',
              style: TextStyle(
                color: AppColors.title(context),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 10),

          _buildReminderOptions(activities),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _controller.isReminderEnabled
                  ? () async {
                      final result = await _controller.syncReminders(
                        activities,
                      );
                      _showMessage(result);
                    }
                  : null,
              icon: const Icon(Icons.sync_rounded),
              label: const Text(
                'Đồng bộ nhắc nhở',
                style: TextStyle(fontWeight: FontWeight.w900),
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
          ),
        ],
      ),
    );
  }

  Widget _buildReminderOptions(List<MyActivityModel> activities) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: _controller.reminderOptions.map((minutes) {
        final selected = minutes == _controller.minutesBefore;

        return GestureDetector(
          onTap: !_controller.isReminderEnabled
              ? null
              : () async {
                  final result = await _controller.changeMinutesBefore(
                    minutes,
                    activities,
                  );
                  _showMessage(result);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.blueGradient : null,
              color: selected ? null : AppColors.iconBox(context),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.divider(context),
              ),
            ),
            child: Text(
              _controller.reminderOptionText(minutes),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.primary(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.subtitle(context),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _activityReminderCard(MyActivityModel activity) {
    final reminderAt = _controller.reminderTime(activity);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.iconBox(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary(context),
                  size: 27,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.title(context),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_controller.formatTime(activity.startAt)} - ${_controller.formatDate(activity.startAt)}',
                      style: TextStyle(
                        color: AppColors.subtitle(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _infoRow(
            icon: Icons.location_on_outlined,
            text: activity.location.isEmpty
                ? 'Chưa cập nhật địa điểm'
                : activity.location,
          ),

          const SizedBox(height: 7),

          _infoRow(
            icon: Icons.notifications_active_outlined,
            text:
                'Nhắc lúc ${_controller.formatTime(reminderAt)} - ${_controller.formatDate(reminderAt)}',
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await _controller.cancelOne(activity);
                    _showMessage(result);
                  },
                  icon: const Icon(Icons.notifications_off_rounded),
                  label: const Text(
                    'Hủy nhắc',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: AppColors.divider(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _controller.isReminderEnabled
                      ? () async {
                          final result = await _controller.scheduleOne(
                            activity,
                          );
                          _showMessage(result);
                        }
                      : null,
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text(
                    'Tạo lại',
                    style: TextStyle(fontWeight: FontWeight.w900),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.subtitle(context), size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingBox() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.primary(context)),
    );
  }

  Widget _emptyBox(String text) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider(context)),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
