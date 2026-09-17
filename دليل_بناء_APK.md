# دليل بناء APK خطوة بخطوة (من الموبايل فقط)

هذه النسخة محدّثة وجاهزة: كل مشاكل البناء القديمة انحلّت داخل المشروع نفسه،
وما عليك إلا الرفع على GitHub وتشغيل البناء التلقائي.

## قبل ما تبدأ (3 دقائق)
1. أنشئ مشروعاً على Firebase: https://console.firebase.google.com
   - فعّل Authentication بطريقة Email/Password
   - أنشئ Firestore Database بوضع test mode مؤقتاً
2. أضف تطبيق Android للمشروع:
   - Package name: `com.example.tuktuk_app`  ← مهم يكون نفس هذا بالضبط
   - نزّل ملف `google-services.json`
3. أنشئ حساباً على https://github.com

## رفع المشروع على GitHub
1. أنشئ repository جديد اسمه `tuktuk-app` (Public أو Private، الاثنين يشتغلون)
2. ارفع **كل** محتويات هذه المجلدات مع الحفاظ على الهيكلية:
   - `lib/` و `pubspec.yaml` و `assets/` و `firestore.rules`
   - مجلد `.github` (مجلد مخفي — إذا تعذّر رفعه من المتصفح، أنشئ الملف
     يدوياً من GitHub: Create new file وسمّه `.github/workflows/build_apk.yml`
     والصق فيه محتوى ملف workflows/build_apk.yml الموجود هنا)
3. ارفع ملف `google-services.json` (اللي نزّلته من Firebase) في **جذر**
   المشروع — يعني بجانب `pubspec.yaml` مباشرة

## تشغيل البناء والحصول على APK
1. افتح تبويب **Actions** في صفحة المستودع → اضغط **Run workflow**
   (أو يبدأ تلقائياً عند الرفع على main)
2. انتظر 10-15 دقيقة (البناء يولّد مجلد android ويثبّت الحزم)
3. لما تظهر علامة ✅ خضراء، اضغط على البناء → **Artifacts** →
   حمّل `tuktuk-app-release` وفك ضغطه → ثبّت الـ APK على جوالك
   (فعّل "التثبيت من مصادر غير معروفة")

## إذا فشل البناء
- اضغط على العملية الحمراء واقرأ آخر سطور السجل — رسائل الخطأ بالعربي موجّهة
- السبب الأشهر: نسيان رفع `google-services.json` أو اختلاف package name
- بعد إصلاح الخطأ أعد Run workflow

## ملاحظات
- إن كانت قاعدة البيانات بوضع test mode، أي أحد يقدر يقرأ/يكتب لمدة 30 يوم —
  انشر firestore.rules بعد الاختبار
- الخرائط غير مفعّلة في الواجهات حالياً، لذا لا حاجة لمفتاح Google Maps الآن
