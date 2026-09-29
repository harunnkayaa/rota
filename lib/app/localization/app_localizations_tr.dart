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
  String get capacityTitle => 'Günlük yük';

  @override
  String get capacitySubtitle => 'Her gün planlanan süre ve o günkü kapasiten.';

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

  @override
  String get navReports => 'Rapor';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get reviewTitle => 'Geçen hafta kapandı';

  @override
  String reviewBody(String count) {
    return '$count hedefin sonucu hazır. Eksik kalan süre sen istemedikçe taşınmaz.';
  }

  @override
  String get reviewOpen => 'Özeti gör';

  @override
  String get reviewSheetTitle => 'Hafta özeti';

  @override
  String reviewShortfall(String amount) {
    return '$amount eksik kaldı';
  }

  @override
  String carryOverAction(String amount) {
    return '$amount bu haftaya ekle';
  }

  @override
  String get carryOverDone => 'Bu haftaya eklendi';

  @override
  String get reviewAcknowledge => 'Tamam';

  @override
  String get moreActions => 'Diğer işlemler';

  @override
  String get archiveGoal => 'Hedefi arşivle';

  @override
  String get archiveConfirmTitle => 'Hedef arşivlensin mi?';

  @override
  String get archiveConfirmBody =>
      'Hedef Bugün ve Hafta ekranlarından kalkar ve yeni haftalara açılmaz. Geçmiş sonuçları raporlarda kalır.';

  @override
  String get archiveConfirm => 'Arşivle';

  @override
  String get goalArchived => 'Hedef arşivlendi';

  @override
  String get undo => 'Geri al';

  @override
  String get editGoal => 'Hedefi düzenle';

  @override
  String get goalUpdated => 'Hedef güncellendi';

  @override
  String get todayEntries => 'Bugünkü kayıtlar';

  @override
  String get todayEntriesHint =>
      'Yanlış girdiğin bir kaydı geri alabilirsin. Kayıt silinmez; geçmişte düzeltme olarak görünür.';

  @override
  String get todayEntriesEmpty => 'Bugün bu hedefe henüz kayıt girilmedi.';

  @override
  String get entrySourceManual => 'Elle';

  @override
  String get entrySourceFocus => 'Odak sayacı';

  @override
  String entryLine(String time, String amount, String source) {
    return '$time · $amount · $source';
  }

  @override
  String entryTakenBack(String amount) {
    return '$amount geri alındı';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsCapacity => 'Günlük kapasite';

  @override
  String get settingsCapacityHint =>
      'Bir günde gerçekçi olarak planlayabileceğin süre. Plan bunu aşarsa uyarı alırsın.';

  @override
  String get settingsDefaultCapacity => 'Her gün';

  @override
  String get settingsWeekdayCapacity => 'Güne özel kapasite';

  @override
  String get settingsWeekdayHint =>
      'Farklı olan günleri ayarla; diğerleri \"Her gün\" değerini kullanır.';

  @override
  String settingsResetDay(String day) {
    return '$day için özel kapasiteyi kaldır';
  }

  @override
  String get settingsWeekStart => 'Hafta başlangıcı';

  @override
  String get settingsWeekStartHint =>
      'Değişiklik bir sonraki haftadan itibaren geçerli olur.';

  @override
  String get settingsDataTitle => 'Verilerin';

  @override
  String get settingsDataBody => 'Verilerin yalnızca bu cihazda saklanıyor.';

  @override
  String get settingsDataBodySynced =>
      'Verilerin bu cihazda ve hesabında saklanıyor; giriş yaptığın her cihazda aynı görünür.';

  @override
  String get focusStart => 'Odaklan';

  @override
  String get focusTitle => 'Odak';

  @override
  String get focusPause => 'Duraklat';

  @override
  String get focusResume => 'Devam et';

  @override
  String get focusFinish => 'Bitir ve kaydet';

  @override
  String get focusCancel => 'Oturumu iptal et';

  @override
  String get focusPaused => 'Duraklatıldı';

  @override
  String focusRecorded(String amount) {
    return '$amount kaydedildi';
  }

  @override
  String get focusTooShort => '1 dakikadan kısa çalışma kaydedilmedi.';

  @override
  String get focusCancelConfirmTitle => 'Oturum iptal edilsin mi?';

  @override
  String get focusCancelConfirmBody => 'Bu oturumdaki süre kaydedilmez.';

  @override
  String get focusCancelConfirm => 'İptal et';

  @override
  String get focusRunning => 'Odak sürüyor';

  @override
  String get focusOpen => 'Aç';

  @override
  String get focusAnotherRunning => 'Başka bir hedefte odak oturumu sürüyor.';

  @override
  String get focusPeriodEnded =>
      'Bu hedefin dönemi bitti; süre kaydedilemedi. Oturumu iptal edip ilerlemeyi yeni haftaya elle ekleyebilirsin.';

  @override
  String focusTimerSemantics(String time) {
    return 'Geçen süre $time';
  }

  @override
  String get reportsTitle => 'Rapor';

  @override
  String get reportsThisWeek => 'Bu hafta';

  @override
  String get reportsTarget => 'Hedef';

  @override
  String get reportsCompletion => 'Tamamlanma';

  @override
  String reportsPercent(String value) {
    return '%$value';
  }

  @override
  String get reportsByCategory => 'Kategoriye göre';

  @override
  String get reportsByCategoryHint =>
      'Bu hafta çalıştığın sürenin alanlara dağılımı.';

  @override
  String get reportsNoWorkYet => 'Bu hafta henüz ilerleme kaydedilmedi.';

  @override
  String get reportsHistory => 'Geçmiş haftalar';

  @override
  String get reportsEmptyHistory =>
      'Kapanan haftaların sonuçları burada görünecek.';

  @override
  String reportsChangeUp(String amount) {
    return 'Önceki haftadan $amount fazla';
  }

  @override
  String reportsChangeDown(String amount) {
    return 'Önceki haftadan $amount az';
  }

  @override
  String get reportsChangeSame => 'Önceki haftayla aynı';

  @override
  String get reportsDeadlines => 'Tarihli hedefler';

  @override
  String get weekPaceShort => 'tempo';

  @override
  String get reminderTitle => 'Rota';

  @override
  String reminderTodayBody(String goal, String amount) {
    return '$goal: bugün $amount kaldı.';
  }

  @override
  String reminderPaceBody(String goal, String amount) {
    return '$goal: tempo için bu hafta $amount daha gerekiyor.';
  }

  @override
  String get reminderHiddenBody => 'Planlanmış kişisel hatırlatıcın var.';

  @override
  String get settingsReminders => 'Hatırlatmalar';

  @override
  String get settingsRemindersHint =>
      'Akşam, bugün henüz çalışmadığın süreyi hatırlatır. Planını tamamladıysan bildirim gelmez.';

  @override
  String get settingsRemindersEnable => 'Hatırlatmaları aç';

  @override
  String get settingsReminderTime => 'Hatırlatma saati';

  @override
  String get settingsQuietFrom => 'Sessiz saat başlangıcı';

  @override
  String get settingsQuietTo => 'Sessiz saat bitişi';

  @override
  String get settingsDailyBudget => 'Günlük en fazla bildirim';

  @override
  String get settingsShowSensitive =>
      'Sağlık ve ibadet hedeflerinin adını göster';

  @override
  String get settingsShowSensitiveHint =>
      'Kapalıyken kilit ekranında yalnızca \"Planlanmış kişisel hatırlatıcın var.\" yazar.';

  @override
  String get settingsPermissionDenied =>
      'Bildirim izni verilmedi. iPhone Ayarlar > Rota > Bildirimler bölümünden açabilirsin.';

  @override
  String get settingsRemindersWebNote =>
      'Hatırlatmalar iPhone uygulamasında çalışır; web sürümü bildirim göndermez.';

  @override
  String get settingsReminderInQuiet =>
      'Hatırlatma saati sessiz saatlerin içinde; bu saatte bildirim gönderilmez.';

  @override
  String get settingsExport => 'Verilerini dışa aktar';

  @override
  String get settingsExportHint =>
      'Hedeflerin, planların, ilerlemen ve ayarların okunabilir JSON olarak.';

  @override
  String get exportTitle => 'Dışa aktarılan veri';

  @override
  String get exportCopy => 'Panoya kopyala';

  @override
  String get exportCopied => 'Veriler panoya kopyalandı';

  @override
  String get close => 'Kapat';

  @override
  String get settingsDelete => 'Tüm verileri sil';

  @override
  String get deleteConfirmTitle => 'Tüm veriler silinsin mi?';

  @override
  String get deleteConfirmBodySynced =>
      'Hedeflerin, planların, ilerleme kayıtların, sonuçların ve ayarların bu cihazdan ve hesabından (yani diğer cihazlarından da) kalıcı olarak silinir. Hesabın açık kalır. Bu işlem geri alınamaz. İstersen önce verilerini dışa aktar.';

  @override
  String get deleteConfirmBody =>
      'Hedeflerin, planların, ilerleme kayıtların, sonuçların ve ayarların bu cihazdan kalıcı olarak silinir. Bu işlem geri alınamaz. İstersen önce verilerini dışa aktar.';

  @override
  String get deleteConfirm => 'Kalıcı olarak sil';

  @override
  String get dataDeleted => 'Tüm veriler silindi';

  @override
  String get settingsAccount => 'Hesap ve eşitleme';

  @override
  String get accountHint =>
      'Hedeflerin hesabında saklanır; telefonunda ve web\'de aynı görünür. İnternet yokken de çalışır, bağlantı gelince eşitlenir.';

  @override
  String get accountDisabled =>
      'Bu sürümde hesap ve eşitleme kapalı; veriler yalnızca bu cihazda.';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get passwordLabel => 'Şifre (en az 8 karakter)';

  @override
  String get signInAction => 'Giriş yap';

  @override
  String get signUpAction => 'Hesap oluştur';

  @override
  String get signInTagline =>
      'Haftalık hedeflerini gerçekçi bir günlük plana dönüştür.';

  @override
  String get signInSwitchToSignUp => 'Hesabın yok mu? Hesap oluştur';

  @override
  String get signInSwitchToSignIn => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get signInSyncHint =>
      'Hedeflerin aynı hesapla telefonda ve webde eşitlenir.';

  @override
  String get authInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get authEmailTaken =>
      'Bu e-postayla zaten bir hesap var; giriş yapmayı dene.';

  @override
  String get authWeakPassword => 'Şifre en az 8 karakter olmalı.';

  @override
  String get authEmailNotConfirmed =>
      'Giriş yapmadan önce e-postanı onaylaman gerekiyor.';

  @override
  String authConfirmationSent(String email) {
    return '$email adresine bir onay bağlantısı gönderdik. Bağlantıya tıkladıktan sonra buradan giriş yap.';
  }

  @override
  String get authSamePassword => 'Yeni şifre eskisiyle aynı olamaz.';

  @override
  String get authTooManyRequests =>
      'Kısa sürede çok fazla deneme oldu. Birkaç dakika sonra tekrar dene.';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get resetTitle => 'Şifreni sıfırla';

  @override
  String get resetIntro =>
      'E-posta adresine bir sıfırlama bağlantısı göndereceğiz. Bağlantı Rota\'nın web sayfasını açar; yeni şifreni orada belirlersin.';

  @override
  String get resetSendCode => 'Bağlantı gönder';

  @override
  String resetCodeSent(String email) {
    return '$email adresine bir bağlantı gönderdik. Maildeki \"Reset password\" bağlantısına tıkla, açılan sayfada yeni şifreni belirle. Gelmediyse gereksiz (spam) klasörüne de bak.';
  }

  @override
  String get resetNewPasswordLabel => 'Yeni şifre (en az 8 karakter)';

  @override
  String get resetConfirm => 'Şifreyi kaydet';

  @override
  String get resetResend => 'Tekrar gönder';

  @override
  String get resetDone => 'Şifren değiştirildi.';

  @override
  String get newPasswordTitle => 'Yeni şifreni belirle';

  @override
  String get newPasswordBody =>
      'Sıfırlama bağlantısıyla geldin. Yeni şifreni kaydettikten sonra uygulamaya (telefonda da) bu şifreyle girersin.';

  @override
  String get authNetwork =>
      'Sunucuya ulaşılamadı. İnternet bağlantını kontrol et.';

  @override
  String get authUnknown => 'Giriş yapılamadı. Tekrar dene.';

  @override
  String get errorEmailInvalid => 'Geçerli bir e-posta adresi gir.';

  @override
  String signedInAs(String email) {
    return '$email olarak giriş yapıldı';
  }

  @override
  String syncStatusSynced(String time) {
    return 'Eşitlendi · $time';
  }

  @override
  String get syncStatusSyncing => 'Eşitleniyor…';

  @override
  String get syncStatusOffline =>
      'Çevrimdışı: değişiklikler bu cihazda bekliyor, bağlantı gelince gönderilecek.';

  @override
  String get syncStatusError =>
      'Sunucu bir değişikliği kabul etmedi; değişikliklerin bu cihazda duruyor.';

  @override
  String get syncStatusConflict =>
      'Bu cihaz ve hesabın farklı değişiklikler içeriyor.';

  @override
  String get syncNow => 'Şimdi eşitle';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get signOutHint =>
      'Verilerin hesabında durur; tekrar giriş yapınca geri gelir.';

  @override
  String get signOutUnsentTitle => 'Gönderilmemiş değişiklikler var';

  @override
  String get signOutUnsentBody =>
      'Bu cihazdaki son değişikliklerin henüz hesabına ulaşmadı (bağlantı yok). Çıkış yaparsan, aynı hesapla yeniden girdiğinde gönderilirler; başka bir hesapla girilirse bu değişiklikler kaybolur.';

  @override
  String get signOutAnyway => 'Yine de çıkış yap';

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get deleteAccountConfirmTitle => 'Hesap silinsin mi?';

  @override
  String get deleteAccountConfirmBody =>
      'Hesabın ve sunucudaki bütün verilerin kalıcı olarak silinir; bu cihazdaki veriler de temizlenir. Bu işlem geri alınamaz.';

  @override
  String get deleteAccountConfirm => 'Hesabı kalıcı olarak sil';

  @override
  String get accountDeleted => 'Hesap silindi';

  @override
  String get conflictTitle => 'Hangi sürüm kullanılsın?';

  @override
  String get conflictBody =>
      'Son eşitlemeden sonra hem bu cihazda hem hesabında farklı değişiklikler yapılmış. Seçtiğin tarafın planları ve ayarları kullanılır; iki taraftaki ilerleme kayıtları korunur.';

  @override
  String get conflictKeepDevice => 'Bu cihazdakini kullan';

  @override
  String get conflictKeepAccount => 'Hesaptakini kullan';

  @override
  String conflictUnmatched(String count) {
    return '$count ilerleme kaydı, seçilen tarafta olmayan hedeflere ait olduğu için eklenemedi.';
  }

  @override
  String get conflictResolved => 'Eşitleme tamamlandı';

  @override
  String get syncConflictBanner =>
      'Eşitleme çakışması: hangi sürümün kullanılacağını seç.';

  @override
  String get chooseAction => 'Seç';
}
