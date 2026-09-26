// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Rota';

  @override
  String get navToday => 'Bugün';

  @override
  String get navWeek => 'Hafta';

  @override
  String get addGoal => 'Hedef ekle';

  @override
  String get emptyTitle => 'Henüz hedefin yok';

  @override
  String get emptyBody =>
      'Haftalık bir hedef oluştur ve günlere dağıt. Rota, her gün yaptığın çalışmanın haftalık hedefine nasıl yansıdığını gösterir.';

  @override
  String get createGoalCta => 'Hedef oluştur';

  @override
  String get loadSampleCta => 'Örnek haftayı yükle';

  @override
  String get summaryPlanned => 'Planlanan';

  @override
  String get summaryDone => 'Gerçekleşen';

  @override
  String get summaryCapacityLeft => 'Boş kapasite';

  @override
  String capacityOver(String amount) {
    return 'Bugünün planı kapasiteni $amount aşıyor.';
  }

  @override
  String progressOf(String done, String target) {
    return '$done / $target';
  }

  @override
  String get todayLabel => 'Bugün';

  @override
  String get weekLabel => 'Bu hafta';

  @override
  String get todayNoPlan => 'Bugün için plan yok';

  @override
  String get flexibleChip => 'Esnek';

  @override
  String get addProgress => 'İlerleme ekle';

  @override
  String goalDebt(String amount) {
    return 'Bu haftanın planında $amount açıkta kaldı.';
  }

  @override
  String get redistribute => 'Yeniden dağıt';

  @override
  String addProgressTitle(String goal) {
    return '$goal için ilerleme';
  }

  @override
  String get customMinutesLabel => 'Dakika';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'Vazgeç';

  @override
  String progressAdded(String amount) {
    return '$amount eklendi';
  }

  @override
  String get errorMinutesInvalid =>
      '1 ile 1440 arasında bir dakika değeri gir.';

  @override
  String get errorPeriodClosed => 'Bu dönem kapandı; yeni ilerleme eklenemez.';

  @override
  String get errorDateOutside => 'Bugün bu hedefin dönemi içinde değil.';

  @override
  String get errorProgressGeneric => 'İlerleme kaydedilemedi. Tekrar dene.';

  @override
  String get redistributeTitle => 'Yeniden dağıtma önerisi';

  @override
  String get strategyEven => 'Eşit';

  @override
  String get strategyCapacity => 'Boş kapasiteye göre';

  @override
  String get includeToday => 'Bugünü de dahil et';

  @override
  String redistributeFeasible(String deficit) {
    return '$deficit mevcut planın dışında kaldı. Kalan günlere şöyle dağıtılabilir:';
  }

  @override
  String redistributeInfeasible(
    String deficit,
    String capacity,
    String shortfall,
  ) {
    return '$deficit planın dışında kaldı, ancak kalan günlerde yalnızca $capacity boş kapasite var. $shortfall bu haftaya sığmıyor. Aşağıdaki kısmı planlayabilir, hedefi azaltmayı ya da başka bir esnek hedefi düşürmeyi düşünebilirsin.';
  }

  @override
  String redistributeNoDays(String deficit) {
    return '$deficit planın dışında kaldı, ancak bu dönemde boş kapasitesi olan gün kalmadı.';
  }

  @override
  String get notAllowedFixed => 'Sabit saatli hedefler yeniden dağıtılmaz.';

  @override
  String get notAllowedNothing =>
      'Dağıtılacak eksik yok; plan hedefi karşılıyor.';

  @override
  String get notAllowedClosed => 'Bu dönem kapandı.';

  @override
  String get applyPlan => 'Planı uygula';

  @override
  String get planApplied => 'Plan güncellendi';

  @override
  String addition(String amount) {
    return '+$amount';
  }

  @override
  String get weekTitle => 'Hafta';

  @override
  String weekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weekNoGoals => 'Bu hafta için hedef yok.';

  @override
  String get capacityTitle => 'Günlük kapasite';

  @override
  String capacityOfDay(String planned, String capacity) {
    return '$planned / $capacity';
  }

  @override
  String capacityDayOver(String amount) {
    return '$amount fazla';
  }

  @override
  String unallocated(String amount) {
    return 'Günlere dağıtılmamış: $amount';
  }

  @override
  String overAllocated(String amount) {
    return 'Hedeften $amount fazla planlandı';
  }

  @override
  String get dayStatusDone => 'Tamamlandı';

  @override
  String dayStatusMissed(String amount) {
    return '$amount eksik';
  }

  @override
  String get dayStatusToday => 'Bugün';

  @override
  String get dayStatusUpcoming => 'Planlandı';

  @override
  String get createGoalTitle => 'Yeni haftalık hedef';

  @override
  String get sectionCategory => 'Kategori';

  @override
  String get newCategory => 'Yeni kategori';

  @override
  String get newCategoryName => 'Kategori adı';

  @override
  String get sectionTitle => 'Hedef adı';

  @override
  String get titleHint => 'Örn. Rota MVP geliştirme';

  @override
  String get sectionTarget => 'Haftalık hedef';

  @override
  String get hoursLabel => 'Saat';

  @override
  String get minutesLabel => 'Dakika';

  @override
  String get sectionDays => 'Günlere dağıt';

  @override
  String get daysHint =>
      'Hedef seçtiğin günlere eşit dağıtılır. Geçmiş günler seçilemez.';

  @override
  String get sectionPreview => 'Günlük plan';

  @override
  String capacityWarningDay(String day, String amount) {
    return '$day: kapasite $amount aşılacak';
  }

  @override
  String get createGoalSubmit => 'Hedefi oluştur';

  @override
  String get errorPickCategory => 'Bir kategori seç.';

  @override
  String get errorTitleRequired => 'Hedef adı gerekli.';

  @override
  String get errorTargetRequired =>
      'Haftalık hedef 0\'dan büyük ve bir haftadan kısa olmalı.';

  @override
  String get errorPickDays => 'En az bir gün seç.';

  @override
  String get goalCreated => 'Hedef oluşturuldu';

  @override
  String durationMinutes(String minutes) {
    return '$minutes dk';
  }

  @override
  String durationHours(String hours) {
    return '$hours sa';
  }

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get categoryWork => 'İş hayatı';

  @override
  String get categoryJobApplication => 'İş başvurusu';

  @override
  String get categoryInterview => 'Mülakat';

  @override
  String get categoryProjectDevelopment => 'Proje geliştirme';

  @override
  String get categoryGraduateStudy => 'Yüksek lisans / ders';

  @override
  String get categoryLanguage => 'PTE / dil';

  @override
  String get categoryReading => 'Kitap';

  @override
  String get categorySport => 'Spor';

  @override
  String get categoryHealthMedication => 'Sağlık / ilaç';

  @override
  String get categoryBrainTraining => 'Beyin jimnastiği';

  @override
  String get categoryWorship => 'Namaz / ibadet';

  @override
  String get categoryPersonal => 'Kişisel';

  @override
  String get sampleProjectGoal => 'Rota MVP geliştirme';

  @override
  String get sampleLanguageGoal => 'PTE hazırlık';

  @override
  String get loadingLabel => 'Veriler yükleniyor';

  @override
  String get loadFailedTitle => 'Kayıtlı verilerin okunamadı';

  @override
  String get loadFailedBody =>
      'Verilerin silinmedi ve üzerine yazılmadı. Tekrar deneyebilirsin; sorun sürerse uygulamanın güncellenmesi gerekebilir.';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get saveFailed => 'Son değişiklik bu cihaza kaydedilemedi.';
}
