// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:html/parser.dart' as htmlparser;
// import 'package:html/dom.dart' as dom;
//
//
// class PolicySection {
//   final String title;
//   final List<Widget> contentWidgets;
//
//   PolicySection({required this.title, required this.contentWidgets});
// }
//
// class HtmlPolicyWidget extends StatelessWidget {
//   final String htmlString;
//   final String title;
//
//   const HtmlPolicyWidget({super.key, required this.htmlString, this.title = ''});
//
//   String _extractPlainText(String html) {
//     var document = htmlparser.parse(html);
//     return document.body?.text ?? html;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final sections = _parseHtmlToSections(htmlString, theme);
//
//     if (sections.isEmpty) {
//       // Fallback if no sections were parsed
//       return _buildParagraph(theme, _extractPlainText(htmlString));
//     }
//
//     // Extract the introduction (if text exists before the first header)
//     Widget introWidget = const SizedBox();
//     List<PolicySection> accordionSections = [];
//
//     if (sections.isNotEmpty && sections.first.title == 'معلومات') {
//       introWidget = _buildIntroduction(theme, sections.first.contentWidgets);
//       accordionSections = sections.sublist(1);
//     } else {
//       accordionSections = sections;
//     }
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const SizedBox(height: 10),
//           _buildHeroIcon(theme, Icons.privacy_tip_rounded),
//           const SizedBox(height: 20),
//
//           if (title.isNotEmpty)
//             Center(
//               child: Text(
//                 title,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w900,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//           const SizedBox(height: 30),
//
//           introWidget,
//
//           ListView.builder(
//           physics: const NeverScrollableScrollPhysics(),
//           shrinkWrap: true,
//           itemCount: accordionSections.length,
//           itemBuilder: (context, index) {
//             return _buildAccordionSection(
//               theme,
//               title: accordionSections[index].title,
//               icon: _getIconForIndex(index),
//               children: accordionSections[index].contentWidgets,
//               index: index,
//             );
//           },
//         ),
//       ],
//     ),
//   );
// }
//
//   Widget _buildHeroIcon(ThemeData theme, IconData icon) {
//     return Center(
//       child: Container(
//         width: 80,
//         height: 80,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               theme.primaryColor,
//               theme.primaryColor.withValues(alpha: 0.7),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: theme.primaryColor.withValues(alpha: 0.3),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Icon(icon, color: Colors.white, size: 40),
//       ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
//     );
//   }
//
//   Widget _buildIntroduction(ThemeData theme, List<Widget> children) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: theme.primaryColor.withValues(alpha: 0.03),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: children,
//       ),
//     ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
//   }
//
//   IconData _getIconForIndex(int index) {
//     final icons = [
//       Icons.verified_user_rounded,
//       Icons.shield_rounded,
//       Icons.security_rounded,
//       Icons.description_rounded,
//       Icons.policy_rounded,
//       Icons.local_police_rounded,
//       Icons.privacy_tip_rounded,
//     ];
//     return icons[index % icons.length];
//   }
//
//   String cleanText(String text) {
//     return text.replaceAll('\u00A0', ' ').replaceAll('&nbsp;', ' ').trim();
//   }
//
//   List<PolicySection> _parseHtmlToSections(String html, ThemeData theme) {
//     dom.Document document = htmlparser.parse(html);
//     List<PolicySection> sections = [];
//
//     String currentTitle = '';
//     List<Widget> currentWidgets = [];
//
//     void addCurrentSection() {
//       if (currentTitle.isNotEmpty || currentWidgets.isNotEmpty) {
//         sections.add(PolicySection(
//           title: currentTitle.isNotEmpty ? currentTitle : 'معلومات',
//           contentWidgets: List.from(currentWidgets),
//         ));
//       }
//       currentTitle = '';
//       currentWidgets = [];
//     }
//
//     var elements = document.body?.children ?? [];
//
//     // If there is only one element or no headers at all, treat it differently
//     bool hasHeaders = elements.any((el) {
//       if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(el.localName)) return true;
//       if (el.localName == 'p') {
//         var boldElements = el.querySelectorAll('strong, b');
//         if (boldElements.isNotEmpty) {
//           final cleanElText = cleanText(el.text);
//           final cleanBoldText = cleanText(boldElements.first.text ?? '');
//           return cleanBoldText.length >= cleanElText.length * 0.7 &&
//                  cleanElText.length < 60 &&
//                  !cleanElText.endsWith(':');
//         }
//       }
//       return false;
//     });
//
//     if (!hasHeaders) {
//        for (var element in elements) {
//          if (element.localName == 'ul' || element.localName == 'ol') {
//             for (var li in element.children) {
//               if (li.localName == 'li') {
//                  currentWidgets.add(_buildBulletPoint(theme, li.text));
//               }
//             }
//          } else if (element.localName == 'table') {
//             // Very simple table parsing
//             for (var tr in element.querySelectorAll('tr')) {
//                var tds = tr.querySelectorAll('td, th');
//                if (tds.length >= 2) {
//                  currentWidgets.add(_buildTableRow(theme, tds[0].text, tds[1].text));
//                } else if (tds.isNotEmpty) {
//                  currentWidgets.add(_buildParagraph(theme, tds[0].text));
//                }
//             }
//          } else {
//             if (element.text.trim().isNotEmpty) {
//                currentWidgets.add(_buildParagraph(theme, element.text));
//             }
//          }
//        }
//        addCurrentSection();
//        return sections;
//     }
//
//     for (var element in elements) {
//       String tagName = element.localName ?? '';
//
//       bool isHeader = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(tagName);
//
//       if (!isHeader && tagName == 'p') {
//         var boldElements = element.querySelectorAll('strong, b');
//         if (boldElements.isNotEmpty) {
//           final cleanElText = cleanText(element.text);
//           final cleanBoldText = cleanText(boldElements.first.text ?? '');
//           isHeader = cleanBoldText.length >= cleanElText.length * 0.7 &&
//                      cleanElText.length < 60 &&
//                      !cleanElText.endsWith(':');
//         }
//       }
//
//       if (isHeader) {
//         addCurrentSection();
//         currentTitle = cleanText(element.text);
//
//       } else if (tagName == 'ul' || tagName == 'ol') {
//         for (var li in element.children) {
//           if (li.localName == 'li') {
//             currentWidgets.add(_buildBulletPoint(theme, li.text));
//           }
//         }
//       } else if (tagName == 'table') {
//         for (var tr in element.querySelectorAll('tr')) {
//            var tds = tr.querySelectorAll('td, th');
//            if (tds.length >= 2) {
//              currentWidgets.add(_buildTableRow(theme, tds[0].text, tds[1].text));
//            } else if (tds.isNotEmpty) {
//              currentWidgets.add(_buildParagraph(theme, tds[0].text));
//            }
//         }
//       } else {
//         if (element.text.trim().isNotEmpty) {
//           currentWidgets.add(_buildParagraph(theme, element.text));
//         }
//       }
//     }
//
//     addCurrentSection();
//     return sections;
//   }
//
//   Widget _buildAccordionSection(
//     ThemeData theme, {
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//     required int index,
//   }) {
//     if (children.isEmpty) return const SizedBox();
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white, // Explicitly white as requested
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 6),
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: Theme(
//           data: theme.copyWith(dividerColor: Colors.transparent),
//           child: ExpansionTile(
//             tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//             leading: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: theme.primaryColor.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: theme.primaryColor, size: 22),
//             ),
//             title: Text(
//               title,
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//               ),
//             ),
//             iconColor: theme.primaryColor,
//             collapsedIconColor: theme.colorScheme.onSurface.withValues(
//               alpha: 0.5,
//             ),
//             childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//             expandedCrossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Divider(height: 1),
//               const SizedBox(height: 15),
//               ...children,
//             ],
//           ),
//         ),
//       ),
//     ).animate().fadeIn(duration: 600.ms, delay: (index * 100).ms).slideX(begin: 0.1, end: 0, delay: (index * 100).ms);
//   }
//
//   Widget _buildParagraph(ThemeData theme, String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Text(
//         text,
//         style: theme.textTheme.bodyMedium?.copyWith(
//           height: 1.6,
//           color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBulletPoint(ThemeData theme, String text) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: Container(
//               width: 5,
//               height: 5,
//               decoration: BoxDecoration(
//                 color: theme.primaryColor,
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 height: 1.6,
//                 color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTableRow(ThemeData theme, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:html/dom.dart' as dom;


class PolicySection {
  final String title;
  final List<Widget> contentWidgets;

  PolicySection({required this.title, required this.contentWidgets});
}

class HtmlPolicyWidget extends StatelessWidget {
  final String htmlString;
  final String title;

  const HtmlPolicyWidget({super.key, required this.htmlString, this.title = ''});

  String _extractPlainText(String html) {
    var document = htmlparser.parse(html);
    return document.body?.text ?? html;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = _parseHtmlToSections(htmlString, theme);

    if (sections.isEmpty) {
      // Fallback if no sections were parsed
      return _buildParagraph(theme, _extractPlainText(htmlString));
    }

    // Extract the introduction (if text exists before the first header)
    Widget introWidget = const SizedBox();
    List<PolicySection> accordionSections = [];

    if (sections.isNotEmpty && sections.first.title == 'معلومات') {
      introWidget = _buildIntroduction(theme, sections.first.contentWidgets);
      accordionSections = sections.sublist(1);
    } else {
      accordionSections = sections;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _buildHeroIcon(theme, Icons.privacy_tip_rounded),
          const SizedBox(height: 20),

          if (title.isNotEmpty)
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ),
          const SizedBox(height: 30),

          introWidget,

          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: accordionSections.length,
            itemBuilder: (context, index) {
              return _buildAccordionSection(
                theme,
                title: accordionSections[index].title,
                icon: _getIconForIndex(index),
                children: accordionSections[index].contentWidgets,
                index: index,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon(ThemeData theme, IconData icon) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.primaryColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon,
            color: theme.cardColor,
            size: 40),
      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildIntroduction(ThemeData theme, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  IconData _getIconForIndex(int index) {
    final icons = [
      Icons.verified_user_rounded,
      Icons.shield_rounded,
      Icons.security_rounded,
      Icons.description_rounded,
      Icons.policy_rounded,
      Icons.local_police_rounded,
      Icons.privacy_tip_rounded,
    ];
    return icons[index % icons.length];
  }

  String cleanText(String text) {
    return text.replaceAll('\u00A0', ' ').replaceAll('&nbsp;', ' ').trim();
  }

  List<PolicySection> _parseHtmlToSections(String html, ThemeData theme) {
    dom.Document document = htmlparser.parse(html);
    List<PolicySection> sections = [];

    String currentTitle = '';
    List<Widget> currentWidgets = [];

    void addCurrentSection() {
      if (currentTitle.isNotEmpty || currentWidgets.isNotEmpty) {
        sections.add(PolicySection(
          title: currentTitle.isNotEmpty ? currentTitle : 'معلومات',
          contentWidgets: List.from(currentWidgets),
        ));
      }
      currentTitle = '';
      currentWidgets = [];
    }

    var elements = document.body?.children ?? [];

    // If there is only one element or no headers at all, treat it differently
    bool hasHeaders = elements.any((el) {
      if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(el.localName)) return true;
      if (el.localName == 'p') {
        var boldElements = el.querySelectorAll('strong, b');
        if (boldElements.isNotEmpty) {
          final cleanElText = cleanText(el.text);
          final cleanBoldText = cleanText(boldElements.first.text ?? '');
          return cleanBoldText.length >= cleanElText.length * 0.7 &&
              cleanElText.length < 60 &&
              !cleanElText.endsWith(':');
        }
      }
      return false;
    });

    if (!hasHeaders) {
      for (var element in elements) {
        if (element.localName == 'ul' || element.localName == 'ol') {
          for (var li in element.children) {
            if (li.localName == 'li') {
              currentWidgets.add(_buildBulletPoint(theme, li.text));
            }
          }
        } else if (element.localName == 'table') {
          // Very simple table parsing
          for (var tr in element.querySelectorAll('tr')) {
            var tds = tr.querySelectorAll('td, th');
            if (tds.length >= 2) {
              currentWidgets.add(_buildTableRow(theme, tds[0].text, tds[1].text));
            } else if (tds.isNotEmpty) {
              currentWidgets.add(_buildParagraph(theme, tds[0].text));
            }
          }
        } else {
          if (element.text.trim().isNotEmpty) {
            currentWidgets.add(_buildParagraph(theme, element.text));
          }
        }
      }
      addCurrentSection();
      return sections;
    }

    for (var element in elements) {
      String tagName = element.localName ?? '';

      bool isHeader = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(tagName);

      if (!isHeader && tagName == 'p') {
        var boldElements = element.querySelectorAll('strong, b');
        if (boldElements.isNotEmpty) {
          final cleanElText = cleanText(element.text);
          final cleanBoldText = cleanText(boldElements.first.text ?? '');
          isHeader = cleanBoldText.length >= cleanElText.length * 0.7 &&
              cleanElText.length < 60 &&
              !cleanElText.endsWith(':');
        }
      }

      if (isHeader) {
        addCurrentSection();
        currentTitle = cleanText(element.text);

      } else if (tagName == 'ul' || tagName == 'ol') {
        for (var li in element.children) {
          if (li.localName == 'li') {
            currentWidgets.add(_buildBulletPoint(theme, li.text));
          }
        }
      } else if (tagName == 'table') {
        for (var tr in element.querySelectorAll('tr')) {
          var tds = tr.querySelectorAll('td, th');
          if (tds.length >= 2) {
            currentWidgets.add(_buildTableRow(theme, tds[0].text, tds[1].text));
          } else if (tds.isNotEmpty) {
            currentWidgets.add(_buildParagraph(theme, tds[0].text));
          }
        }
      } else {
        if (element.text.trim().isNotEmpty) {
          currentWidgets.add(_buildParagraph(theme, element.text));
        }
      }
    }

    addCurrentSection();
    return sections;
  }

  Widget _buildAccordionSection(
      ThemeData theme, {
        required String title,
        required IconData icon,
        required List<Widget> children,
        required int index,
      }) {
    if (children.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor, // Explicitly white as requested
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 22),
            ),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            iconColor: theme.primaryColor,
            collapsedIconColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.5,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1),
              const SizedBox(height: 15),
              ...children,
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: (index * 100).ms).slideX(begin: 0.1, end: 0, delay: (index * 100).ms);
  }

  Widget _buildParagraph(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}