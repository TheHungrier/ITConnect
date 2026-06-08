import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/widgets/app_back_button.dart';

import '../../models/news_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helper.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsModel news;

  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final summary = news.summary.trim();
    final detailContent = news.content.trim();

    final bool hasDetailContent =
        detailContent.isNotEmpty && detailContent != summary;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.divider(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow(context),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (news.imageUrl.trim().isNotEmpty) _buildImage(context),

                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
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

                          const SizedBox(height: 14),

                          Text(
                            news.title,
                            style: TextStyle(
                              color: AppColors.title(context),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.32,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: AppColors.subtitle(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatNewsDate(news.createdAt),
                                style: TextStyle(
                                  color: AppColors.subtitle(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          if (summary.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.isDark(context)
                                    ? const Color(0xFF101B2D)
                                    : const Color(0xFFF4F8FF),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.divider(context),
                                ),
                              ),
                              child: Text(
                                summary,
                                style: TextStyle(
                                  color: AppColors.isDark(context)
                                      ? const Color(0xFFD5E3F5)
                                      : const Color(0xFF38516F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],

                          if (hasDetailContent) ...[
                            const SizedBox(height: 18),
                            Text(
                              'Nội dung chi tiết',
                              style: TextStyle(
                                color: AppColors.title(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              detailContent,
                              style: TextStyle(
                                color: AppColors.isDark(context)
                                    ? const Color(0xFFD5E3F5)
                                    : const Color(0xFF263B55),
                                fontSize: 15,
                                height: 1.65,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: Image.network(
        news.imageUrl,
        height: 210,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 170,
            width: double.infinity,
            color: AppColors.iconBox(context),
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.primary(context),
              size: 42,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              'Thông tin chi tiết',
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

  String _formatNewsDate(DateTime? date) {
    if (date == null) return 'Chưa rõ ngày';
    return DateHelper.formatDate(date);
  }

  Widget _tag({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
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
}
