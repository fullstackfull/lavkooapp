import 'package:syriapharmacy/localization/language_constrants.dart';
 import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scalify/flutter_scalify.dart';

import 'package:html/parser.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:syriapharmacy/features/health/domain/models/entities/news_model.dart';
class NewsDetailsScreen extends StatelessWidget {
  final NewsModel post;

  const NewsDetailsScreen({super.key, required this.post});

  void _shareNews() {
    final url = post.link;
    final title = post.displayTitle;
    Share.share('$title\n\n$url');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = post.displayTitle;
    final content = post.displayContent;
    final imageUrl = post.displayImageUrl;
    final formattedDate = post.date.split('T')[0];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderImage(context, title, imageUrl),
                  _buildArticleContent(context, isDark, formattedDate, content),
                  _buildActionButtons(context, post.link),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header Image with Hero
  Widget _buildHeaderImage(BuildContext context, String title, String imageUrl) {
    return Stack(
      children: [
        Hero(
          tag: 'news_image_${post.id}',
          child: SizedBox(
            width: double.infinity,
            height: 350.h,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.white,
                padding: EdgeInsets.all(50.w),
                child: const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            20.w,
            MediaQuery.of(context).padding.top + 8.h,
            20.w,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20.iz,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _shareNews(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 20.iz,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              title,
              textAlign: TextAlign.right,
              maxLines: 2,
              style: TextStyle(
                height: 1.4,
                color: Colors.white,
                fontSize: 16.fz,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArticleContent(
    BuildContext context,
    bool isDark,
    String date,
    String content,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontSize: 12.fz,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Use HtmlWidget for professional content rendering
          HtmlWidget(
            content,
            textStyle: TextStyle(
              fontSize: 15.fz,
              height: 1.7,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'RHZak',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String url) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            Icons.share_outlined,
            (getTranslated('share', context) ?? 'share'),
            Theme.of(context).primaryColor,
            () => _shareNews(),
          ),
          _buildActionButton(
            Icons.language,
            (getTranslated('browse', context) ?? 'browse'),
            Theme.of(context).primaryColor,
            () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28.iz, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12.fz, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? '';
  }
}
