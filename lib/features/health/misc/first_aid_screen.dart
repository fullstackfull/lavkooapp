import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 30),
                  _buildEmergencyCall(),
                  const SizedBox(height: 30),
                  _buildCategoryGrid(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white)),
      title: Text((getTranslated('firstAidGuide', context) ?? 'firstAidGuide'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.black38),
          hintText: (getTranslated('searchInstruction', context) ?? 'searchInstruction'),
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmergencyCall() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: Colors.redAccent, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((getTranslated('callAmbulance', context) ?? 'callAmbulance'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                Text('911 / 110', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.call, color: Colors.white)),
        ],
      ),
    );
  }

  List<String> _getInstructions(String name, bool isAr) {
    if (name.contains('حروق') || name.contains('Burn')) {
      return isAr ? [
        'قم بتبريد الحرق بماء جارٍ بارد (ليس مثلجاً) لمدة 10 إلى 20 دقيقة.',
        'قم بإزالة الخواتم أو المجوهرات من المنطقة المصابة قبل أن تتورم.',
        'لا تفتح الفقاعات المائية لتجنب العدوى.',
        'غطِّ الحرق بضمادة معقمة غير لاصقة.'
      ] : [
        'Cool the burn under cool running water for 10-20 minutes.',
        'Remove rings or tight items from the burned area before it swells.',
        'Don\'t break blisters to prevent infection.',
        'Cover the burn loosely with a sterile, non-stick bandage.'
      ];
    } else if (name.contains('اختناق') || name.contains('Chok')) {
      return isAr ? [
        'قم بإجراء 5 ضربات على الظهر بين لوحي الكتف.',
        'قم بإجراء 5 ضغطات بطنية (مناورة هايمليخ) أعلى السرة.',
        'استمر بالتبديل حتى يخرج الجسم الغريب أو يفقد المصاب الوعي.',
        'اتصل بالإسعاف فوراً إذا فقد المصاب الوعي وابدأ الإنعاش القلبي.'
      ] : [
        'Give 5 back blows between the shoulder blades.',
        'Give 5 abdominal thrusts (Heimlich maneuver).',
        'Alternate until the blockage is dislodged or person faints.',
        'Call 911 immediately if they lose consciousness and start CPR.'
      ];
    } else if (name.contains('نزيف') || name.contains('Bleed')) {
      return isAr ? [
        'اضغط بقوة ومباشرة على الجرح باستخدام قطعة قماش نظيفة أو ضمادة.',
        'ارفع الجزء المصاب فوق مستوى القلب إن أمكن لتقليل تدفق الدم.',
        'إذا استمر النزيف، أضف ضمادة أخرى فوق الأولى ولا تزل الأولى أبداً.',
        'اطلب المساعدة الطبية فوراً إذا كان النزيف شديداً.'
      ] : [
        'Apply firm, direct pressure on the wound with a clean cloth.',
        'Elevate the injured area above the heart if possible.',
        'If blood bleeds through, add another bandage on top. Don\'t remove the first.',
        'Seek medical help immediately for severe bleeding.'
      ];
    } else if (name.contains('كسور') || name.contains('Fract')) {
      return isAr ? [
        'لا تحاول تحريك المصاب أو إعادة العظم إلى مكانه.',
        'قم بتثبيت المنطقة المصابة باستخدام جبيرة مؤقتة.',
        'ضع كمادات ثلج (ملفوفة في قماش) على المنطقة لتقليل التورم.',
        'اتصل بالإسعاف واستمر في طمأنة المصاب حتى وصول المساعدة.'
      ] : [
        'Do not try to move the person or realign the bone.',
        'Immobilize the injured area using a temporary splint.',
        'Apply ice packs (wrapped in cloth) to reduce swelling.',
        'Call emergency services and reassure the person until help arrives.'
      ];
    } else if (name.contains('إغماء') || name.contains('Faint')) {
      return isAr ? [
        'ضع المصاب على ظهره وارفع ساقيه أعلى من مستوى القلب.',
        'قم بفك أي ملابس ضيقة حول الرقبة أو الخصر لضمان تنفس أفضل.',
        'تأكد من وجود مجرى هواء مفتوح وتحقق من التنفس.',
        'إذا لم يستعد الوعي خلال دقيقة، اتصل بالإسعاف فوراً.'
      ] : [
        'Lay the person flat on their back and elevate their legs.',
        'Loosen any tight clothing around the neck or waist.',
        'Ensure the airway is open and check for breathing.',
        'If they don\'t regain consciousness within a minute, call 911.'
      ];
    } else if (name.contains('تسمم') || name.contains('Poison')) {
      return isAr ? [
        'اتصل بمركز السموم أو الطوارئ فوراً للحصول على التوجيه.',
        'لا تجبر المصاب على التقيؤ ما لم يطلب منك المختصون ذلك.',
        'اجمع أي عبوات أدوية قريبة لمساعدة الطبيب في التشخيص.',
        'إذا كان السم ملامساً للجلد، اغسله بالماء الجاري بكثرة.'
      ] : [
        'Call poison control or emergency services immediately.',
        'Do not induce vomiting unless told to do so by professionals.',
        'Gather any nearby pill bottles to help doctors identify the poison.',
        'If skin exposure occurred, wash the area with plenty of running water.'
      ];
    } else if (name.contains('الإنعاش') || name.contains('CPR')) {
      return isAr ? [
        'تأكد من أمان المكان وتحقق من وعي المصاب.',
        'اطلب المساعدة فوراً (اتصل بالإسعاف).',
        'ضع كعب يدك في منتصف الصدر واضغط بقوة وسرعة (100-120 ضغطة/دقيقة).',
        'استمر في الضغط حتى وصول المساعدة أو استعادة الوعي.'
      ] : [
        'Check the scene for safety and check the person\'s responsiveness.',
        'Call for help immediately (Call 911).',
        'Place the heel of your hand in the center of the chest and push hard and fast.',
        'Continue compressions until help arrives or the person regains consciousness.'
      ];
    }
    return isAr ? [
      'تأكد من سلامتك وسلامة المصاب أولاً.',
      'اطلب المساعدة الطبية عند الحاجة.',
      'ابقَ هادئاً وطمئن المصاب.',
      'تجنب تحريك المصاب إذا كان هناك شك بوجود إصابة.'
    ] : [
      'Ensure safety for yourself and the injured person first.',
      'Call for medical help when necessary.',
      'Stay calm and reassure the injured person.',
      'Avoid moving the person if a severe injury is suspected.'
    ];
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': (getTranslated('burns', context) ?? 'burns'), 'icon': Icons.fire_hydrant_alt},
      {'name': (getTranslated('choking', context) ?? 'choking'), 'icon': Icons.air},
      {'name': (getTranslated('bleeding', context) ?? 'bleeding'), 'icon': Icons.bloodtype},
      {'name': (getTranslated('fractures', context) ?? 'fractures'), 'icon': Icons.healing},
      {'name': (getTranslated('fainting', context) ?? 'fainting'), 'icon': Icons.person_off},
      {'name': (getTranslated('poisoning', context) ?? 'poisoning'), 'icon': Icons.warning},
      {'name': (getTranslated('cpr', context) ?? 'cpr'), 'icon': Icons.favorite},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.95),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final name = category['name'] as String;
        final icon = category['icon'] as IconData;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return InkWell(
          onTap: () {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            final steps = _getInstructions(name, isAr);
            showModalBottomSheet(
              context: context,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              isScrollControlled: true,
              builder: (context) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.55,
                maxChildSize: 0.8,
                minChildSize: 0.4,
                builder: (context, scrollController) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 20),
                      Icon(icon, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 15),
                      Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 25),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: steps.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                  child: Text('${i + 1}', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    steps[i],
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.5, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: Text(isAr ? 'حسناً، فهمت' : 'Got it', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.redAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.redAccent, size: 30),
                const SizedBox(height: 8),
                Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn();
  }
}
