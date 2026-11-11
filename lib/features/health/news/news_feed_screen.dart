import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_scalify/flutter_scalify.dart';

import 'package:provider/provider.dart';

import 'package:syriapharmacy/features/health/domain/models/entities/news_model.dart';
import 'package:syriapharmacy/features/health/domain/models/news_model.dart';
import 'news_details.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          isAr ? 'الأخبار' : 'News',
          style: TextStyle(
            fontSize: 20.fz,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'RHZak',
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.newsPosts.isEmpty) {
            return Center(child: Text(isAr ? 'لا توجد أخبار حالياً' : 'No news currently'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Featured News (Main Card)
                _buildMainNewsCard(context, provider.newsPosts[0], primaryColor, isDark),
                
                const SizedBox(height: 16),

                // 2. Secondary News (Two Small Cards)
                if (provider.newsPosts.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildSmallNewsCard(context, provider.newsPosts[1], primaryColor, isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSmallNewsCard(context, provider.newsPosts[2], primaryColor, isDark)),
                    ],
                  )
                else if (provider.newsPosts.length > 1)
                  _buildSmallNewsCard(context, provider.newsPosts[1], primaryColor, isDark),

                // 3. Latest News List (Horizontal Cards)
                if (provider.newsPosts.length > 3) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAr ? 'آخر الأخبار والمقالات' : 'Latest News & Articles',
                        style: TextStyle(
                          fontSize: 16.fz,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'RHZak',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...provider.newsPosts.skip(3).map((item) {
                    return _buildHorizontalNewsCard(context, item, primaryColor, isDark);
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainNewsCard(BuildContext context, NewsModel item, Color primaryColor, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => NewsDetailsScreen(post: item)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200.h,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18.5)),
                child: Hero(
                  tag: 'news_image_${item.id}',
                  child: CachedNetworkImage(
                    imageUrl: item.displayImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AutoSizeText(
                item.displayTitle,
                textAlign: TextAlign.start,
                maxLines: 2,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14.fz,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RHZak',
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSmallNewsCard(BuildContext context, NewsModel item, Color primaryColor, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => NewsDetailsScreen(post: item)),
      ),
      child: Container(
        height: 220.h,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 120.h,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18.5)),
                child: Hero(
                  tag: 'news_image_${item.id}',
                  child: CachedNetworkImage(
                    imageUrl: item.displayImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AutoSizeText(
                  item.displayTitle,
                  textAlign: TextAlign.start,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12.fz,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RHZak',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildHorizontalNewsCard(BuildContext context, NewsModel item, Color primaryColor, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => NewsDetailsScreen(post: item)),
      ),
      child: Container(
        height: 110.h,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withValues(alpha: 0.1), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120.w,
              child: ClipRRect(
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(18.5),
                  bottomStart: Radius.circular(18.5),
                ),
                child: Hero(
                  tag: 'news_image_${item.id}',
                  child: CachedNetworkImage(
                    imageUrl: item.displayImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      item.displayTitle,
                      maxLines: 2,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 13.fz,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'RHZak',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 10.iz, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          item.date.split('T')[0],
                          style: TextStyle(color: Colors.grey, fontSize: 10.fz),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }
}
