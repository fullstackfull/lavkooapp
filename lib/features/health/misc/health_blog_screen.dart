import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


class HealthBlogScreen extends StatelessWidget {
  const HealthBlogScreen({super.key});

  static List<Map<String, String>> _getArticles(bool isAr) => [
    {
      'title': isAr ? 'أهمية شرب المياه في الصيف' : 'Importance of Hydration in Summer',
      'summary': isAr ? 'اكتشف أفضل الأطعمة التي تساعد في تقوية عضلة القلب وتقليل الكوليسترول...' : 'Discover the best foods that help strengthen the heart muscle and reduce cholesterol...',
      'image': 'https://images.unsplash.com/photo-1544145945-f904253d0c7e?w=800',
      'category': isAr ? 'تغذية' : 'Nutrition',
      'readTime': isAr ? '٥ دقائق' : '5 min'
    },
    {
      'title': isAr ? 'كيف تقوي مناعتك في الشتاء؟' : 'How to Boost Immunity in Winter?',
      'summary': isAr ? 'خطوات بسيطة وعملية لتقليل التوتر ومستويات الضغط في حياتك الشخصية والمهنية...' : 'Simple and practical steps to reduce anxiety and stress levels in your professional and personal life...',
      'image': 'https://images.unsplash.com/photo-1512438248408-106ea96289af?w=800',
      'category': isAr ? 'وقاية' : 'Prevention',
      'readTime': isAr ? '٧ دقائق' : '7 min'
    },
    {
      'title': isAr ? 'فوائد الرياضة الصباحية' : 'Benefits of Morning Exercise',
      'summary': isAr ? 'لماذا يعتبر الماء العنصر الأهم في رحلة إنقاص الوزن وتحسين صحة البشرة...' : 'Why water is considered the most important element in the weight loss journey and improving skin health...',
      'image': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
      'category': isAr ? 'عام' : 'General',
      'readTime': isAr ? '٤ دقائق' : '4 min'
    }
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final articles = _getArticles(isAr);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.lightBlue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (getTranslated('blog', context) ?? 'blog'),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return GestureDetector(
                    onTap: () {
                      // Future: Navigate to full article
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 25),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(
                              article['image']!, 
                              height: 180, 
                              width: double.infinity, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 180,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.lightBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text(article['category']!, style: const TextStyle(color: Colors.lightBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    Text(article['readTime']!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(article['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(article['summary']!, style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 150).ms).slideY(begin: 0.1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
