# قائمة الإطلاق v1.0.0

## تقني
- [ ] GitHub Actions أخضر: فحص الرسومات + analyze + test + APK + AAB.
- [ ] حجم APK (arm64) أقل من 40MB (تقرير الحجم في سجل البناء).
- [ ] 60fps على جهاز متوسط (2GB RAM): Flutter DevTools ← Performance أثناء: فرشاة نيون طويلة، عصا سحرية، الإحياء، الحديقة.
- [ ] لا تحذيرات «setState during build» أو overflow في `flutter run --debug`.
- [ ] «سجل الأخطاء» فارغ بعد جلسة 30 دقيقة.
- [ ] اختبار على: جوال صغير (360dp)، جوال كبير، تابلت أفقي، أندرويد 9 وأندرويد 14.

## التوقيع (مرة واحدة)
1. `keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias colorland`
2. **احفظ الملف وكلمات المرور في مكان آمن خارج المستودع.**
3. في GitHub ← Settings ← Secrets: `KEYSTORE_B64` (= `base64 -w0 upload.jks`)، `KEY_ALIAS`، `KEY_PASSWORD`، `STORE_PASSWORD`.
4. البناء التالي يخرج APK/AAB موقّعة للإطلاق تلقائيًا.

## Google Play
- [ ] حساب مطوّر + Families Policy + Teacher Approved (اختياري).
- [ ] نموذج «أمان البيانات»: لا جمع، لا مشاركة.
- [ ] الفئة العمرية المستهدفة: 3–5، 6–8، 9–12.
- [ ] رفع `docs/PRIVACY_POLICY.md` كصفحة ويب ووضع رابطها.
- [ ] نصوص `docs/STORE_LISTING.md` + 8 لقطات + أيقونة 512×512 (`tools/icon/lolo.svg`).
- [ ] اختبار داخلي ← مغلق ← إنتاج.
