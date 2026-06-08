import 'package:flutter/material.dart';

import '../../models/news_model.dart';
import '../../repositories/news_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_back_button.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatelessWidget {
  NewsScreen({Key? key}) : super(key: key);

  final NewsRepository _newsRepository = NewsRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<List<NewsModel>>(
              stream: _newsRepository.getAllNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(context),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _emptyBox(
                    context,
                    'Lỗi tải tin tức: ${snapshot.error}',
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyBox(context, 'Chưa có tin tức nào');
                }

                final news = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  itemCount: news.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _newsFullItem(context, news[index]);
                  },
                );
              },
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
              'Tin tức',
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

  Widget _newsFullItem(BuildContext context, NewsModel news) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: news.isImportant
                ? AppColors.primary(context).withOpacity(0.35)
                : AppColors.divider(context),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _newsImageOrDateBadge(context, news),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      _tag(
                        text: news.category,
                        backgroundColor: AppColors.iconBox(context),
                        textColor: AppColors.primary(context),
                      ),
                      if (news.isImportant)
                        _tag(
                          text: 'Nổi bật',
                          backgroundColor: AppColors.isDark(context)
                              ? const Color(0xFF3A2508)
                              : const Color(0xFFFFF3E0),
                          textColor: const Color(0xFFE65100),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    news.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.subtitle(context),
                      fontSize: 12.8,
                      height: 1.38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.iconBox(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider(context)),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newsImageOrDateBadge(BuildContext context, NewsModel news) {
    if (news.imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          news.imageUrl,
          width: 70,
          height: 78,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _calendarNewsBadge(context, news);
          },
        ),
      );
    }

    return _calendarNewsBadge(context, news);
  }

  Widget _calendarNewsBadge(BuildContext context, NewsModel news) {
    final bool important = news.isImportant;

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
              color: important
                  ? AppColors.primary(context)
                  : AppColors.iconBox(context),
              child: Center(
                child: Text(
                  _getNewsMonth(news.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: important
                        ? Colors.white
                        : AppColors.primary(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Text(
                  _getNewsDay(news.createdAt),
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

  String _getNewsMonth(DateTime? date) {
    if (date == null) return '--';
    return 'TH ${date.month.toString().padLeft(2, '0')}';
  }

  String _getNewsDay(DateTime? date) {
    if (date == null) return '--';
    return date.day.toString().padLeft(2, '0');
  }

  Widget _tag({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyBox(BuildContext context, String text) {
    return Center(
      child: Padding(
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
