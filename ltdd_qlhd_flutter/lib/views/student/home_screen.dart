import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/views/student/campus_map_screen.dart';
import 'package:ltdd_qlhd_flutter/views/student/chatbot_screen.dart';
import 'package:ltdd_qlhd_flutter/views/student/feedback_screen.dart';
import 'package:ltdd_qlhd_flutter/views/student/reminder_screen.dart';

import '../../controllers/home_controller.dart';
import '../../models/activity_model.dart';
import '../../models/news_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helper.dart';
import '../../widgets/bottom_nav.dart';

import 'activities_screen.dart';
import 'activity_detail_screen.dart';
import 'news_detail_screen.dart';
import 'news_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _homeController = HomeController();

  final PageController _newsPageController = PageController();

  late final Future<dynamic> _currentUserFuture;

  Timer? _newsTimer;
  int _currentNewsPage = 0;
  int _latestNewsLength = 0;
  bool _newsSlideForward = true;

  @override
  void initState() {
    super.initState();

    _currentUserFuture = _homeController.getCurrentUserData();

    _newsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_latestNewsLength <= 1) return;
      if (!_newsPageController.hasClients) return;

      int nextPage;

      if (_newsSlideForward) {
        if (_currentNewsPage >= _latestNewsLength - 1) {
          _newsSlideForward = false;
          nextPage = _currentNewsPage - 1;
        } else {
          nextPage = _currentNewsPage + 1;
        }
      } else {
        if (_currentNewsPage <= 0) {
          _newsSlideForward = true;
          nextPage = _currentNewsPage + 1;
        } else {
          nextPage = _currentNewsPage - 1;
        }
      }

      _newsPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    _newsPageController.dispose();
    super.dispose();
  }

  void _openChatbotScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
    );
  }

  void _openNotificationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  void _openFeedbackScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  void _openCampusMapScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CampusMapScreen()),
    );
  }

  void _openReminderScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReminderScreen()),
    );
  }

  void _openNewsScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => NewsScreen()));
  }

  void _openActivitiesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
    );
  }

  void _openActivityDetailScreen(ActivityModel activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activity: activity),
      ),
    );
  }

  void _openNewsDetailScreen(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
      body: FutureBuilder(
        future: _currentUserFuture,
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          final fullName = user?.name ?? 'Sinh viên';
          final name = _homeController.getShortName(fullName);
          final avatarUrl = _homeController.getAvatarUrl(user);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, name, avatarUrl)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: _sectionTitle(
                    title: 'Tin tức',
                    actionText: 'Xem tất cả',
                    onTap: _openNewsScreen,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: StreamBuilder<List<NewsModel>>(
                  stream: _homeController.getLatestNews(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _loadingBox();
                    }

                    if (snapshot.hasError) {
                      return _emptyBox('Lỗi tải tin tức: ${snapshot.error}');
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _emptyBox('Chưa có tin tức mới');
                    }

                    final news = snapshot.data!;
                    _latestNewsLength = news.length;

                    if (_currentNewsPage >= _latestNewsLength) {
                      _currentNewsPage = 0;
                      _newsSlideForward = true;
                    }

                    return _newsSlider(news);
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: _sectionTitle(
                    title: 'Tiện ích',
                    actionText: '',
                    onTap: () {},
                  ),
                ),
              ),

              SliverToBoxAdapter(child: _utilitySection(context)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: _sectionTitle(
                    title: 'Hoạt động mới nhất',
                    actionText: 'Xem tất cả',
                    onTap: _openActivitiesScreen,
                  ),
                ),
              ),

              StreamBuilder<List<ActivityModel>>(
                stream: _homeController.getLatestActivities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(child: _loadingBox());
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: _emptyBox('Lỗi tải hoạt động: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _emptyBox('Chưa có hoạt động nào'),
                    );
                  }

                  final activities = snapshot.data!.take(5).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String avatarUrl) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.4,
              ),
            ),
            child: CircleAvatar(
              radius: 23,
              backgroundColor: Colors.white.withOpacity(0.18),
              foregroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          StreamBuilder(
            stream: _homeController.getNotifications(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final hasUnread = _homeController.hasUnreadNotification(
                notifications,
              );

              return _notificationIcon(
                onTap: _openNotificationScreen,
                hasUnread: hasUnread,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _notificationIcon({
    required VoidCallback onTap,
    required bool hasUnread,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          if (hasUnread)
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _newsSlider(List<NewsModel> news) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: SizedBox(
        height: 142,
        child: PageView.builder(
          controller: _newsPageController,
          scrollDirection: Axis.vertical,
          itemCount: news.length,
          onPageChanged: (index) {
            _currentNewsPage = index;
          },
          itemBuilder: (context, index) {
            return _newsSliderItem(context, news[index]);
          },
        ),
      ),
    );
  }

  Widget _newsSliderItem(BuildContext context, NewsModel news) {
    return GestureDetector(
      onTap: () {
        _openNewsDetailScreen(news);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: news.isImportant
                ? AppColors.primary(context).withOpacity(0.35)
                : AppColors.divider(context),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _calendarNewsBadge(news),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.iconBox(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          news.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primary(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      if (news.isImportant)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.isDark(context)
                                ? const Color(0xFF3A2508)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Nổi bật',
                            style: TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.title(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.28,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    news.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.subtitle(context),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.iconBox(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider(context)),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.primary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarNewsBadge(NewsModel news) {
    final bool important = news.isImportant;

    if (news.imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          news.imageUrl,
          width: 70,
          height: 78,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _newsDateBadge(news, important);
          },
        ),
      );
    }

    return _newsDateBadge(news, important);
  }

  Widget _newsDateBadge(NewsModel news, bool important) {
    return Container(
      width: 58,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: important
              ? AppColors.primary(context).withOpacity(0.35)
              : AppColors.divider(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: important
                    ? AppColors.primary(context)
                    : AppColors.iconBox(context),
              ),
              child: Center(
                child: Text(
                  DateHelper.getNullableMonth(news.createdAt),
                  style: TextStyle(
                    color: important
                        ? Colors.white
                        : AppColors.primary(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateHelper.getNullableDay(news.createdAt),
                  style: TextStyle(
                    color: AppColors.primary(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _utilitySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(24),
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
            Expanded(
              child: _utilityItem(
                icon: Icons.calendar_month_rounded,
                title: 'Nhắc nhở',
                onTap: () {
                  _openReminderScreen();
                },
              ),
            ),
            Expanded(
              child: _utilityItem(
                icon: Icons.map_rounded,
                title: 'Bản đồ',
                onTap: () {
                  _openCampusMapScreen();
                },
              ),
            ),
            Expanded(
              child: _utilityItem(
                icon: Icons.smart_toy_rounded,
                title: 'Chatbot',
                onTap: () {
                  _openChatbotScreen();
                },
              ),
            ),
            Expanded(
              child: _utilityItem(
                icon: Icons.rate_review_rounded,
                title: 'Góp ý',
                onTap: () {
                  _openFeedbackScreen();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _utilityItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.blueGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        if (actionText.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: TextStyle(
                color: AppColors.primary(context),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _activityCard(BuildContext context, ActivityModel activity) {
    final percent = _homeController.getActivityPercent(activity);

    return GestureDetector(
      onTap: () {
        _openActivityDetailScreen(activity);
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
                          _openActivityDetailScreen(activity);
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
