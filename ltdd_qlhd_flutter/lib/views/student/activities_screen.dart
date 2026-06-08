import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/views/student/activity_detail_screen.dart';
import 'package:ltdd_qlhd_flutter/widgets/app_back_button.dart';

import '../../models/activity_model.dart';
import '../../repositories/activity_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helper.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _activityRepository = ActivityRepository();
  final _searchController = TextEditingController();

  String _keyword = '';
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = const [
    'Tất cả',
    'Đoàn',
    'Workshop',
    'Seminar',
    'Học thuật'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchActivity(ActivityModel activity) {
    final keyword = _keyword.toLowerCase().trim();
    final dateText = DateHelper.formatDate(activity.startAt).toLowerCase();
    final timeText = DateHelper.formatTimeRange(
      activity.startAt,
      activity.endAt,
    ).toLowerCase();

    final matchKeyword =
        keyword.isEmpty ||
        activity.title.toLowerCase().contains(keyword) ||
        activity.category.toLowerCase().contains(keyword) ||
        activity.location.toLowerCase().contains(keyword) ||
        dateText.contains(keyword) ||
        timeText.contains(keyword);

    final matchCategory =
        _selectedCategory == 'Tất cả' ||
        activity.category.toLowerCase() == _selectedCategory.toLowerCase();

    return matchKeyword && matchCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _searchBox(),
                  ),
                ),
                SliverToBoxAdapter(child: _categoryList()),
                StreamBuilder<List<ActivityModel>>(
                  stream: _activityRepository.getAllActivities(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(child: _loadingBox());
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: _emptyBox(
                          'Lỗi tải hoạt động: ${snapshot.error}',
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _emptyBox('Chưa có hoạt động nào'),
                      );
                    }

                    final activities = snapshot.data!
                        .where(_matchActivity)
                        .toList();

                    if (activities.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _emptyBox('Không tìm thấy hoạt động phù hợp'),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      sliver: SliverList.separated(
                        itemCount: activities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _activityCard(context, activities[index]);
                        },
                      ),
                    );
                  },
                ),
              ],
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
              'Tất cả hoạt động',
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

  Widget _searchBox() {
    return Container(
      height: 48,
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
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: AppColors.title(context),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: AppColors.primary(context),
        onChanged: (value) {
          setState(() => _keyword = value.trim());
        },
        decoration: InputDecoration(
          hintText: 'Tìm hoạt động, địa điểm...',
          hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primary(context),
          ),
          suffixIcon: _keyword.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _keyword = '');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.muted(context),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _categoryList() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.blueGradient : null,
                color: selected ? null : AppColors.card(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : AppColors.divider(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? AppColors.primary(context).withOpacity(0.18)
                        : AppColors.shadow(context),
                    blurRadius: selected ? 14 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.primary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _activityCard(BuildContext context, ActivityModel activity) {
    final percent = activity.maxParticipants == 0
        ? 0.0
        : (activity.currentParticipants / activity.maxParticipants).clamp(
            0.0,
            1.0,
          );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityDetailScreen(activity: activity),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(26),
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
                          height: 165,
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
                            Colors.black.withOpacity(0.35),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary(context),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        activity.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card(context).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.divider(context)),
                      ),
                      child: Text(
                        DateHelper.formatDate(activity.startAt),
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                        Icons.access_time_rounded,
                        size: 17,
                        color: AppColors.subtitle(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateHelper.formatTimeRange(
                          activity.startAt,
                          activity.endAt,
                        ),
                        style: TextStyle(
                          color: AppColors.subtitle(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: AppColors.iconBox(context),
                      color: AppColors.primary(context),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${activity.currentParticipants}/${activity.maxParticipants} chỗ đã đăng ký',
                          style: TextStyle(
                            color: AppColors.subtitle(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActivityDetailScreen(activity: activity),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityImageFallback() {
    return Container(
      height: 165,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary(context)),
      ),
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
            ),
          ),
        ),
      ),
    );
  }
}
