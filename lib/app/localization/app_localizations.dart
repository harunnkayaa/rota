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

  /// No description provided for @inMemoryNotice.
  ///
  /// In tr, this message translates to:
  /// **'Veriler şimdilik yalnızca bu oturumda tutulur; sayfa yenilenince silinir.'**
  String get inMemoryNotice;

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

  /// No description provided for @unallocated.
  ///
  /// In tr, this message translates to:
  /// **'Günlere dağıtılmamış: {amount}'**
  String unallocated(String amount);

  /// No description provided for @overAllocated.
  ///
  /// In tr, this message translates to:
  /// **'Hedeften {amount} fazla planlandı'**
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
  /// **'Yeni haftalık hedef'**
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
