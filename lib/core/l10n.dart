import 'package:flutter/widgets.dart';

import 'settings.dart';

/// Tiny two-language string table (Arabic default, English).
class S {
  const S(this.lang);
  final String lang;

  /// Registers a dependency on the app locale, so text rebuilds instantly
  /// when parents switch the language.
  static S of(BuildContext context) =>
      S(Localizations.maybeLocaleOf(context)?.languageCode ?? Settings.instance.lang);
  static S get current => S(Settings.instance.lang);

  bool get isAr => lang != 'en';

  String _t(String ar, String en) => isAr ? ar : en;

  String get appName => _t('عالم الألوان', 'ColorLand');
  String get startColoring => _t('ابدأ التلوين', 'Start Coloring');
  String get freeDraw => _t('الرسم الحر', 'Free Drawing');
  String get myGallery => _t('معرض رسوماتي', 'My Gallery');
  String get worlds => _t('اختر عالمك', 'Pick a World');
  String get locked => _t('مقفل', 'Locked');
  String needStars(int n) => _t('تحتاج $n نجوم لفتح هذا العالم', 'You need $n stars to open this world');
  String get classic => _t('تلوين عادي', 'Color');
  String get magic => _t('التلوين السحري', 'Magic Reveal');
  String get numbers => _t('بالأرقام', 'By Numbers');
  String get chooseMode => _t('كيف تريد أن تلوّن؟', 'How do you want to color?');
  String get wellDone => _t('أحسنت! 🎉', 'Well done! 🎉');
  String get finished => _t('أكملت الرسمة', 'You finished it');
  String get bringToLife => _t('أحيِها!', 'Bring it to life!');
  String get alive => _t('رسمتك صارت حيّة!', 'Your drawing is alive!');
  String get again => _t('مرة أخرى', 'Again');
  String get done => _t('تم', 'Done');
  String get gallery => _t('معرض أعمالي', 'My Artworks');
  String get emptyGallery => _t('لا توجد رسومات بعد. هيا نلوّن!', 'No drawings yet. Let\'s color!');
  String get garden => _t('حديقة العالم', 'World Garden');
  String get emptyGarden => _t('أحيِ رسوماتك لتعيش هنا!', 'Bring drawings to life to see them here!');
  String get achievements => _t('الإنجازات', 'Badges');
  String get newBadge => _t('شارة جديدة!', 'New badge!');
  String get dailyGift => _t('هدية اليوم', 'Daily Gift');
  String get giftOpen => _t('افتح الهدية', 'Open the gift');
  String get giftGot => _t('حصلت على نجمتين!', 'You got 2 stars!');
  String get giftTomorrow => _t('عد غدًا لهدية جديدة', 'Come back tomorrow for a new gift');
  String get mixColors => _t('امزج الألوان', 'Mix Colors');
  String get mixHint => _t('اختر لونين', 'Pick two colors');
  String get addColor => _t('أضف اللون', 'Add color');
  String get newColor => _t('لون جديد!', 'New color!');
  String get parents => _t('للوالدين', 'For Parents');
  String gateQuestion2(String a, String b) => _t('اضغط على الرقم $a ثم الرقم $b', 'Tap $a, then $b');
  String gateQuestion(String n) => _t('اضغط على الرقم: $n', 'Tap the number: $n');
  String get settings => _t('الإعدادات', 'Settings');
  String get sound => _t('المؤثرات الصوتية', 'Sound effects');
  String get music => _t('الموسيقى', 'Music');
  String get vibration => _t('الاهتزاز', 'Vibration');
  String get language => _t('اللغة', 'Language');
  String get ageMode => _t('عمر الطفل', 'Child age');
  String get ageLittle => _t('صغير (3 – 5)', 'Little (3 - 5)');
  String get ageBig => _t('كبير (6 – 10)', 'Big (6 - 10)');
  String get unlockAll => _t('فتح كل العوالم', 'Unlock all worlds');
  String get timeLimit => _t('مدة اللعب اليومية', 'Daily play time');
  String get off => _t('بدون حد', 'No limit');
  String minutes(int m) => _t('$m دقيقة', '$m min');
  String get resetAll => _t('مسح كل التقدم والرسومات', 'Erase all progress & drawings');
  String get resetConfirm => _t('هل أنت متأكد؟ لا يمكن التراجع.', 'Are you sure? This cannot be undone.');
  String get yes => _t('نعم', 'Yes');
  String get cancel => _t('إلغاء', 'Cancel');
  String get privacy => _t('لا يجمع التطبيق أي بيانات، ولا يحتاج إنترنت، ولا يحتوي إعلانات.', 'No data collected, no internet, no ads.');
  String get restTitle => _t('وقت الراحة 😴', 'Rest time 😴');
  String get restBody => _t('لولو متعبة، لنكمل غدًا!', 'Lolo is sleepy. Let\'s continue tomorrow!');
  String get restContinue => _t('للوالدين: متابعة', 'Parents: continue');
  String get stars => _t('نجوم', 'stars');
  String get delete => _t('حذف', 'Delete');
  String get loloHello => _t('أهلًا! أنا لولو 🎨', 'Hi! I\'m Lolo 🎨');
  String get loloTap => _t('هيهي! هذا يدغدغ!', 'Hehe! That tickles!');
  String get tools => _t('الأدوات', 'Tools');
  String get brushStyles => _t('نوع الفرشاة', 'Brush type');
  String get continueDrawing => _t('أكمل الرسم', 'Keep drawing');
  String get saveToPhone => _t('احفظ في صور الجوال', 'Save to phone photos');
  String get savedToPhone => _t('تم الحفظ في الصور ✅', 'Saved to photos ✅');
  String get saveFailed => _t('تعذّر الحفظ', 'Could not save');
  String get galleryHint => _t('اضغط مطولًا على الرسمة لخيارات أكثر', 'Long-press a drawing for more options');
  String get errorLog => _t('سجل الأخطاء (للدعم)', 'Error log (for support)');
  String get nextDrawing => _t('رسمة جديدة', 'New drawing');

  static const wordsAr = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة'];
  static const wordsEn = ['', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
  String numberWord(int n) => isAr ? wordsAr[n] : wordsEn[n];
}
