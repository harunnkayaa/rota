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
  String overAllocated(String amount) {
    return 'Kalan hedeften $amount fazla planlandı.';
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
  String get createGoalTitle => 'Yeni hedef';

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

  @override
  String get editTodayPlan => 'Bugünün planı';

  @override
  String get editWeekPlan => 'Haftanın planı';

  @override
  String get editPlanTooltip => 'Planı düzenle';

  @override
  String remainingToday(String amount) {
    return 'Kalan $amount';
  }

  @override
  String get summaryRemaining => 'Kalan';

  @override
  String todayRingSemantics(String done, String planned) {
    return 'Bugün $done / $planned tamamlandı';
  }

  @override
  String planDistributed(String planned, String target) {
    return 'Planlanan $planned / $target';
  }

  @override
  String planUnallocated(String amount) {
    return '$amount henüz günlere dağıtılmadı.';
  }

  @override
  String planOverTarget(String amount) {
    return 'Hedeften $amount fazla planladın.';
  }

  @override
  String planDebt(String amount) {
    return 'Plan, kalan hedefin $amount kısmını karşılamıyor.';
  }

  @override
  String get planCovers => 'Plan haftalık hedefi karşılıyor.';

  @override
  String get distributeEvenlyAction => 'Eşit dağıt';

  @override
  String get matchTargetToPlan => 'Hedefi toplama eşitle';

  @override
  String get clearPlan => 'Temizle';

  @override
  String decreaseBy(String amount) {
    return '$amount azalt';
  }

  @override
  String increaseBy(String amount) {
    return '$amount artır';
  }

  @override
  String durationFieldSemantics(String label, String value) {
    return '$label: $value. Değiştirmek için dokun.';
  }

  @override
  String durationSheetTitle(String label) {
    return '$label için süre';
  }

  @override
  String errorDurationMax(String max) {
    return 'En fazla $max girilebilir.';
  }

  @override
  String pastDayLocked(String done, String planned) {
    return 'Geçmiş gün · $done / $planned';
  }

  @override
  String get sectionDailyPlan => 'Günlük plan';

  @override
  String get dailyPlanHint =>
      'Her gün için ayrı süre belirle. Sonra Bugün ya da Hafta ekranından değiştirebilirsin.';

  @override
  String get weekTargetHint => 'Bu hafta toplam ne kadar çalışmak istiyorsun?';

  @override
  String capacityRowOver(String amount) {
    return 'Günlük kapasite $amount aşılıyor';
  }

  @override
  String hoursCompact(String value) {
    return '$value sa';
  }

  @override
  String dayCellSemantics(String day, String value, String status) {
    return '$day: $value, $status';
  }

  @override
  String get dayStatusNoPlan => 'Plan yok';

  @override
  String get errorPlanPast => 'Geçmiş günlerin planı değiştirilemez.';

  @override
  String get errorPlanGeneric => 'Plan kaydedilemedi. Tekrar dene.';

  @override
  String get weekdayToday => 'Bugün';

  @override
  String todayProgressOf(String planned) {
    return '/ $planned';
  }

  @override
  String get sectionWeeklyTarget => 'Haftalık hedef';

  @override
  String planRemainingOf(String planned, String target) {
    return 'Kalan plan $planned / kalan hedef $target';
  }

  @override
  String planOverRemaining(String amount) {
    return 'Kalan hedeften $amount fazla planladın.';
  }

  @override
  String get planCoversRemaining => 'Plan, haftanın kalanını karşılıyor.';

  @override
  String dayPlanTitle(String day) {
    return '$day planı';
  }

  @override
  String get sectionGoalKind => 'Hedef türü';

  @override
  String get goalKindWeekly => 'Haftalık';

  @override
  String get goalKindDeadline => 'Tarihli';

  @override
  String get goalKindWeeklyHint =>
      'Her hafta tekrarlanan çalışma: haftada 10 sa proje.';

  @override
  String get goalKindDeadlineHint =>
      'Bir tarihe yetişmesi gereken iş: 15 Kasım\'daki sınava 40 sa hazırlık.';

  @override
  String get sectionDueDate => 'Tarih';

  @override
  String get dueDateHint =>
      'Sınav, mülakat veya teslim günü. Çalışma bu günden öncesine planlanır.';

  @override
  String get pickDueDate => 'Tarih seç';

  @override
  String dueDateValue(String date, String days) {
    return '$date · $days gün kaldı';
  }

  @override
  String get sectionTotalTarget => 'Toplam hedef';

  @override
  String get totalTargetHint =>
      'Bu tarihe kadar toplam ne kadar çalışmak istiyorsun?';

  @override
  String get errorDueDate => 'Bugünden sonraki bir tarih seç.';

  @override
  String get errorTotalRequired => 'Toplam hedef 0\'dan büyük olmalı.';

  @override
  String pacePerWeek(String amount) {
    return 'Haftada ~$amount gerekiyor';
  }

  @override
  String get paceFeasible => 'Mevcut kapasitenle bu tarihe yetişebilirsin.';

  @override
  String paceShortfall(String amount) {
    return 'Mevcut kapasitenle $amount eksik kalır.';
  }

  @override
  String get pickDateFirst =>
      'Günlük planı görmek için önce tarihi ve toplam hedefi seç.';

  @override
  String get weekPaceLabel => 'Bu haftanın temposu';

  @override
  String get totalLabel => 'Toplam';

  @override
  String get deadlineStatusOnTrack => 'Yolunda';

  @override
  String deadlineStatusBehind(String amount) {
    return 'Bu hafta $amount açık';
  }

  @override
  String deadlineStatusNotFeasible(String amount) {
    return '$amount eksik kalıyor';
  }

  @override
  String get deadlineStatusCompleted => 'Tamamlandı';

  @override
  String get deadlineStatusOverdue => 'Tarih geçti';

  @override
  String paceBehindNotice(String amount) {
    return 'Tempoya yetişmek için bu hafta $amount daha planlaman gerekiyor.';
  }

  @override
  String paceNotFeasibleNotice(String date, String amount) {
    return 'Mevcut planla $date tarihine $amount eksikle varırsın.';
  }

  @override
  String get paceOptions => 'Seçenekler';

  @override
  String get catchUpTitle => 'Tempoyu yakala';

  @override
  String catchUpGap(String amount) {
    return 'Tempoya yetişmek için bu hafta $amount daha gerekiyor.';
  }

  @override
  String get catchUpFromFree => 'Boş zamanından';

  @override
  String get catchUpFromOthers => 'Diğer hedeflerden';

  @override
  String get catchUpDonorsTitle => 'Başka hedeften süre al';

  @override
  String get catchUpDonorsHint =>
      'Seçtiğin hedefin bu haftaki planından alınır; o günün toplam yükü değişmez.';

  @override
  String catchUpDonorPlanned(String amount) {
    return 'Bu hafta $amount planlı';
  }

  @override
  String catchUpShortfall(String amount) {
    return '$amount bu haftaya sığmıyor. Başka bir hedeften süre alabilir ya da toplam hedefi düşürebilirsin.';
  }

  @override
  String get catchUpNoDays =>
      'Bu hafta telafi edilecek gün kalmadı; tempo gelecek haftaya yansıyacak.';

  @override
  String get catchUpNothingNeeded => 'Bu haftanın temposu karşılanıyor.';

  @override
  String catchUpReduction(String goal, String amount) {
    return '$goal: −$amount';
  }

  @override
  String get changeTotalTarget => 'Toplam hedefi değiştir';

  @override
  String get targetUpdated => 'Hedef güncellendi';

  @override
  String planWeekPaceOf(String planned, String target) {
    return 'Bu hafta planlanan $planned / tempo $target';
  }

  @override
  String planWeekPaceMissing(String amount) {
    return 'Tempo için bu hafta $amount daha planla.';
  }

  @override
  String planWeekPaceOver(String amount) {
    return 'Tempodan $amount fazla planladın.';
  }

  @override
  String get planWeekPaceCovers => 'Plan bu haftanın temposunu karşılıyor.';
}
