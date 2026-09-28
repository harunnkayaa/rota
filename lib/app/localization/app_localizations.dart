import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rota'**
  String get appTitle;

  /// No description provided for @navToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get navToday;

  /// No description provided for @navWeek.
  ///
  /// In tr, this message translates to:
  /// **'Hafta'**
  String get navWeek;

  /// No description provided for @addGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef ekle'**
  String get addGoal;

  /// No description provided for @emptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz hedefin yok'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık bir hedef oluştur ve günlere dağıt. Rota, her gün yaptığın çalışmanın haftalık hedefine nasıl yansıdığını gösterir.'**
  String get emptyBody;

  /// No description provided for @createGoalCta.
  ///
  /// In tr, this message translates to:
  /// **'Hedef oluştur'**
  String get createGoalCta;

  /// No description provided for @loadSampleCta.
  ///
  /// In tr, this message translates to:
  /// **'Örnek haftayı yükle'**
  String get loadSampleCta;

  /// No description provided for @summaryPlanned.
  ///
  /// In tr, this message translates to:
  /// **'Planlanan'**
  String get summaryPlanned;

  /// No description provided for @summaryDone.
  ///
  /// In tr, this message translates to:
  /// **'Gerçekleşen'**
  String get summaryDone;

  /// No description provided for @summaryCapacityLeft.
  ///
  /// In tr, this message translates to:
  /// **'Boş kapasite'**
  String get summaryCapacityLeft;

  /// No description provided for @capacityOver.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün planı kapasiteni {amount} aşıyor.'**
  String capacityOver(String amount);

  /// No description provided for @progressOf.
  ///
  /// In tr, this message translates to:
  /// **'{done} / {target}'**
  String progressOf(String done, String target);

  /// No description provided for @todayLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get todayLabel;

  /// No description provided for @weekLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta'**
  String get weekLabel;

  /// No description provided for @todayNoPlan.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için plan yok'**
  String get todayNoPlan;

  /// No description provided for @flexibleChip.
  ///
  /// In tr, this message translates to:
  /// **'Esnek'**
  String get flexibleChip;

  /// No description provided for @addProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme ekle'**
  String get addProgress;

  /// No description provided for @goalDebt.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın planında {amount} açıkta kaldı.'**
  String goalDebt(String amount);

  /// No description provided for @redistribute.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dağıt'**
  String get redistribute;

  /// No description provided for @addProgressTitle.
  ///
  /// In tr, this message translates to:
  /// **'{goal} için ilerleme'**
  String addProgressTitle(String goal);

  /// No description provided for @customMinutesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dakika'**
  String get customMinutesLabel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @progressAdded.
  ///
  /// In tr, this message translates to:
  /// **'{amount} eklendi'**
  String progressAdded(String amount);

  /// No description provided for @errorMinutesInvalid.
  ///
  /// In tr, this message translates to:
  /// **'1 ile 1440 arasında bir dakika değeri gir.'**
  String get errorMinutesInvalid;

  /// No description provided for @errorPeriodClosed.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönem kapandı; yeni ilerleme eklenemez.'**
  String get errorPeriodClosed;

  /// No description provided for @errorDateOutside.
  ///
  /// In tr, this message translates to:
  /// **'Bugün bu hedefin dönemi içinde değil.'**
  String get errorDateOutside;

  /// No description provided for @errorProgressGeneric.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme kaydedilemedi. Tekrar dene.'**
  String get errorProgressGeneric;

  /// No description provided for @redistributeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dağıtma önerisi'**
  String get redistributeTitle;

  /// No description provided for @strategyEven.
  ///
  /// In tr, this message translates to:
  /// **'Eşit'**
  String get strategyEven;

  /// No description provided for @strategyCapacity.
  ///
  /// In tr, this message translates to:
  /// **'Boş kapasiteye göre'**
  String get strategyCapacity;

  /// No description provided for @includeToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünü de dahil et'**
  String get includeToday;

  /// No description provided for @redistributeFeasible.
  ///
  /// In tr, this message translates to:
  /// **'{deficit} mevcut planın dışında kaldı. Kalan günlere şöyle dağıtılabilir:'**
  String redistributeFeasible(String deficit);

  /// No description provided for @redistributeInfeasible.
  ///
  /// In tr, this message translates to:
  /// **'{deficit} planın dışında kaldı, ancak kalan günlerde yalnızca {capacity} boş kapasite var. {shortfall} bu haftaya sığmıyor. Aşağıdaki kısmı planlayabilir, hedefi azaltmayı ya da başka bir esnek hedefi düşürmeyi düşünebilirsin.'**
  String redistributeInfeasible(
    String deficit,
    String capacity,
    String shortfall,
  );

  /// No description provided for @redistributeNoDays.
  ///
  /// In tr, this message translates to:
  /// **'{deficit} planın dışında kaldı, ancak bu dönemde boş kapasitesi olan gün kalmadı.'**
  String redistributeNoDays(String deficit);

  /// No description provided for @notAllowedFixed.
  ///
  /// In tr, this message translates to:
  /// **'Sabit saatli hedefler yeniden dağıtılmaz.'**
  String get notAllowedFixed;

  /// No description provided for @notAllowedNothing.
  ///
  /// In tr, this message translates to:
  /// **'Dağıtılacak eksik yok; plan hedefi karşılıyor.'**
  String get notAllowedNothing;

  /// No description provided for @notAllowedClosed.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönem kapandı.'**
  String get notAllowedClosed;

  /// No description provided for @applyPlan.
  ///
  /// In tr, this message translates to:
  /// **'Planı uygula'**
  String get applyPlan;

  /// No description provided for @planApplied.
  ///
  /// In tr, this message translates to:
  /// **'Plan güncellendi'**
  String get planApplied;

  /// No description provided for @addition.
  ///
  /// In tr, this message translates to:
  /// **'+{amount}'**
  String addition(String amount);

  /// No description provided for @weekTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hafta'**
  String get weekTitle;

  /// No description provided for @weekRange.
  ///
  /// In tr, this message translates to:
  /// **'{start} – {end}'**
  String weekRange(String start, String end);

  /// No description provided for @weekNoGoals.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta için hedef yok.'**
  String get weekNoGoals;

  /// No description provided for @capacityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kapasite'**
  String get capacityTitle;

  /// No description provided for @capacityOfDay.
  ///
  /// In tr, this message translates to:
  /// **'{planned} / {capacity}'**
  String capacityOfDay(String planned, String capacity);

  /// No description provided for @capacityDayOver.
  ///
  /// In tr, this message translates to:
  /// **'{amount} fazla'**
  String capacityDayOver(String amount);

  /// No description provided for @overAllocated.
  ///
  /// In tr, this message translates to:
  /// **'Kalan hedeften {amount} fazla planlandı.'**
  String overAllocated(String amount);

  /// No description provided for @dayStatusDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get dayStatusDone;

  /// No description provided for @dayStatusMissed.
  ///
  /// In tr, this message translates to:
  /// **'{amount} eksik'**
  String dayStatusMissed(String amount);

  /// No description provided for @dayStatusToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get dayStatusToday;

  /// No description provided for @dayStatusUpcoming.
  ///
  /// In tr, this message translates to:
  /// **'Planlandı'**
  String get dayStatusUpcoming;

  /// No description provided for @createGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni hedef'**
  String get createGoalTitle;

  /// No description provided for @sectionCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get sectionCategory;

  /// No description provided for @newCategory.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kategori'**
  String get newCategory;

  /// No description provided for @newCategoryName.
  ///
  /// In tr, this message translates to:
  /// **'Kategori adı'**
  String get newCategoryName;

  /// No description provided for @sectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedef adı'**
  String get sectionTitle;

  /// No description provided for @titleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Rota MVP geliştirme'**
  String get titleHint;

  /// No description provided for @sectionTarget.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık hedef'**
  String get sectionTarget;

  /// No description provided for @hoursLabel.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get hoursLabel;

  /// No description provided for @minutesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dakika'**
  String get minutesLabel;

  /// No description provided for @sectionDays.
  ///
  /// In tr, this message translates to:
  /// **'Günlere dağıt'**
  String get sectionDays;

  /// No description provided for @daysHint.
  ///
  /// In tr, this message translates to:
  /// **'Hedef seçtiğin günlere eşit dağıtılır. Geçmiş günler seçilemez.'**
  String get daysHint;

  /// No description provided for @sectionPreview.
  ///
  /// In tr, this message translates to:
  /// **'Günlük plan'**
  String get sectionPreview;

  /// No description provided for @capacityWarningDay.
  ///
  /// In tr, this message translates to:
  /// **'{day}: kapasite {amount} aşılacak'**
  String capacityWarningDay(String day, String amount);

  /// No description provided for @createGoalSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Hedefi oluştur'**
  String get createGoalSubmit;

  /// No description provided for @errorPickCategory.
  ///
  /// In tr, this message translates to:
  /// **'Bir kategori seç.'**
  String get errorPickCategory;

  /// No description provided for @errorTitleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Hedef adı gerekli.'**
  String get errorTitleRequired;

  /// No description provided for @errorTargetRequired.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık hedef 0\'dan büyük ve bir haftadan kısa olmalı.'**
  String get errorTargetRequired;

  /// No description provided for @errorPickDays.
  ///
  /// In tr, this message translates to:
  /// **'En az bir gün seç.'**
  String get errorPickDays;

  /// No description provided for @goalCreated.
  ///
  /// In tr, this message translates to:
  /// **'Hedef oluşturuldu'**
  String get goalCreated;

  /// No description provided for @durationMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String durationMinutes(String minutes);

  /// No description provided for @durationHours.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa'**
  String durationHours(String hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk'**
  String durationHoursMinutes(String hours, String minutes);

  /// No description provided for @categoryWork.
  ///
  /// In tr, this message translates to:
  /// **'İş hayatı'**
  String get categoryWork;

  /// No description provided for @categoryJobApplication.
  ///
  /// In tr, this message translates to:
  /// **'İş başvurusu'**
  String get categoryJobApplication;

  /// No description provided for @categoryInterview.
  ///
  /// In tr, this message translates to:
  /// **'Mülakat'**
  String get categoryInterview;

  /// No description provided for @categoryProjectDevelopment.
  ///
  /// In tr, this message translates to:
  /// **'Proje geliştirme'**
  String get categoryProjectDevelopment;

  /// No description provided for @categoryGraduateStudy.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek lisans / ders'**
  String get categoryGraduateStudy;

  /// No description provided for @categoryLanguage.
  ///
  /// In tr, this message translates to:
  /// **'PTE / dil'**
  String get categoryLanguage;

  /// No description provided for @categoryReading.
  ///
  /// In tr, this message translates to:
  /// **'Kitap'**
  String get categoryReading;

  /// No description provided for @categorySport.
  ///
  /// In tr, this message translates to:
  /// **'Spor'**
  String get categorySport;

  /// No description provided for @categoryHealthMedication.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık / ilaç'**
  String get categoryHealthMedication;

  /// No description provided for @categoryBrainTraining.
  ///
  /// In tr, this message translates to:
  /// **'Beyin jimnastiği'**
  String get categoryBrainTraining;

  /// No description provided for @categoryWorship.
  ///
  /// In tr, this message translates to:
  /// **'Namaz / ibadet'**
  String get categoryWorship;

  /// No description provided for @categoryPersonal.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel'**
  String get categoryPersonal;

  /// No description provided for @sampleProjectGoal.
  ///
  /// In tr, this message translates to:
  /// **'Rota MVP geliştirme'**
  String get sampleProjectGoal;

  /// No description provided for @sampleLanguageGoal.
  ///
  /// In tr, this message translates to:
  /// **'PTE hazırlık'**
  String get sampleLanguageGoal;

  /// No description provided for @loadingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Veriler yükleniyor'**
  String get loadingLabel;

  /// No description provided for @loadFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı verilerin okunamadı'**
  String get loadFailedTitle;

  /// No description provided for @loadFailedBody.
  ///
  /// In tr, this message translates to:
  /// **'Verilerin silinmedi ve üzerine yazılmadı. Tekrar deneyebilirsin; sorun sürerse uygulamanın güncellenmesi gerekebilir.'**
  String get loadFailedBody;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @saveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Son değişiklik bu cihaza kaydedilemedi.'**
  String get saveFailed;

  /// No description provided for @editTodayPlan.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün planı'**
  String get editTodayPlan;

  /// No description provided for @editWeekPlan.
  ///
  /// In tr, this message translates to:
  /// **'Haftanın planı'**
  String get editWeekPlan;

  /// No description provided for @editPlanTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Planı düzenle'**
  String get editPlanTooltip;

  /// No description provided for @remainingToday.
  ///
  /// In tr, this message translates to:
  /// **'Kalan {amount}'**
  String remainingToday(String amount);

  /// No description provided for @summaryRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Kalan'**
  String get summaryRemaining;

  /// No description provided for @todayRingSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {done} / {planned} tamamlandı'**
  String todayRingSemantics(String done, String planned);

  /// No description provided for @planDistributed.
  ///
  /// In tr, this message translates to:
  /// **'Planlanan {planned} / {target}'**
  String planDistributed(String planned, String target);

  /// No description provided for @planUnallocated.
  ///
  /// In tr, this message translates to:
  /// **'{amount} henüz günlere dağıtılmadı.'**
  String planUnallocated(String amount);

  /// No description provided for @planOverTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedeften {amount} fazla planladın.'**
  String planOverTarget(String amount);

  /// No description provided for @planDebt.
  ///
  /// In tr, this message translates to:
  /// **'Plan, kalan hedefin {amount} kısmını karşılamıyor.'**
  String planDebt(String amount);

  /// No description provided for @planCovers.
  ///
  /// In tr, this message translates to:
  /// **'Plan haftalık hedefi karşılıyor.'**
  String get planCovers;

  /// No description provided for @distributeEvenlyAction.
  ///
  /// In tr, this message translates to:
  /// **'Eşit dağıt'**
  String get distributeEvenlyAction;

  /// No description provided for @matchTargetToPlan.
  ///
  /// In tr, this message translates to:
  /// **'Hedefi toplama eşitle'**
  String get matchTargetToPlan;

  /// No description provided for @clearPlan.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clearPlan;

  /// No description provided for @decreaseBy.
  ///
  /// In tr, this message translates to:
  /// **'{amount} azalt'**
  String decreaseBy(String amount);

  /// No description provided for @increaseBy.
  ///
  /// In tr, this message translates to:
  /// **'{amount} artır'**
  String increaseBy(String amount);

  /// No description provided for @durationFieldSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{label}: {value}. Değiştirmek için dokun.'**
  String durationFieldSemantics(String label, String value);

  /// No description provided for @durationSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'{label} için süre'**
  String durationSheetTitle(String label);

  /// No description provided for @errorDurationMax.
  ///
  /// In tr, this message translates to:
  /// **'En fazla {max} girilebilir.'**
  String errorDurationMax(String max);

  /// No description provided for @pastDayLocked.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş gün · {done} / {planned}'**
  String pastDayLocked(String done, String planned);

  /// No description provided for @sectionDailyPlan.
  ///
  /// In tr, this message translates to:
  /// **'Günlük plan'**
  String get sectionDailyPlan;

  /// No description provided for @dailyPlanHint.
  ///
  /// In tr, this message translates to:
  /// **'Her gün için ayrı süre belirle. Sonra Bugün ya da Hafta ekranından değiştirebilirsin.'**
  String get dailyPlanHint;

  /// No description provided for @weekTargetHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta toplam ne kadar çalışmak istiyorsun?'**
  String get weekTargetHint;

  /// No description provided for @capacityRowOver.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kapasite {amount} aşılıyor'**
  String capacityRowOver(String amount);

  /// No description provided for @hoursCompact.
  ///
  /// In tr, this message translates to:
  /// **'{value} sa'**
  String hoursCompact(String value);

  /// No description provided for @dayCellSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{day}: {value}, {status}'**
  String dayCellSemantics(String day, String value, String status);

  /// No description provided for @dayStatusNoPlan.
  ///
  /// In tr, this message translates to:
  /// **'Plan yok'**
  String get dayStatusNoPlan;

  /// No description provided for @errorPlanPast.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş günlerin planı değiştirilemez.'**
  String get errorPlanPast;

  /// No description provided for @errorPlanGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Plan kaydedilemedi. Tekrar dene.'**
  String get errorPlanGeneric;

  /// No description provided for @weekdayToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get weekdayToday;

  /// No description provided for @todayProgressOf.
  ///
  /// In tr, this message translates to:
  /// **'/ {planned}'**
  String todayProgressOf(String planned);

  /// No description provided for @sectionWeeklyTarget.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık hedef'**
  String get sectionWeeklyTarget;

  /// No description provided for @planRemainingOf.
  ///
  /// In tr, this message translates to:
  /// **'Kalan plan {planned} / kalan hedef {target}'**
  String planRemainingOf(String planned, String target);

  /// No description provided for @planOverRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Kalan hedeften {amount} fazla planladın.'**
  String planOverRemaining(String amount);

  /// No description provided for @planCoversRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Plan, haftanın kalanını karşılıyor.'**
  String get planCoversRemaining;

  /// No description provided for @dayPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'{day} planı'**
  String dayPlanTitle(String day);

  /// No description provided for @sectionGoalKind.
  ///
  /// In tr, this message translates to:
  /// **'Hedef türü'**
  String get sectionGoalKind;

  /// No description provided for @goalKindWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get goalKindWeekly;

  /// No description provided for @goalKindDeadline.
  ///
  /// In tr, this message translates to:
  /// **'Tarihli'**
  String get goalKindDeadline;

  /// No description provided for @goalKindWeeklyHint.
  ///
  /// In tr, this message translates to:
  /// **'Her hafta tekrarlanan çalışma: haftada 10 sa proje.'**
  String get goalKindWeeklyHint;

  /// No description provided for @goalKindDeadlineHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir tarihe yetişmesi gereken iş: 15 Kasım\'daki sınava 40 sa hazırlık.'**
  String get goalKindDeadlineHint;

  /// No description provided for @sectionDueDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get sectionDueDate;

  /// No description provided for @dueDateHint.
  ///
  /// In tr, this message translates to:
  /// **'Sınav, mülakat veya teslim günü. Çalışma bu günden öncesine planlanır.'**
  String get dueDateHint;

  /// No description provided for @pickDueDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get pickDueDate;

  /// No description provided for @dueDateValue.
  ///
  /// In tr, this message translates to:
  /// **'{date} · {days} gün kaldı'**
  String dueDateValue(String date, String days);

  /// No description provided for @sectionTotalTarget.
  ///
  /// In tr, this message translates to:
  /// **'Toplam hedef'**
  String get sectionTotalTarget;

  /// No description provided for @totalTargetHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarihe kadar toplam ne kadar çalışmak istiyorsun?'**
  String get totalTargetHint;

  /// No description provided for @errorDueDate.
  ///
  /// In tr, this message translates to:
  /// **'Bugünden sonraki bir tarih seç.'**
  String get errorDueDate;

  /// No description provided for @errorTotalRequired.
  ///
  /// In tr, this message translates to:
  /// **'Toplam hedef 0\'dan büyük olmalı.'**
  String get errorTotalRequired;

  /// No description provided for @pacePerWeek.
  ///
  /// In tr, this message translates to:
  /// **'Haftada ~{amount} gerekiyor'**
  String pacePerWeek(String amount);

  /// No description provided for @paceFeasible.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kapasitenle bu tarihe yetişebilirsin.'**
  String get paceFeasible;

  /// No description provided for @paceShortfall.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kapasitenle {amount} eksik kalır.'**
  String paceShortfall(String amount);

  /// No description provided for @pickDateFirst.
  ///
  /// In tr, this message translates to:
  /// **'Günlük planı görmek için önce tarihi ve toplam hedefi seç.'**
  String get pickDateFirst;

  /// No description provided for @weekPaceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın temposu'**
  String get weekPaceLabel;

  /// No description provided for @totalLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get totalLabel;

  /// No description provided for @deadlineStatusOnTrack.
  ///
  /// In tr, this message translates to:
  /// **'Yolunda'**
  String get deadlineStatusOnTrack;

  /// No description provided for @deadlineStatusBehind.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta {amount} açık'**
  String deadlineStatusBehind(String amount);

  /// No description provided for @deadlineStatusNotFeasible.
  ///
  /// In tr, this message translates to:
  /// **'{amount} eksik kalıyor'**
  String deadlineStatusNotFeasible(String amount);

  /// No description provided for @deadlineStatusCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get deadlineStatusCompleted;

  /// No description provided for @deadlineStatusOverdue.
  ///
  /// In tr, this message translates to:
  /// **'Tarih geçti'**
  String get deadlineStatusOverdue;

  /// No description provided for @paceBehindNotice.
  ///
  /// In tr, this message translates to:
  /// **'Tempoya yetişmek için bu hafta {amount} daha planlaman gerekiyor.'**
  String paceBehindNotice(String amount);

  /// No description provided for @paceNotFeasibleNotice.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut planla {date} tarihine {amount} eksikle varırsın.'**
  String paceNotFeasibleNotice(String date, String amount);

  /// No description provided for @paceOptions.
  ///
  /// In tr, this message translates to:
  /// **'Seçenekler'**
  String get paceOptions;

  /// No description provided for @catchUpTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tempoyu yakala'**
  String get catchUpTitle;

  /// No description provided for @catchUpGap.
  ///
  /// In tr, this message translates to:
  /// **'Tempoya yetişmek için bu hafta {amount} daha gerekiyor.'**
  String catchUpGap(String amount);

  /// No description provided for @catchUpFromFree.
  ///
  /// In tr, this message translates to:
  /// **'Boş zamanından'**
  String get catchUpFromFree;

  /// No description provided for @catchUpFromOthers.
  ///
  /// In tr, this message translates to:
  /// **'Diğer hedeflerden'**
  String get catchUpFromOthers;

  /// No description provided for @catchUpDonorsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başka hedeften süre al'**
  String get catchUpDonorsTitle;

  /// No description provided for @catchUpDonorsHint.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin hedefin bu haftaki planından alınır; o günün toplam yükü değişmez.'**
  String get catchUpDonorsHint;

  /// No description provided for @catchUpDonorPlanned.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta {amount} planlı'**
  String catchUpDonorPlanned(String amount);

  /// No description provided for @catchUpShortfall.
  ///
  /// In tr, this message translates to:
  /// **'{amount} bu haftaya sığmıyor. Başka bir hedeften süre alabilir ya da toplam hedefi düşürebilirsin.'**
  String catchUpShortfall(String amount);

  /// No description provided for @catchUpNoDays.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta telafi edilecek gün kalmadı; tempo gelecek haftaya yansıyacak.'**
  String get catchUpNoDays;

  /// No description provided for @catchUpNothingNeeded.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın temposu karşılanıyor.'**
  String get catchUpNothingNeeded;

  /// No description provided for @catchUpReduction.
  ///
  /// In tr, this message translates to:
  /// **'{goal}: −{amount}'**
  String catchUpReduction(String goal, String amount);

  /// No description provided for @changeTotalTarget.
  ///
  /// In tr, this message translates to:
  /// **'Toplam hedefi değiştir'**
  String get changeTotalTarget;

  /// No description provided for @targetUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Hedef güncellendi'**
  String get targetUpdated;

  /// No description provided for @planWeekPaceOf.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta planlanan {planned} / tempo {target}'**
  String planWeekPaceOf(String planned, String target);

  /// No description provided for @planWeekPaceMissing.
  ///
  /// In tr, this message translates to:
  /// **'Tempo için bu hafta {amount} daha planla.'**
  String planWeekPaceMissing(String amount);

  /// No description provided for @planWeekPaceOver.
  ///
  /// In tr, this message translates to:
  /// **'Tempodan {amount} fazla planladın.'**
  String planWeekPaceOver(String amount);

  /// No description provided for @planWeekPaceCovers.
  ///
  /// In tr, this message translates to:
  /// **'Plan bu haftanın temposunu karşılıyor.'**
  String get planWeekPaceCovers;

  /// No description provided for @navReports.
  ///
  /// In tr, this message translates to:
  /// **'Rapor'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get navSettings;

  /// No description provided for @reviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçen hafta kapandı'**
  String get reviewTitle;

  /// No description provided for @reviewBody.
  ///
  /// In tr, this message translates to:
  /// **'{count} hedefin sonucu hazır. Eksik kalan süre sen istemedikçe taşınmaz.'**
  String reviewBody(String count);

  /// No description provided for @reviewOpen.
  ///
  /// In tr, this message translates to:
  /// **'Özeti gör'**
  String get reviewOpen;

  /// No description provided for @reviewSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hafta özeti'**
  String get reviewSheetTitle;

  /// No description provided for @reviewShortfall.
  ///
  /// In tr, this message translates to:
  /// **'{amount} eksik kaldı'**
  String reviewShortfall(String amount);

  /// No description provided for @carryOverAction.
  ///
  /// In tr, this message translates to:
  /// **'{amount} bu haftaya ekle'**
  String carryOverAction(String amount);

  /// No description provided for @carryOverDone.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftaya eklendi'**
  String get carryOverDone;

  /// No description provided for @reviewAcknowledge.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get reviewAcknowledge;

  /// No description provided for @moreActions.
  ///
  /// In tr, this message translates to:
  /// **'Diğer işlemler'**
  String get moreActions;

  /// No description provided for @archiveGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedefi arşivle'**
  String get archiveGoal;

  /// No description provided for @archiveConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedef arşivlensin mi?'**
  String get archiveConfirmTitle;

  /// No description provided for @archiveConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Bugün ve Hafta ekranlarından kalkar ve yeni haftalara açılmaz. Geçmiş sonuçları raporlarda kalır.'**
  String get archiveConfirmBody;

  /// No description provided for @archiveConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get archiveConfirm;

  /// No description provided for @goalArchived.
  ///
  /// In tr, this message translates to:
  /// **'Hedef arşivlendi'**
  String get goalArchived;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsCapacity.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kapasite'**
  String get settingsCapacity;

  /// No description provided for @settingsCapacityHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir günde gerçekçi olarak planlayabileceğin süre. Plan bunu aşarsa uyarı alırsın.'**
  String get settingsCapacityHint;

  /// No description provided for @settingsDefaultCapacity.
  ///
  /// In tr, this message translates to:
  /// **'Her gün'**
  String get settingsDefaultCapacity;

  /// No description provided for @settingsWeekdayCapacity.
  ///
  /// In tr, this message translates to:
  /// **'Güne özel kapasite'**
  String get settingsWeekdayCapacity;

  /// No description provided for @settingsWeekdayHint.
  ///
  /// In tr, this message translates to:
  /// **'Farklı olan günleri ayarla; diğerleri \"Her gün\" değerini kullanır.'**
  String get settingsWeekdayHint;

  /// No description provided for @settingsResetDay.
  ///
  /// In tr, this message translates to:
  /// **'{day} için özel kapasiteyi kaldır'**
  String settingsResetDay(String day);

  /// No description provided for @settingsWeekStart.
  ///
  /// In tr, this message translates to:
  /// **'Hafta başlangıcı'**
  String get settingsWeekStart;

  /// No description provided for @settingsWeekStartHint.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklik bir sonraki haftadan itibaren geçerli olur.'**
  String get settingsWeekStartHint;

  /// No description provided for @settingsDataTitle.
  ///
  /// In tr, this message translates to:
  /// **'Verilerin'**
  String get settingsDataTitle;

  /// No description provided for @settingsDataBody.
  ///
  /// In tr, this message translates to:
  /// **'Veriler şu an yalnızca bu cihazda saklanıyor. Cihazlar arası senkronizasyon bir sonraki aşamada gelecek.'**
  String get settingsDataBody;

  /// No description provided for @focusStart.
  ///
  /// In tr, this message translates to:
  /// **'Odaklan'**
  String get focusStart;

  /// No description provided for @focusTitle.
  ///
  /// In tr, this message translates to:
  /// **'Odak'**
  String get focusTitle;

  /// No description provided for @focusPause.
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get focusPause;

  /// No description provided for @focusResume.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get focusResume;

  /// No description provided for @focusFinish.
  ///
  /// In tr, this message translates to:
  /// **'Bitir ve kaydet'**
  String get focusFinish;

  /// No description provided for @focusCancel.
  ///
  /// In tr, this message translates to:
  /// **'Oturumu iptal et'**
  String get focusCancel;

  /// No description provided for @focusPaused.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı'**
  String get focusPaused;

  /// No description provided for @focusRecorded.
  ///
  /// In tr, this message translates to:
  /// **'{amount} kaydedildi'**
  String focusRecorded(String amount);

  /// No description provided for @focusTooShort.
  ///
  /// In tr, this message translates to:
  /// **'1 dakikadan kısa çalışma kaydedilmedi.'**
  String get focusTooShort;

  /// No description provided for @focusCancelConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oturum iptal edilsin mi?'**
  String get focusCancelConfirmTitle;

  /// No description provided for @focusCancelConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu oturumdaki süre kaydedilmez.'**
  String get focusCancelConfirmBody;

  /// No description provided for @focusCancelConfirm.
  ///
  /// In tr, this message translates to:
  /// **'İptal et'**
  String get focusCancelConfirm;

  /// No description provided for @focusRunning.
  ///
  /// In tr, this message translates to:
  /// **'Odak sürüyor'**
  String get focusRunning;

  /// No description provided for @focusOpen.
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get focusOpen;

  /// No description provided for @focusAnotherRunning.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir hedefte odak oturumu sürüyor.'**
  String get focusAnotherRunning;

  /// No description provided for @focusPeriodEnded.
  ///
  /// In tr, this message translates to:
  /// **'Bu hedefin dönemi bitti; süre kaydedilemedi. Oturumu iptal edip ilerlemeyi yeni haftaya elle ekleyebilirsin.'**
  String get focusPeriodEnded;

  /// No description provided for @focusTimerSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Geçen süre {time}'**
  String focusTimerSemantics(String time);

  /// No description provided for @reportsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rapor'**
  String get reportsTitle;

  /// No description provided for @reportsThisWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta'**
  String get reportsThisWeek;

  /// No description provided for @reportsTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get reportsTarget;

  /// No description provided for @reportsCompletion.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanma'**
  String get reportsCompletion;

  /// No description provided for @reportsPercent.
  ///
  /// In tr, this message translates to:
  /// **'%{value}'**
  String reportsPercent(String value);

  /// No description provided for @reportsByCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriye göre'**
  String get reportsByCategory;

  /// No description provided for @reportsByCategoryHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta çalıştığın sürenin alanlara dağılımı.'**
  String get reportsByCategoryHint;

  /// No description provided for @reportsNoWorkYet.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta henüz ilerleme kaydedilmedi.'**
  String get reportsNoWorkYet;

  /// No description provided for @reportsHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş haftalar'**
  String get reportsHistory;

  /// No description provided for @reportsEmptyHistory.
  ///
  /// In tr, this message translates to:
  /// **'Kapanan haftaların sonuçları burada görünecek.'**
  String get reportsEmptyHistory;

  /// No description provided for @reportsChangeUp.
  ///
  /// In tr, this message translates to:
  /// **'Önceki haftadan {amount} fazla'**
  String reportsChangeUp(String amount);

  /// No description provided for @reportsChangeDown.
  ///
  /// In tr, this message translates to:
  /// **'Önceki haftadan {amount} az'**
  String reportsChangeDown(String amount);

  /// No description provided for @reportsChangeSame.
  ///
  /// In tr, this message translates to:
  /// **'Önceki haftayla aynı'**
  String get reportsChangeSame;

  /// No description provided for @reportsDeadlines.
  ///
  /// In tr, this message translates to:
  /// **'Tarihli hedefler'**
  String get reportsDeadlines;

  /// No description provided for @weekPaceShort.
  ///
  /// In tr, this message translates to:
  /// **'tempo'**
  String get weekPaceShort;

  /// No description provided for @reminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rota'**
  String get reminderTitle;

  /// No description provided for @reminderTodayBody.
  ///
  /// In tr, this message translates to:
  /// **'{goal}: bugün {amount} kaldı.'**
  String reminderTodayBody(String goal, String amount);

  /// No description provided for @reminderPaceBody.
  ///
  /// In tr, this message translates to:
  /// **'{goal}: tempo için bu hafta {amount} daha gerekiyor.'**
  String reminderPaceBody(String goal, String amount);

  /// No description provided for @reminderHiddenBody.
  ///
  /// In tr, this message translates to:
  /// **'Planlanmış kişisel hatırlatıcın var.'**
  String get reminderHiddenBody;

  /// No description provided for @settingsReminders.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmalar'**
  String get settingsReminders;

  /// No description provided for @settingsRemindersHint.
  ///
  /// In tr, this message translates to:
  /// **'Akşam, bugün henüz çalışmadığın süreyi hatırlatır. Planını tamamladıysan bildirim gelmez.'**
  String get settingsRemindersHint;

  /// No description provided for @settingsRemindersEnable.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmaları aç'**
  String get settingsRemindersEnable;

  /// No description provided for @settingsReminderTime.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma saati'**
  String get settingsReminderTime;

  /// No description provided for @settingsQuietFrom.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz saat başlangıcı'**
  String get settingsQuietFrom;

  /// No description provided for @settingsQuietTo.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz saat bitişi'**
  String get settingsQuietTo;

  /// No description provided for @settingsDailyBudget.
  ///
  /// In tr, this message translates to:
  /// **'Günlük en fazla bildirim'**
  String get settingsDailyBudget;

  /// No description provided for @settingsShowSensitive.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık ve ibadet hedeflerinin adını göster'**
  String get settingsShowSensitive;

  /// No description provided for @settingsShowSensitiveHint.
  ///
  /// In tr, this message translates to:
  /// **'Kapalıyken kilit ekranında yalnızca \"Planlanmış kişisel hatırlatıcın var.\" yazar.'**
  String get settingsShowSensitiveHint;

  /// No description provided for @settingsPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim izni verilmedi. iPhone Ayarlar > Rota > Bildirimler bölümünden açabilirsin.'**
  String get settingsPermissionDenied;

  /// No description provided for @settingsRemindersWebNote.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmalar iPhone uygulamasında çalışır; web sürümü bildirim göndermez.'**
  String get settingsRemindersWebNote;

  /// No description provided for @settingsReminderInQuiet.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma saati sessiz saatlerin içinde; bu saatte bildirim gönderilmez.'**
  String get settingsReminderInQuiet;

  /// No description provided for @settingsExport.
  ///
  /// In tr, this message translates to:
  /// **'Verilerini dışa aktar'**
  String get settingsExport;

  /// No description provided for @settingsExportHint.
  ///
  /// In tr, this message translates to:
  /// **'Hedeflerin, planların, ilerlemen ve ayarların okunabilir JSON olarak.'**
  String get settingsExportHint;

  /// No description provided for @exportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarılan veri'**
  String get exportTitle;

  /// No description provided for @exportCopy.
  ///
  /// In tr, this message translates to:
  /// **'Panoya kopyala'**
  String get exportCopy;

  /// No description provided for @exportCopied.
  ///
  /// In tr, this message translates to:
  /// **'Veriler panoya kopyalandı'**
  String get exportCopied;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @settingsDelete.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileri sil'**
  String get settingsDelete;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm veriler silinsin mi?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Hedeflerin, planların, ilerleme kayıtların, sonuçların ve ayarların bu cihazdan kalıcı olarak silinir. Bu işlem geri alınamaz. İstersen önce verilerini dışa aktar.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı olarak sil'**
  String get deleteConfirm;

  /// No description provided for @dataDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Tüm veriler silindi'**
  String get dataDeleted;

  /// No description provided for @settingsAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap ve eşitleme'**
  String get settingsAccount;

  /// No description provided for @accountHint.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yaparsan hedeflerin telefonunda ve web\'de aynı olur. Hesap olmadan da her şey bu cihazda çalışır.'**
  String get accountHint;

  /// No description provided for @accountDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Bu sürümde hesap ve eşitleme kapalı; veriler yalnızca bu cihazda.'**
  String get accountDisabled;

  /// No description provided for @emailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (en az 8 karakter)'**
  String get passwordLabel;

  /// No description provided for @signInAction.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get signInAction;

  /// No description provided for @signUpAction.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluştur'**
  String get signUpAction;

  /// No description provided for @signInTagline.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık hedeflerini gerçekçi bir günlük plana dönüştür.'**
  String get signInTagline;

  /// No description provided for @signInSwitchToSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Hesap oluştur'**
  String get signInSwitchToSignUp;

  /// No description provided for @signInSwitchToSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get signInSwitchToSignIn;

  /// No description provided for @signInSyncHint.
  ///
  /// In tr, this message translates to:
  /// **'Hedeflerin aynı hesapla telefonda ve webde eşitlenir.'**
  String get signInSyncHint;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya şifre hatalı.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailTaken.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-postayla zaten bir hesap var; giriş yapmayı dene.'**
  String get authEmailTaken;

  /// No description provided for @authWeakPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 8 karakter olmalı.'**
  String get authWeakPassword;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapmadan önce e-postanı onaylaman gerekiyor.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authConfirmationSent.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine bir onay bağlantısı gönderdik. Bağlantıya tıkladıktan sonra buradan giriş yap.'**
  String authConfirmationSent(String email);

  /// No description provided for @authNetwork.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuya ulaşılamadı. İnternet bağlantını kontrol et.'**
  String get authNetwork;

  /// No description provided for @authUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılamadı. Tekrar dene.'**
  String get authUnknown;

  /// No description provided for @errorEmailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get errorEmailInvalid;

  /// No description provided for @signedInAs.
  ///
  /// In tr, this message translates to:
  /// **'{email} olarak giriş yapıldı'**
  String signedInAs(String email);

  /// No description provided for @syncStatusSynced.
  ///
  /// In tr, this message translates to:
  /// **'Eşitlendi · {time}'**
  String syncStatusSynced(String time);

  /// No description provided for @syncStatusSyncing.
  ///
  /// In tr, this message translates to:
  /// **'Eşitleniyor…'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusOffline.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı: değişiklikler bu cihazda bekliyor, bağlantı gelince gönderilecek.'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusError.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu bir değişikliği kabul etmedi; değişikliklerin bu cihazda duruyor.'**
  String get syncStatusError;

  /// No description provided for @syncStatusConflict.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihaz ve hesabın farklı değişiklikler içeriyor.'**
  String get syncStatusConflict;

  /// No description provided for @syncNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi eşitle'**
  String get syncNow;

  /// No description provided for @signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get signOut;

  /// No description provided for @signOutHint.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapınca verilerin bu cihazda kalır.'**
  String get signOutHint;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı sil'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinsin mi?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın ve sunucudaki bütün verilerin kalıcı olarak silinir; bu cihazdaki veriler de temizlenir. Bu işlem geri alınamaz.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı kalıcı olarak sil'**
  String get deleteAccountConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silindi'**
  String get accountDeleted;

  /// No description provided for @conflictTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi sürüm kullanılsın?'**
  String get conflictTitle;

  /// No description provided for @conflictBody.
  ///
  /// In tr, this message translates to:
  /// **'Son eşitlemeden sonra hem bu cihazda hem hesabında farklı değişiklikler yapılmış. Seçtiğin tarafın planları ve ayarları kullanılır; iki taraftaki ilerleme kayıtları korunur.'**
  String get conflictBody;

  /// No description provided for @conflictKeepDevice.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazdakini kullan'**
  String get conflictKeepDevice;

  /// No description provided for @conflictKeepAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesaptakini kullan'**
  String get conflictKeepAccount;

  /// No description provided for @conflictUnmatched.
  ///
  /// In tr, this message translates to:
  /// **'{count} ilerleme kaydı, seçilen tarafta olmayan hedeflere ait olduğu için eklenemedi.'**
  String conflictUnmatched(String count);

  /// No description provided for @conflictResolved.
  ///
  /// In tr, this message translates to:
  /// **'Eşitleme tamamlandı'**
  String get conflictResolved;

  /// No description provided for @syncConflictBanner.
  ///
  /// In tr, this message translates to:
  /// **'Eşitleme çakışması: hangi sürümün kullanılacağını seç.'**
  String get syncConflictBanner;

  /// No description provided for @chooseAction.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get chooseAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
