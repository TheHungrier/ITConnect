import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/utils/date_helper.dart';
import 'package:ltdd_qlhd_flutter/views/student/my_activity_detail_screen.dart';

import '../../controllers/my_activity_controller.dart';
import '../../models/my_activity_model.dart';
import '../../models/term_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav.dart';
import 'check_in_screen.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  final MyActivityController _controller = MyActivityController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openMyActivityDetailScreen(MyActivityModel activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyActivityDetailScreen(activity: activity),
      ),
    );
  }

  void _openCheckInScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckInScreen()),
    );
  }

  String _emptyTextByTab() {
    if (_controller.tab == 0) {
      return 'Bạn chưa có hoạt động sắp diễn ra trong học kỳ này';
    }

    if (_controller.tab == 1) {
      return 'Bạn chưa có hoạt động chưa hoàn thành trong học kỳ này';
    }

    return 'Bạn chưa có hoạt động đã hoàn thành trong học kỳ này';
  }

  void _showTermPicker(List<TermModel> terms) {
    if (terms.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: AppColors.primary(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chọn học kỳ',
                        style: TextStyle(
                          color: AppColors.title(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...terms.map((term) {
                  final selected = term.id == _controller.selectedTermId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        _controller.changeTerm(term.id);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.iconBox(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary(context).withOpacity(0.35)
                                : AppColors.divider(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                term.name,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.primary(context)
                                      : AppColors.title(context),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary(context),
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          bottomNavigationBar: const BottomNav(currentIndex: 1),
          body: StreamBuilder<List<TermModel>>(
            stream: _controller.getTerms(),
            builder: (context, termSnapshot) {
              if (termSnapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _loadingBox()),
                  ],
                );
              }

              if (termSnapshot.hasError) {
                return Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: _emptyBox('Lỗi tải học kỳ: ${termSnapshot.error}'),
                    ),
                  ],
                );
              }

              final terms = termSnapshot.data ?? [];

              if (terms.isEmpty) {
                return Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: _emptyBox(
                        'Chưa có học kỳ trong hệ thống.\nVui lòng thêm collection terms trên Firestore.',
                      ),
                    ),
                  ],
                );
              }

              _controller.ensureSelectedTerm(terms);

              return StreamBuilder<List<MyActivityModel>>(
                stream: _controller.getMyActivities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      children: [
                        _buildHeader(context),
                        Expanded(child: _loadingBox()),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        _buildHeader(context),
                        Expanded(
                          child: _emptyBox(
                            'Lỗi tải hoạt động: ${snapshot.error}',
                          ),
                        ),
                      ],
                    );
                  }

                  final activities = snapshot.data ?? [];
                  final filteredActivities = _controller.filterActivities(
                    activities,
                  );

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(context)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                          child: _buildPointCard(activities, terms),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                          child: _buildTabsWithTermButton(terms),
                        ),
                      ),
                      if (filteredActivities.isEmpty)
                        SliverToBoxAdapter(child: _emptyBox(_emptyTextByTab()))
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                          sliver: SliverList.separated(
                            itemCount: filteredActivities.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final activity = filteredActivities[index];

                              if (_controller.tab == 0) {
                                return _upcomingCard(activity);
                              }

                              if (_controller.tab == 1) {
                                return _unfinishedCard(activity);
                              }

                              return _completedCard(activity);
                            },
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
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
      child: const Text(
        'Hoạt động của tôi',
        style: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildPointCard(
    List<MyActivityModel> activities,
    List<TermModel> terms,
  ) {
    final trainingPoints = _controller.trainingPoints(activities);
    final rank = _controller.trainingRank(activities);
    final completed = _controller.completedCount(activities);
    final upcoming = _controller.upcomingCount(activities);
    final unfinished = _controller.unfinishedCount(activities);
    final progress = _controller.pointProgress(activities);
    final termName = _controller.selectedTermName(terms);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(context).withOpacity(0.14),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF00A8FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điểm rèn luyện',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        termName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Loại: $rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.10),
                        ),
                        child: Center(
                          child: Text(
                            '$trainingPoints',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              border: Border(
                left: BorderSide(color: AppColors.divider(context)),
                right: BorderSide(color: AppColors.divider(context)),
                bottom: BorderSide(color: AppColors.divider(context)),
              ),
            ),
            child: Row(
              children: [
                _statItem('$completed', 'Hoàn thành'),
                _divider(),
                _statItem('$upcoming', 'Sắp diễn ra'),
                _divider(),
                _statItem('$unfinished', 'Chưa xong'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsWithTermButton(List<TermModel> terms) {
    return Row(
      children: [
        Expanded(child: _buildTabs()),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showTermPicker(terms),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider(context)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow(context),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              color: AppColors.primary(context),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.iconBox(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider(context)),
      ),
      child: Row(
        children: [
          _tabButton('Sắp diễn ra', 0),
          _tabButton('Chưa xong', 1),
          _tabButton('Hoàn thành', 2),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final selected = _controller.tab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _controller.changeTab(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.blueGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary(context).withOpacity(0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.primary(context),
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.primary(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 38, color: AppColors.divider(context));
  }

  Widget _upcomingCard(MyActivityModel activity) {
    return GestureDetector(
      onTap: () {
        _openMyActivityDetailScreen(activity);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: Stack(
                children: [
                  activity.imageUrl.isNotEmpty
                      ? Image.network(
                          activity.imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _activityImageFallback(),
                        )
                      : _activityImageFallback(),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.02),
                            Colors.black.withOpacity(0.34),
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
                    child: _badge(
                      activity.category,
                      AppColors.primary(context),
                      Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _badge(
                      '+${activity.points} điểm',
                      const Color(0xFF00C853),
                      Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.title(context),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 17,
                        color: AppColors.subtitle(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${DateHelper.formatDate(activity.startAt)} - ${DateHelper.formatTime(activity.startAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.subtitle(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: AppColors.subtitle(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.subtitle(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _openCheckInScreen,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: const Text(
                        'Điểm danh',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unfinishedCard(MyActivityModel activity) {
    final status = activity.status;
    final isAbsent = status == 'absent';
    final isPendingReview = status == 'pending_review';
    final penalty = activity.penaltyPoints > 0 ? activity.penaltyPoints : 6;

    final Color statusColor = isAbsent
        ? Colors.redAccent
        : isPendingReview
        ? Colors.orange
        : Colors.orange;

    final Color statusBackground = isAbsent
        ? AppColors.isDark(context)
              ? const Color(0xFF3B1115)
              : const Color(0xFFFFEBEE)
        : AppColors.isDark(context)
        ? const Color(0xFF3B2B10)
        : const Color(0xFFFFF3E0);

    final IconData icon = isAbsent
        ? Icons.cancel_rounded
        : isPendingReview
        ? Icons.pending_actions_rounded
        : Icons.warning_amber_rounded;

    final String label = isAbsent
        ? 'Vắng'
        : isPendingReview
        ? 'Chờ duyệt'
        : 'Chưa xong';

    return GestureDetector(
      onTap: () {
        _openMyActivityDetailScreen(activity);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: statusColor, size: 30),
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
                  const SizedBox(height: 6),
                  Text(
                    '${DateHelper.formatDate(activity.startAt)} • ${activity.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.subtitle(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badge(label, statusBackground, statusColor),
                if (isAbsent) ...[
                  const SizedBox(height: 8),
                  Text(
                    '-$penalty điểm',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _completedCard(MyActivityModel activity) {
    return GestureDetector(
      onTap: () {
        _openMyActivityDetailScreen(activity);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? const Color(0xFF12351F)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 28,
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
                  const SizedBox(height: 6),
                  Text(
                    '${DateHelper.formatDate(activity.startAt)} • ${activity.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.subtitle(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badge(
                  'Đã tham dự',
                  AppColors.isDark(context)
                      ? const Color(0xFF12351F)
                      : const Color(0xFFE8F5E9),
                  Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  '+${activity.points} điểm',
                  style: TextStyle(
                    color: AppColors.primary(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _activityImageFallback() {
    return Container(
      height: 160,
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
          size: 48,
        ),
      ),
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
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
