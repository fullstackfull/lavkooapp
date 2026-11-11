// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:html/parser.dart' as htmlparser;
// import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
// import 'package:syriapharmacy/utill/app_constants.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class HtmlAboutUsWidget extends StatelessWidget {
//   final String htmlString;
//   final String title;
//
//   const HtmlAboutUsWidget({
//     super.key,
//     required this.htmlString,
//     required this.title,
//   });
//
//   String _extractPlainText(String html) {
//     var document = htmlparser.parse(html);
//     return document.body?.text ?? html;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final splashController =
//         Provider.of<SplashController>(context, listen: false);
//     final companyName =
//         splashController.configModel?.companyName ?? AppConstants.appName;
//     final companyPhone = splashController.configModel?.companyPhone ?? '';
//     final companyEmail = splashController.configModel?.companyEmail ?? '';
//     final websiteUrl = AppConstants.baseUrl;
//
//     final descriptionText = _extractPlainText(htmlString);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const SizedBox(height: 10),
//           // Giant Hero Icon
//           Center(
//             child: Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: theme.primaryColor.withValues(alpha: 0.1),
//               ),
//               child: Icon(
//                 Icons.info_rounded,
//                 color: theme.primaryColor,
//                 size: 60,
//               ),
//             ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
//           ),
//           const SizedBox(height: 16),
//           // Company Title
//           Center(
//             child: Text(
//               companyName.toUpperCase(),
//               textAlign: TextAlign.center,
//               style: theme.textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.w900,
//                 letterSpacing: 1.5,
//                 color: theme.primaryColor,
//               ),
//             ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
//           ),
//           const SizedBox(height: 8),
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: theme.primaryColor.withValues(alpha: 0.5),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ).animate().fadeIn(delay: 400.ms).scaleX(),
//           ),
//           const SizedBox(height: 30),
//
//           // Introduction Box
//           if (descriptionText.trim().isNotEmpty)
//             _buildSection(
//               context,
//               title: "من نحن",
//               content: htmlString,
//               icon: Icons.auto_awesome_rounded,
//               delay: 400,
//             ),
//
//           // Mission & Vision Section
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _buildInfoCard(
//                     context,
//                     title: "الرسالة",
//                     content:
//                         "تقديم تجربة تسوق فريدة وآمنة لعملائنا من خلال توفير منتجات عالية الجودة وخدمات متميزه.",
//                     icon: Icons.track_changes_rounded,
//                     color: Colors.blue,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildInfoCard(
//                     context,
//                     title: "الرؤية",
//                     content:
//                         "أن نكون المنصة الأكثر ثقة واختياراً للتسوق الإلكتروني في المنطقة.",
//                     icon: Icons.visibility_rounded,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ],
//             ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
//           ),
//
//           // Values Section
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(context, "قيمنا"),
//                 const SizedBox(height: 16),
//                 Wrap(
//                   spacing: 12,
//                   runSpacing: 12,
//                   children: [
//                     _buildValueTag(context, "الجودة", Icons.verified_rounded,
//                         Colors.green),
//                     _buildValueTag(context, "الثقة", Icons.handshake_rounded,
//                         Colors.orange),
//                     _buildValueTag(
//                         context, "الخصوصية", Icons.shield_rounded, Colors.blue),
//                     _buildValueTag(
//                         context, "السرعة", Icons.bolt_rounded, Colors.amber),
//                     _buildValueTag(context, "العميل أولاً",
//                         Icons.favorite_rounded, Colors.red),
//                   ],
//                 ).animate().fadeIn(delay: 800.ms),
//               ],
//             ),
//           ),
//
//           // Why Us Table
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(context, "لماذا نحن؟"),
//                 const SizedBox(height: 16),
//                 Container(
//                   clipBehavior: Clip.antiAlias,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: theme.primaryColor.withValues(alpha: 0.1),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.04),
//                         blurRadius: 15,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Table(
//                     columnWidths: const {
//                       0: FlexColumnWidth(1),
//                       1: FlexColumnWidth(1),
//                     },
//                     children: [
//                       TableRow(
//                         decoration: BoxDecoration(
//                           color: theme.primaryColor.withValues(alpha: 0.08),
//                         ),
//                         children: [
//                           _buildTableCell("منصتنا",
//                               isHeader: true, theme: theme),
//                           _buildTableCell("المنصات الأخرى",
//                               isHeader: true, theme: theme),
//                         ],
//                       ),
//                       _buildTableRow("منتجات أصلية ومضمونة 100%",
//                           "احتمالية وجود منتجات مقلدة", theme),
//                       _buildTableRow("دعم فني سريع ومتميز ومتواصل",
//                           "بائعون غير متخصصين أو متأخرين", theme),
//                       _buildTableRow("واجهة متكاملة وسهلة الاستخدام",
//                           "منصات متفرقة وغير منظمة", theme),
//                       _buildTableRow("توصيل سريع وموثوق لكافة المناطق",
//                           "توصيل محدود وبطيء", theme),
//                     ],
//                   ),
//                 ),
//               ],
//             ).animate().fadeIn(delay: 1000.ms),
//           ),
//
//           // Contact Us Section
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(context, "اتصل بنا"),
//                 const SizedBox(height: 16),
//                 if (companyPhone.isNotEmpty)
//                   _buildContactItem(
//                     context,
//                     icon: Icons.phone_android_rounded,
//                     label: "الهاتف",
//                     value: companyPhone,
//                     onTap: () => launchUrl(Uri.parse('tel:$companyPhone')),
//                   ),
//                 if (companyEmail.isNotEmpty)
//                   _buildContactItem(
//                     context,
//                     icon: Icons.email_rounded,
//                     label: "البريد الإلكتروني",
//                     value: companyEmail,
//                     onTap: () => launchUrl(Uri.parse('mailto:$companyEmail')),
//                   ),
//                 _buildContactItem(
//                   context,
//                   icon: Icons.language_rounded,
//                   label: "الموقع الإلكتروني",
//                   value: websiteUrl
//                       .replaceAll('https://', '')
//                       .replaceAll('http://', ''),
//                   onTap: () => launchUrl(Uri.parse(websiteUrl)),
//                 ),
//               ],
//             ).animate().fadeIn(delay: 1200.ms),
//           ),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader(BuildContext context, String title) {
//     return Text(
//       title,
//       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: Theme.of(context).colorScheme.onSurface,
//           ),
//     );
//   }
//
//   Widget _buildSection(
//     BuildContext context, {
//     required String title,
//     required String content,
//     required IconData icon,
//     required int delay,
//   }) {
//     final theme = Theme.of(context);
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20.0),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.04),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: theme.primaryColor, size: 24),
//                 const SizedBox(width: 12),
//                 Text(
//                   title,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             HtmlWidget(
//               content,
//               onTapUrl: (String url) {
//                 return launchUrl(Uri.parse(url),
//                     mode: LaunchMode.externalApplication);
//               },
//               textStyle: theme.textTheme.bodyMedium?.copyWith(
//                 height: 1.6,
//                 color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
//               ),
//             ),
//           ],
//         ),
//       ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.1),
//     );
//   }
//
//   Widget _buildInfoCard(
//     BuildContext context, {
//     required String title,
//     required String content,
//     required IconData icon,
//     required Color color,
//   }) {
//     final theme = Theme.of(context);
//     return Container(
//       height: 180,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.05),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: color.withValues(alpha: 0.1)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 28),
//           const SizedBox(height: 12),
//           Text(
//             title,
//             style: theme.textTheme.titleSmall?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child: Text(
//               content,
//               maxLines: 4,
//               overflow: TextOverflow.ellipsis,
//               style: theme.textTheme.bodySmall?.copyWith(
//                 height: 1.4,
//                 color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildValueTag(
//     BuildContext context,
//     String label,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//         border: Border.all(color: color.withValues(alpha: 0.2)),
//         boxShadow: [
//           BoxShadow(
//             color: color.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 16),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: Theme.of(context)
//                 .textTheme
//                 .bodySmall
//                 ?.copyWith(fontWeight: FontWeight.w600),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTableCell(String text,
//       {bool isHeader = false, required ThemeData theme}) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Text(
//         text,
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//           fontSize: isHeader ? 14 : 13,
//           color: isHeader ? theme.primaryColor : theme.colorScheme.onSurface,
//         ),
//       ),
//     );
//   }
//
//   TableRow _buildTableRow(String col1, String col2, ThemeData theme) {
//     return TableRow(
//       children: [
//         _buildTableCell(col1, theme: theme),
//         _buildTableCell(col2, theme: theme),
//       ],
//     );
//   }
//
//   Widget _buildContactItem(
//     BuildContext context, {
//     required IconData icon,
//     required String label,
//     required String value,
//     required VoidCallback onTap,
//   }) {
//     final theme = Theme.of(context);
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         margin: const EdgeInsets.only(bottom: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: theme.primaryColor.withValues(alpha: 0.05)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.02),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: theme.primaryColor.withValues(alpha: 0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: theme.primaryColor, size: 20),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: Colors.grey,
//                     ),
//                   ),
//                   Text(
//                     value,
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               Icons.open_in_new_rounded,
//               size: 16,
//               color: Colors.grey.withValues(alpha: 0.5),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

class HtmlAboutUsWidget extends StatelessWidget {
  final String htmlString;
  final String title;

  const HtmlAboutUsWidget({
    super.key,
    required this.htmlString,
    required this.title,
  });

  String _extractPlainText(String html) {
    var document = htmlparser.parse(html);
    return document.body?.text ?? html;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final splashController =
    Provider.of<SplashController>(context, listen: false);
    final companyName =
        splashController.configModel?.companyName ?? AppConstants.appName;
    final companyPhone = splashController.configModel?.companyPhone ?? '';
    final companyEmail = splashController.configModel?.companyEmail ?? '';
    final websiteUrl = AppConstants.baseUrl;

    final descriptionText = _extractPlainText(htmlString);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Giant Hero Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.info_rounded,
                color: theme.primaryColor,
                size: 60,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 16),
          // Company Title
          Center(
            child: Text(
              companyName.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.primaryColor,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate().fadeIn(delay: 400.ms).scaleX(),
          ),
          const SizedBox(height: 30),

          // Introduction Box
          if (descriptionText.trim().isNotEmpty)
            _buildSection(
              context,
              title: "من نحن",
              content: htmlString,
              icon: Icons.auto_awesome_rounded,
              delay: 400,
            ),

          // Mission & Vision Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    title: "الرسالة",
                    content:
                    "تقديم تجربة تسوق فريدة وآمنة لعملائنا من خلال توفير منتجات عالية الجودة وخدمات متميزه.",
                    icon: Icons.track_changes_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    title: "الرؤية",
                    content:
                    "أن نكون المنصة الأكثر ثقة واختياراً للتسوق الإلكتروني في المنطقة.",
                    icon: Icons.visibility_rounded,
                    color: Colors.purple,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
          ),

          // Values Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, "قيمنا"),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildValueTag(context, "الجودة", Icons.verified_rounded,
                        Colors.green),
                    _buildValueTag(context, "الثقة", Icons.handshake_rounded,
                        Colors.orange),
                    _buildValueTag(
                        context, "الخصوصية", Icons.shield_rounded, Colors.blue),
                    _buildValueTag(
                        context, "السرعة", Icons.bolt_rounded, Colors.amber),
                    _buildValueTag(context, "العميل أولاً",
                        Icons.favorite_rounded, Colors.red),
                  ],
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),

          // Why Us Table
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, "لماذا نحن؟"),
                const SizedBox(height: 16),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.08),
                        ),
                        children: [
                          _buildTableCell("منصتنا",
                              isHeader: true, theme: theme),
                          _buildTableCell("المنصات الأخرى",
                              isHeader: true, theme: theme),
                        ],
                      ),
                      _buildTableRow("منتجات أصلية ومضمونة 100%",
                          "احتمالية وجود منتجات مقلدة", theme),
                      _buildTableRow("دعم فني سريع ومتميز ومتواصل",
                          "بائعون غير متخصصين أو متأخرين", theme),
                      _buildTableRow("واجهة متكاملة وسهلة الاستخدام",
                          "منصات متفرقة وغير منظمة", theme),
                      _buildTableRow("توصيل سريع وموثوق لكافة المناطق",
                          "توصيل محدود وبطيء", theme),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 1000.ms),
          ),

          // Contact Us Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, "اتصل بنا"),
                const SizedBox(height: 16),
                if (companyPhone.isNotEmpty)
                  _buildContactItem(
                    context,
                    icon: Icons.phone_android_rounded,
                    label: "الهاتف",
                    value: companyPhone,
                    onTap: () => launchUrl(Uri.parse('tel:$companyPhone')),
                  ),
                if (companyEmail.isNotEmpty)
                  _buildContactItem(
                    context,
                    icon: Icons.email_rounded,
                    label: "البريد الإلكتروني",
                    value: companyEmail,
                    onTap: () => launchUrl(Uri.parse('mailto:$companyEmail')),
                  ),
                _buildContactItem(
                  context,
                  icon: Icons.language_rounded,
                  label: "الموقع الإلكتروني",
                  value: websiteUrl
                      .replaceAll('https://', '')
                      .replaceAll('http://', ''),
                  onTap: () => launchUrl(Uri.parse(websiteUrl)),
                ),
              ],
            ).animate().fadeIn(delay: 1200.ms),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required String content,
        required IconData icon,
        required int delay,
      }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            HtmlWidget(
              content,
              onTapUrl: (String url) {
                return launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              },
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.1),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, {
        required String title,
        required String content,
        required IconData icon,
        required Color color,
      }) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueTag(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text,
      {bool isHeader = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
          color: isHeader ? theme.primaryColor : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, ThemeData theme) {
    return TableRow(
      children: [
        _buildTableCell(col1, theme: theme),
        _buildTableCell(col2, theme: theme),
      ],
    );
  }

  Widget _buildContactItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}