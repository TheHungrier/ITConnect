import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/utils/date_helper.dart';

import '../../controllers/calendar_controller.dart';
import '../../models/activity_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarController _controller = CalendarController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          bottomNavigationBar: const BottomNav(currentIndex: 3),
          body: StreamBuilder<List<ActivityModel>>(
            stream: _controller.getAllActivities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary(context),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Lỗi tải lịch hoạt động: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.subtitle(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final activities = snapshot.data ?? [];
              final selectedActivities = _controller.activitiesOfDay(
                activities,
                _controller.selectedDate,
              );

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildViewModeSelector()),
                  SliverToBoxAdapter(child: _buildCalendarBody(activities)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hoạt động ngày ${_controller.dayTitle(_controller.selectedDate)}',
                              style: TextStyle(
                                color: AppColors.title(context),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${selectedActivities.length} hoạt động',
                            style: TextStyle(
                              color: AppColors.primary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedActivities.isEmpty)
                    SliverToBoxAdapter(
                      child: _emptyBox('Không có hoạt động trong ngày này'),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      sliver: SliverList.separated(
                        itemCount: selectedActivities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _activityItem(selectedActivities[index]);
                        },
                      ),
                    ),
                ],
              );
            },
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
      child: const Text(
        'Lịch hoạt động',
        style: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _modeButton('day', 'Ngày'),
            _modeButton('week', 'Tuần'),
            _modeButton('month', 'Tháng'),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String value, String title) {
    final selected = _controller.viewMode == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _controller.changeViewMode(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 42,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.subtitle(context),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarBody(List<ActivityModel> activities) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            _calendarHeader(),
            const SizedBox(height: 16),
            if (_controller.viewMode == 'day') _dayView(activities),
            if (_controller.viewMode == 'week') _weekView(activities),
            if (_controller.viewMode == 'month') _monthView(activities),
          ],
        ),
      ),
    );
  }

  Widget _calendarHeader() {
    return Row(
      children: [
        _circleButton(
          icon: Icons.chevron_left_rounded,
          onTap: _controller.previous,
        ),
        Expanded(
          child: Text(
            _controller.headerTitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _circleButton(
          icon: Icons.chevron_right_rounded,
          onTap: _controller.next,
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.iconBox(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider(context)),
        ),
        child: Icon(icon, color: AppColors.primary(context), size: 24),
      ),
    );
  }

  Widget _dayView(List<ActivityModel> activities) {
    final count = _controller
        .activitiesOfDay(activities, _controller.selectedDate)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.iconBox(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider(context)),
      ),
      child: Column(
        children: [
          Text(
            '${_controller.selectedDate.day}',
            style: TextStyle(
              color: AppColors.primary(context),
              fontSize: 44,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tháng ${_controller.selectedDate.month}, ${_controller.selectedDate.year}',
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count hoạt động trong ngày',
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekView(List<ActivityModel> activities) {
    final days = _controller.daysOfCurrentWeek();
    const weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Row(
      children: List.generate(days.length, (index) {
        final day = days[index];
        final selected = _controller.isSameDay(day, _controller.selectedDate);
        final count = _controller.activitiesOfDay(activities, day).length;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              _controller.selectDate(day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary(context)
                    : AppColors.iconBox(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppColors.primary(context)
                      : AppColors.divider(context),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    weekLabels[index],
                    style: TextStyle(
                      color: selected
                          ? Colors.white70
                          : AppColors.subtitle(context),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.title(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.card(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Colors.white.withOpacity(0.20)
                            : AppColors.divider(context),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.primary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _monthView(List<ActivityModel> activities) {
    final days = _controller.daysOfCurrentMonth();
    const weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      children: [
        Row(
          children: weekLabels.map((label) {
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.subtitle(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final inMonth = day.month == _controller.selectedDate.month;
            final selected = _controller.isSameDay(
              day,
              _controller.selectedDate,
            );
            final today = _controller.isSameDay(day, DateTime.now());
            final count = _controller.activitiesOfDay(activities, day).length;

            return GestureDetector(
              onTap: () {
                _controller.selectDate(day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary(context)
                      : today
                      ? AppColors.iconBox(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary(context)
                        : today
                        ? AppColors.divider(context)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : inMonth
                            ? AppColors.title(context)
                            : AppColors.muted(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (count > 0)
                      Container(
                        width: count >= 2 ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : AppColors.primary(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      )
                    else
                      const SizedBox(height: 7),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${_controller.activitiesOfMonth(activities, _controller.selectedDate).length} hoạt động trong tháng này',
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityItem(ActivityModel activity) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.blueGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppColors.subtitle(context),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      DateHelper.formatTimeRange(
                        activity.startAt,
                        activity.endAt,
                      ),
                      style: TextStyle(
                        color: AppColors.subtitle(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.subtitle(context),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        activity.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.subtitle(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.iconBox(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              activity.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primary(context),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
