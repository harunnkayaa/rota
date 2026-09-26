# Rota — Product, Architecture and Engineering Constitution

> Bu dosya Rota projesinin ürün, mimari, güvenlik, kalite ve geliştirme kurallarının ana kaynağıdır.
> Claude veya projede çalışan başka bir geliştirici, herhangi bir değişiklik yapmadan önce bu dosyanın tamamını okumalıdır.
> Bu dosyayla çelişen geçici bir talep varsa çelişki açıkça belirtilmeli; sessizce kapsam veya mimari değiştirilmemelidir.

---

## 1. Projenin özeti

**Çalışma adı:** Rota  
**Ürün türü:** Kişisel hedef, planlama, odak ve ilerleme takip sistemi  
**Birincil platform:** iOS — özellikle iPhone 15  
**İkincil platform:** Web — masaüstü ve mobil tarayıcı  
**Dil:** İlk sürüm Türkçe; mimari İngilizce yerelleştirmeye hazır olmalı  
**Birincil kullanıcı:** Uygulamayı kendi günlük hayatında kullanacak tek kullanıcıyla başlar; mimari çok kullanıcılı ve güvenli olmalıdır.  
**Temel teknoloji yönü:** Flutter + Dart, Supabase Auth + PostgreSQL, yerel ve uzaktan bildirimler  

Rota klasik bir yapılacaklar listesi değildir. Ürünün merkezi, haftalık veya özel dönemli hedeflerle günlük hedefler arasında ölçülebilir ve açıklanabilir bir ilişki kurmaktır.

Örnek:

- Haftalık hedef: 10 saat proje geliştirme
- Pazartesi günlük hedefi: 2 saat proje geliştirme
- Pazartesi 90 dakika çalışılırsa:
  - Günlük hedef: 90/120 dakika
  - Haftalık hedef: 90/600 dakika
- Aynı çalışma iki kez sayılmamalıdır.
- Pazartesi hedefi tamamlanmazsa kalan miktar otomatik olarak kaybolmamalı veya sessizce devredilmemelidir.
- Sistem, kullanıcıya kalan süreyi ve yeniden planlama seçeneklerini göstermelidir.

---

## 2. Kullanıcı problemi

Kullanıcının temel problemi görevleri hatırlamamak değildir. Asıl problemler şunlardır:

1. İş arama, proje geliştirme, mülakat hazırlığı, yüksek lisans, PTE, spor, kitap ve kişisel rutinler arasında öncelik belirleyememek.
2. Haftalık hedeflerin günlük hayata nasıl dağıtılacağını bilememek.
3. Bir günlük hedef kaçırıldığında haftalık planın geri kalanını gerçekçi biçimde yeniden düzenleyememek.
4. Kapasitesinin üzerinde plan yapıp daha sonra başarısızlık hissi yaşamak.
5. Çalışılan gerçek süreyi, yalnızca tamamlandı kutusundan daha ayrıntılı görmek istemek.
6. Mobil cihazdan günlük uygulama, web üzerinden kapsamlı haftalık planlama ve raporlama yapmak istemek.
7. Bildirim almak fakat bildirim bombardımanına uğramamak.
8. İş, eğitim, sağlık, ibadet ve kişisel gelişim gibi farklı karaktere sahip hedefleri tek uygulamada, doğru davranış kurallarıyla yönetmek.

---

## 3. Ürün vizyonu

Rota'nın hedefi kullanıcıya daha fazla görev vermek değil, sınırlı zamanını gerçekçi biçimde dağıtmasına yardımcı olmaktır.

Ürün şu sorulara açık cevap vermelidir:

- Bugün ne yapmalıyım?
- Bu hedef hangi haftalık veya dönemsel amaca hizmet ediyor?
- Bu hafta ne kadar ilerledim?
- Bir hedefi kaçırırsam kalan plan nasıl etkileniyor?
- Kalan günlerde bu hedef hâlâ gerçekçi mi?
- Hangi alanı sürekli fazla planlıyor veya ihmal ediyorum?
- Bir mülakat, sınav veya teslim tarihi çıktığında programımı nasıl değiştirmeliyim?
- Planlanan çalışma ile gerçekleşen çalışma arasındaki fark nedir?

---

## 4. Değişmez ürün ilkeleri

### 4.1 Gerçekçilik, motivasyon gösterisinden önemlidir

- Kullanıcının günlük kullanılabilir kapasitesi tutulmalıdır.
- Planlanan toplam süre kapasiteyi aşarsa uyarı verilmelidir.
- Uygulama gerçek dışı planı başarı gibi göstermemelidir.
- Fazla hedef eklemek teşvik edilmemelidir.

### 4.2 Haftalık hedef ile günlük hedef birbirinden kopuk değildir

- Günlük hedef isteğe bağlı olarak bir haftalık/dönemsel hedefe bağlanır.
- Günlük ilerleme üst hedefe otomatik katkı sağlar.
- Tek progress kaydı birden fazla yerde mükerrer sayılmamalıdır.

### 4.3 Kaçırılmış hedefler sessizce taşınmaz

- Kullanıcıya eksik miktar ve etkisi gösterilir.
- Yeniden dağıtma kullanıcının onayıyla yapılır.
- Önceki dönemin sonucu değiştirilmez; snapshot olarak korunur.
- Carry-over yeni dönemle ilişkilendirilir.

### 4.4 Her hedef aynı davranmaz

- Esnek haftalık hedef yeniden dağıtılabilir.
- Sabit saatli ilaç hatırlatması yeniden dağıtılamaz.
- Namaz veya randevu gibi zamana bağlı hedeflerin kendi kuralları vardır.
- Deadline hedefleri kalan süreye göre risk uyarısı üretir.

### 4.5 Bildirim bir ürün özelliğidir, spam aracı değildir

- Sessiz saatler uygulanmalıdır.
- Günlük bildirim bütçesi olmalıdır.
- Kritik ve esnek bildirimler ayrılmalıdır.
- Aynı durum için yinelenen bildirimler idempotent olmalıdır.

### 4.6 Kullanıcı verisi kullanıcıya aittir

- Veri dışa aktarılabilmelidir.
- Hesap ve veriler silinebilmelidir.
- Sağlık ve ibadet verileri hassas kabul edilmelidir.
- Bildirim metinlerinde gizlilik modu bulunmalıdır.

### 4.7 Önce çalışan çekirdek, sonra AI

- İlk sürüm deterministik kurallarla çalışmalıdır.
- LLM veya AI temel planlama için zorunlu bağımlılık olmamalıdır.
- AI daha sonra öneri, özet veya senaryo üretmek için eklenebilir.
- AI önerisi kullanıcının planını izinsiz değiştiremez.

---

## 5. MVP kapsamı

MVP aşağıdaki uçtan uca akışı sorunsuz tamamlamalıdır:

1. Kullanıcı giriş yapar.
2. Kategori oluşturur veya hazır kategori seçer.
3. Haftalık, günlük, kayan 7 günlük veya özel dönemli hedef oluşturur.
4. Hedefin ölçüm birimini seçer.
5. Haftalık hedefi günlere dağıtır.
6. Günlük hedefe elle veya odak sayacıyla ilerleme kaydeder.
7. Günlük ilerleme haftalık hedefe doğru biçimde yansır.
8. Eksik günlük hedef tespit edilir.
9. Kullanıcı yeniden dağıtma seçeneklerinden birini seçer.
10. Hatırlatmalar iPhone'da çalışır.
11. Aynı veri web uygulamasında görünür.
12. Dönem bitiminde sonuç snapshot olarak kaydedilir.
13. Haftalık rapor planlanan ve gerçekleşen miktarları gösterir.

### MVP'de olmayacaklar

- Sosyal ağ, arkadaş ekleme veya liderlik tablosu
- Takım/şirket çalışma alanı
- Her şeyi yöneten otonom AI ajanı
- Mikroservis mimarisi
- Karmaşık rozet/puan ekonomisi
- Her platform için ayrı kod tabanı
- Tıbbi öneri veya doz tavsiyesi
- İlk sürümde otomatik konum tabanlı namaz vakti zorunluluğu
- Gereksiz gamification
- Reklam veya ödeme sistemi

---

## 6. Hedef türleri

### 6.1 Flexible quota goal

Belirli dönem içinde ölçülebilir miktarın tamamlanması gerekir.

Örnekler:

- Haftada 10 saat proje
- Haftada 200 sayfa kitap
- Haftada 6 saat PTE
- Haftada 3 spor seansı
- Haftada 50 mülakat sorusu

Davranış:

- Günlere dağıtılabilir.
- Kalan günlere yeniden dağıtılabilir.
- Dönem sonunda partial/completed/missed sonucu oluşur.

### 6.2 Recurring routine

Belirlenen günlerde tekrar eder.

Örnekler:

- Her gün 15 dakika beyin jimnastiği
- Pazartesi, çarşamba, cumartesi spor
- Her gece 30 dakika kitap

Davranış:

- Her occurrence ayrı takip edilir.
- Streak gösterilebilir fakat ürünün ana metriği olmamalıdır.
- Kaçırılan rutin isteğe bağlı yeniden planlanabilir.

### 6.3 Fixed-time critical routine

Belirli saatte gerçekleşmesi gereken ve esnek kota gibi taşınmaması gereken rutin.

Örnekler:

- İlaç kullanımı
- Namaz
- Randevu

Davranış:

- Kesin saate veya zaman aralığına bağlanabilir.
- Kaçırıldığında “tamamlandı” varsayılmaz.
- İlaç hedeflerinde uygulama asla çift doz veya telafi dozu tavsiye etmez.
- Gizli bildirim metni kullanılabilir: “Planlanmış kişisel hatırlatıcın var.”

### 6.4 Deadline / milestone goal

Belirli tarihe kadar bir çıktı tamamlanmalıdır.

Örnekler:

- PTE sınavı
- Mülakat tarihi
- Yüksek lisans ödevi
- Proje sürümü

Davranış:

- Deadline yaklaştıkça risk hesaplanır.
- Kalan iş/kalan kapasite karşılaştırılır.
- Kullanıcının onayıyla diğer esnek hedefler geçici olarak azaltılabilir.

---

## 7. Ölçüm türleri

En az aşağıdaki measurement türleri desteklenmelidir:

- `duration_minutes`: dakika/saat
- `count`: adet
- `pages`: sayfa
- `boolean`: yapıldı/yapılmadı
- `sessions`: seans
- `dose`: doz alındı/alınmadı; tıbbi tavsiye yok
- `custom_numeric`: kullanıcı tanımlı sayı ve birim

Kurallar:

- Tüm duration verisi veritabanında integer dakika olarak tutulmalıdır.
- UI saat ve dakika olarak gösterebilir.
- Floating-point süre kullanılmamalıdır.
- Ölçüm tipi hedef oluşturulduktan sonra progress varsa doğrudan değiştirilememelidir.
- Değişiklik gerekiyorsa yeni hedef versiyonu veya migration akışı kullanılmalıdır.

---

## 8. Dönem türleri ve tarih semantiği

### 8.1 Calendar week

- Varsayılan: Pazartesi başlangıç, sonraki pazartesi bitiş.
- Kullanıcı hafta başlangıç gününü ayarlardan değiştirebilir.

### 8.2 Rolling 7 days

- Örneğin salı başlatılan dönem, sonraki salı başlamadan biter.
- Veritabanında `start_date` inclusive, `end_date` exclusive tutulmalıdır.
- UI kullanıcı dostu tarih aralığı göstermelidir.

### 8.3 Custom period

- Kullanıcı başlangıç ve bitiş tarihini seçer.
- Minimum ve maksimum dönem sınırları ürün kararına göre tanımlanmalıdır.

### 8.4 Daily occurrence

- Kullanıcının timezone'una göre yerel takvim günüyle ilişkilidir.
- Timestamp'ler UTC tutulmalı; yerel gün hesaplarında profil timezone'u kullanılmalıdır.
- `Europe/Istanbul` ilk kullanıcı için varsayılan timezone'dur.

---

## 9. Hedef hiyerarşisi ve veri modeli

Önerilen kavramsal model:

### 9.1 Profile

- `id`
- `user_id`
- `display_name`
- `timezone`
- `locale`
- `week_start_day`
- `quiet_hours_start`
- `quiet_hours_end`
- `daily_notification_budget`
- `privacy_notification_mode`
- `created_at`
- `updated_at`

### 9.2 Category

- `id`
- `user_id`
- `name`
- `icon_key`
- `color_token`
- `is_sensitive`
- `is_archived`
- `sort_order`

Hazır kategoriler:

- İş hayatı
- İş başvurusu
- Mülakat
- Proje geliştirme
- Yüksek lisans / ders
- PTE / dil
- Kitap
- Spor
- Sağlık / ilaç
- Beyin jimnastiği
- Namaz / ibadet
- Kişisel

Kullanıcı özel kategori oluşturabilmelidir.

### 9.3 Goal template

Tekrarlayan veya tekrar kullanılabilir hedefin tanımıdır.

- `id`
- `user_id`
- `category_id`
- `title`
- `description`
- `goal_type`
- `measurement_type`
- `unit_label`
- `default_target_value`
- `priority`
- `flexibility`
- `recurrence_rule`
- `is_sensitive`
- `is_active`
- `created_at`
- `updated_at`

### 9.4 Goal period

Bir hedefin belirli dönem içindeki instance'ıdır.

- `id`
- `user_id`
- `goal_template_id`
- `period_type`
- `start_date`
- `end_date_exclusive`
- `target_value`
- `status`
- `carryover_from_period_id`
- `closed_at`
- `created_at`
- `updated_at`

### 9.5 Daily allocation

Goal period hedefinin belirli güne ayrılmış kısmıdır.

- `id`
- `user_id`
- `goal_period_id`
- `target_date`
- `allocated_value`
- `available_capacity_minutes_snapshot`
- `status`
- `created_at`
- `updated_at`

### 9.6 Progress entry

Gerçekleşen ilerlemenin tek kaynak kaydıdır.

- `id`: client-generated UUID; offline/idempotency için
- `user_id`
- `goal_period_id`
- `daily_allocation_id`: nullable
- `value_delta`
- `source`: manual, focus_timer, import, adjustment
- `occurred_at`
- `local_date`
- `note`
- `evidence_url`: nullable
- `idempotency_key`
- `created_at`

Haftalık ve günlük toplamlar aynı progress entry'lerden hesaplanmalıdır. Mükerrer total kolonları ancak performans için ve güvenli transaction/trigger ile kullanılabilir.

### 9.7 Focus session

- `id`
- `user_id`
- `goal_period_id`
- `daily_allocation_id`
- `started_at`
- `ended_at`
- `paused_duration_seconds`
- `status`
- `device_id`
- `progress_entry_id`: tamamlandığında oluşan kayıt

### 9.8 Reminder rule

- `id`
- `user_id`
- `goal_template_id` veya `goal_period_id`
- `reminder_type`
- `schedule`
- `threshold`
- `channel`
- `is_critical`
- `respect_quiet_hours`
- `enabled`

### 9.9 Notification delivery

- `id`
- `user_id`
- `device_id`
- `reminder_rule_id`
- `dedupe_key`
- `scheduled_for`
- `sent_at`
- `status`
- `failure_reason`

### 9.10 Weekly/period review

- `id`
- `user_id`
- `period_start`
- `period_end_exclusive`
- `snapshot_json`
- `reflection_text`
- `main_blocker`
- `next_period_focus`
- `created_at`

### 9.11 Device

- `id`
- `user_id`
- `platform`
- `push_token`
- `last_seen_at`
- `notifications_enabled`
- `app_version`

Gerçek SQL şeması migration dosyalarıyla oluşturulmalı; doğrudan dashboard üzerinde izsiz değişiklik yapılmamalıdır.

---

## 10. Planlama motoru

Planlama motoru UI'dan bağımsız, test edilebilir saf Dart servisleri olarak tasarlanmalıdır.

Temel sorumluluklar:

1. Dönem içindeki toplam hedefi ve gerçekleşeni hesaplama.
2. Günlük allocation toplamını dönem hedefiyle karşılaştırma.
3. Kalan miktarı hesaplama.
4. Kalan günlerin kapasitesini hesaplama.
5. Eksik günlük hedefleri tespit etme.
6. Yeniden dağıtım önerisi üretme.
7. Sabit hedefleri yeniden dağıtım dışında tutma.
8. Deadline riskini hesaplama.
9. Period kapanış sonucu üretme.
10. Taşınacak miktarı yeni dönemle açıkça ilişkilendirme.

### 10.1 Yeniden dağıtım algoritması — ilk sürüm

İlk sürüm deterministik ve açıklanabilir olmalıdır.

Girdiler:

- Kalan hedef miktarı
- Kalan günler
- Her günün kullanılabilir kapasitesi
- Kullanıcının tercih ettiği günler
- Sabit günlük hedefler
- Hedef önceliği
- Maksimum günlük yük

Çıktılar:

- Önerilen günlük allocation listesi
- Kapasite aşımı varsa uyarı
- Hedefin dönem içinde tamamlanmasının mümkün olup olmadığı
- Önerinin kısa insan-okur açıklaması

Örnek:

> Haftalık proje hedefinde 360 dakika kaldı. Dönemde 3 uygun gün ve toplam 300 dakika boş kapasite var. Hedef mevcut kapasiteyle tamamlanamaz. Hedefi 60 dakika azaltabilir, başka bir esnek hedefi düşürebilir veya dönemi uzatabilirsin.

### 10.2 Kapasite modeli

- Kullanıcı genel günlük kapasite belirleyebilir.
- Tarih bazında kapasite override edilebilir.
- Ders günü, seyahat, randevu gibi bloklar kapasiteyi azaltabilir.
- Planlanan toplam süre kapasiteyi aştığında soft warning gösterilir.
- Kritik sabit rutinler kapasite uyarısına rağmen silinmez.

### 10.3 Hedef borcu

“Goal debt” kullanıcıya suçluluk üretmek için değil, dönem içindeki kalan yükü görünür yapmak için kullanılır.

- Eksik miktar açıkça gösterilir.
- Borç yalnızca esnek hedefler için yeniden dağıtılır.
- Dönem kapanınca borç otomatik olarak gelecek döneme taşınmaz.
- Kullanıcı carry-over seçerse yeni period oluşturulur ve kaynak period ilişkilendirilir.

---

## 11. Bildirim sistemi

### 11.1 Bildirim türleri

- Hedef başlamadan önce hatırlatma
- Belirli saate kadar ilerleme yoksa hatırlatma
- Gün sonu eksik hedef bildirimi
- Haftalık dönem orta noktası ilerleme bildirimi
- Dönem bitimine 48/24 saat kala uyarı
- Dönem kapanış özeti
- Deadline risk bildirimi
- Sabit saatli ilaç/rutin bildirimi
- Mülakat modu bildirimi

### 11.2 Yerel ve uzaktan bildirim ayrımı

Yerel bildirimler:

- Cihazda kesin saati bilinen hatırlatmalar
- Offline durumda da çalışması beklenen rutinler
- Günlük basit hatırlatmalar

Uzaktan bildirimler:

- Sunucu verisine göre değişen kalan hedef
- Haftalık eksik miktar
- Çok cihazlı senkronizasyona bağlı durumlar
- Dönem kapanış raporu

### 11.3 Bildirim yorgunluğu

- Kullanıcının günlük maksimum bildirim sayısı olmalıdır.
- Aynı hedef için kısa sürede mükerrer bildirim gönderilmemelidir.
- `dedupe_key` zorunludur.
- Sessiz saatlerde kritik olmayan bildirim ertelenmelidir.
- Kullanıcı snooze, bugün atla veya yeniden planla aksiyonlarına sahip olmalıdır.

### 11.4 Gizlilik

Hassas hedeflerde iki metin modu olmalıdır:

- Açık: “İlacını alma zamanın geldi.”
- Gizli: “Planlanmış kişisel hatırlatıcın var.”

Kilit ekranında kullanıcı istemeden sağlık veya ibadet bilgisi görünmemelidir.

---

## 12. Yenilikçi özellikler

### 12.1 MVP için onaylı yenilikler

1. **Haftalıktan günlüğe bağlı hedef yapısı**
2. **Kapasite aşımı uyarısı**
3. **Eksik hedefi kalan günlere açıklanabilir yeniden dağıtma**
4. **Odak sayacından otomatik progress üretme**
5. **Dönem kapanış snapshot'ı ve açık carry-over**
6. **Bildirim bütçesi ve sessiz saatler**
7. **Mobil günlük kullanım + web planlama ayrımı**

### 12.2 MVP sonrası aday özellikler

- Mülakat modu
- Sınav modu
- Enerji seviyesine göre görev önerisi
- Gerçekleşme geçmişinden gerçekçi kapasite önerisi
- “Neden yapamadım?” blocker analizi
- GitHub commit entegrasyonuyla proje süresi/çıktı bağlantısı
- Takvim entegrasyonu
- Konum tabanlı namaz vakitleri
- Apple Health/HealthKit ile spor verisi
- Kısayollar/Siri entegrasyonu
- Widget ve Live Activity
- AI haftalık plan önerisi
- AI haftalık değerlendirme özeti
- Hedefler arası çatışma tespiti
- “Minimum uygulanabilir gün” modu
- Seyahat/hastalık/yoğun hafta modu
- İlerleme tahmini: mevcut hızla hedef tamamlanır mı?

### 12.3 Claude'un yenilik önerme yetkisi

Claude yeni ve farklı özellikler önerebilir. Ancak şu kurallar zorunludur:

1. Özellik sessizce uygulanamaz; önce önerilmelidir.
2. Her öneri şu puanlarla değerlendirilmelidir:
   - Kullanıcı problemini çözme değeri: 1–5
   - Günlük kullanım değeri: 1–5
   - Teknik/portföy değeri: 1–5
   - Geliştirme karmaşıklığı: 1–5
   - Hata/güvenlik riski: 1–5
   - MVP'yi geciktirme riski: 1–5
3. Öneri `MVP`, `v1.1`, `v2` veya `reddedilmeli` olarak sınıflandırılmalıdır.
4. MVP'ye aynı anda en fazla bir yeni özellik önerilebilir.
5. Yeni özellik mevcut planlama motorunu, veri bütünlüğünü veya bildirim güvenilirliğini riske atamaz.
6. AI, sosyal özellik veya gamification sırf ilgi çekici göründüğü için eklenemez.
7. Kullanıcıya somut fayda üretmeyen özellik reddedilmelidir.

---

## 13. Ana ekranlar ve kullanıcı akışları

### 13.1 Onboarding

- Uygulamanın amacı kısa açıklanır.
- Timezone doğrulanır.
- Hafta başlangıç günü seçilir.
- Sessiz saatler seçilir.
- Bildirim izni bağlamı açıklanarak istenir; uygulama açılır açılmaz kör izin pop-up'ı gösterilmez.
- Başlangıç kategorileri seçilir.
- Örnek hedef eklemek isteğe bağlıdır.

### 13.2 Bugün

İlk viewport'ta:

- Bugünkü toplam planlanan süre
- Gerçekleşen süre
- Kalan kapasite
- Bugünün hedefleri
- Kritik hatırlatmalar
- Aktif odak sayacı
- Hızlı ilerleme ekleme

Her hedef kartı:

- Başlık
- Kategori
- Günlük gerçekleşme
- Bağlı haftalık hedef gerçekleşmesi
- Öncelik veya sabit/esnek işareti
- Başlat, ilerleme ekle, ertele aksiyonları

### 13.3 Hafta

- Gün sütunları veya uygun mobil eşdeğeri
- Haftalık hedef kartları
- Günlük allocation'lar
- Kalan hedef borcu
- Kapasite aşımı
- Sürükle-bırak yalnızca erişilebilir alternatifle birlikte düşünülmelidir
- Toplu yeniden dağıtma

### 13.4 Hedef oluşturma

Adımlar:

1. Kategori
2. Hedef türü
3. Ölçüm türü
4. Hedef miktarı
5. Dönem
6. Günlere dağıtım
7. Hatırlatma
8. Gizlilik ve esneklik
9. Özet/onay

Form tek ekranda aşırı kalabalık olmamalıdır.

### 13.5 Odak

- Aktif hedef seçimi
- Başlat/duraklat/bitir
- Geçen süre
- Mola
- Seans notu
- Bitirince progress entry oluşturma
- Uygulama kapanması veya cihaz değişiminde seans kurtarma

### 13.6 Raporlar

- Planlanan vs gerçekleşen
- Kategori bazında süre/miktar
- Gün bazında kapasite kullanımı
- Eksik hedef nedenleri
- Önceki dönem karşılaştırması
- Kullanıcıya anlaşılır öneriler

### 13.7 Ayarlar

- Profil
- Timezone ve locale
- Hafta başlangıcı
- Sessiz saatler
- Bildirim bütçesi
- Gizli bildirim metni
- Kategori yönetimi
- Veri dışa aktarma
- Hesap/veri silme

---

## 14. Mobil ve web deneyimi

### Mobil öncelikleri

- Bugünkü hedefler
- Hızlı progress
- Focus timer
- Bildirim aksiyonları
- Tek elle kullanım
- Safe area
- Dynamic Type
- iPhone 15 üzerinde fiziksel test

### Web öncelikleri

- Haftalık planı toplu düzenleme
- Daha geniş raporlar
- Hedefleri günlere dağıtma
- Klavye erişilebilirliği
- Responsive masaüstü/tablet/mobil düzen

Aynı veri ve domain kuralları kullanılmalı; platformlara ayrı iş mantığı yazılmamalıdır.

---

## 15. Teknik mimari

### 15.1 İlk sürüm

- Flutter/Dart tek repository
- Feature-first klasörleme
- Domain katmanı UI ve veri kaynağından bağımsız
- Supabase Auth
- PostgreSQL + RLS
- Supabase Realtime gerektiği yerde
- Supabase Cron + Edge Function ile sunucu kontrolleri
- FCM/APNs/Web Push ile uzaktan bildirim
- iOS yerel bildirimleri
- Local cache ve offline operation queue

### 15.2 Daha sonra

- FastAPI planlama/AI servisi
- Gelişmiş analitik
- Harici entegrasyonlar

FastAPI yalnızca net bir use case olduğunda eklenmelidir. Flutter'ın yapabileceği basit CRUD için ayrı backend yazılmamalıdır.

### 15.3 Önerilen klasörleme

```text
lib/
  app/
    app.dart
    router/
    theme/
    localization/
  core/
    errors/
    time/
    notifications/
    sync/
    utils/
  features/
    auth/
      data/
      domain/
      presentation/
    categories/
    goals/
    planning/
    today/
    focus/
    reminders/
    reports/
    settings/
  shared/
    widgets/
    models/
test/
  unit/
  widget/
  integration/
supabase/
  migrations/
  functions/
docs/
  adr/
  product/
```

Bu yapı ilk günden anlamsız abstraction üretmek için kullanılmamalıdır. Feature büyümeden boş klasörler ve interface'ler oluşturulmamalıdır.

---

## 16. Offline ve senkronizasyon

Uygulama kısa süreli internet kesintisinde temel günlük kullanımını sürdürebilmelidir.

Kurallar:

- Progress entry client-generated UUID kullanır.
- Tekrar gönderim aynı kaydı çoğaltmamalıdır.
- Offline progress queue bağlantı gelince sync edilir.
- UI optimistic olabilir fakat sync durumu görünür olmalıdır.
- Progress kayıtları mümkün olduğunca append-only olmalıdır.
- Aynı goal iki cihazda eş zamanlı düzenlenirse çakışma sessizce ezilmemelidir.
- Basit alanlarda version/updated_at tabanlı conflict detection kullanılmalıdır.
- Çakışmada kullanıcıya iki sürüm gösterme veya yeniden yükleme seçeneği düşünülmelidir.
- Server authoritative kaynaktır; ancak kullanıcı girdisi kaybolmamalıdır.

---

## 17. Güvenlik ve gizlilik

- Supabase service-role key hiçbir zaman Flutter istemcisinde bulunamaz.
- Secrets repository'ye commit edilemez.
- RLS tüm kullanıcı tablolarında zorunludur.
- Her kullanıcı yalnızca kendi `user_id` kayıtlarını görebilmelidir.
- Storage bucket politikaları kullanıcı bazlı olmalıdır.
- Hassas kategori verileri loglarda açıkça yazılmamalıdır.
- Notification payload'ında gereksiz kişisel veri taşınmamalıdır.
- SQL injection, yetkisiz erişim ve IDOR senaryoları test edilmelidir.
- Hesap silme tüm ilgili kişisel veriyi kapsamalıdır.
- Medication özelliği bilgi ve hatırlatma amaçlıdır; tıbbi karar vermez.

---

## 18. Tasarım sistemi ve UX kuralları

- Görsel dil mevcut Harun'un Rotası sitesindeki koyu, net ve ciddi “command center” hissinden ilham alabilir.
- Ürün yalnızca dark mode olmamalı; light ve dark theme desteklenmelidir.
- Renk tek başına durum göstergesi olmamalıdır.
- Ana gövde metni okunabilir olmalıdır.
- Hedef miktarı, kalan süre ve deadline küçük/gizli metin olmamalıdır.
- Dokunma hedefleri iOS kullanımına uygun olmalıdır.
- Dynamic Type ve ekran okuyucu etiketleri desteklenmelidir.
- Klavye ile web kullanımı mümkün olmalıdır.
- İlk ekran pazarlama ekranı değil, gerçek çalışma yüzeyi olmalıdır.
- Kullanıcının suçluluk duygusunu artıran kırmızı/cezalandırıcı dil kullanılmamalıdır.
- “Başarısız oldun” yerine “Hedefin 60 dakikası tamamlanmadı” gibi nesnel dil kullanılmalıdır.
- Animasyonlar kısa, amaçlı ve reduce-motion tercihine duyarlı olmalıdır.
- Varsayılan component görünümü bitmiş tasarım kabul edilmemelidir.

---

## 19. Kod standartları

- Kod, identifier ve dosya adları İngilizce olmalıdır.
- Kullanıcıya görünen metinler yerelleştirme katmanından gelmelidir.
- Null safety zorunludur.
- Domain kuralları widget içinde yazılmamalıdır.
- Büyük widget'lar küçük ve anlamlı parçalara ayrılmalıdır.
- Magic number kullanılmamalıdır.
- Date/time hesapları doğrudan dağınık şekilde yapılmamalı; merkezi time service kullanılmalıdır.
- Async error'lar yutulmamalıdır.
- Kullanıcıya teknik stack trace gösterilmemelidir.
- Loglar hassas veri içermemelidir.
- Dependency eklemeden önce gerekçe ve resmi bakım durumu kontrol edilmelidir.
- Güncel stable Flutter/Dart sürümü resmi kaynaklardan doğrulanmalıdır.
- Paket sürümleri tahmin edilmemeli; uygulama başlatılırken güncel ve uyumlu sürümler kontrol edilmelidir.
- Lint, formatter ve analyzer hatasız olmalıdır.

---

## 20. Test stratejisi

### 20.1 Unit tests — zorunlu

Planlama motoru için en az şu senaryolar test edilmelidir:

1. Haftalık 600 dakikalık hedefe günlük 120 dakikanın doğru katkısı
2. Progress entry'nin iki kez sayılmaması
3. Pazartesi–pazar calendar week
4. Salı başlayan rolling 7-day period
5. Custom period
6. Eksik günlük allocation
7. Kalan günlere eşit dağıtım
8. Kapasiteye göre ağırlıklı dağıtım
9. Toplam kapasitenin yetersiz olması
10. Sabit ilaç hedefinin yeniden dağıtılmaması
11. Period kapanışı ve snapshot
12. Explicit carry-over
13. Offline progress idempotency
14. Timezone değişimi
15. Gece yarısı sınırı
16. Sessiz saatler
17. Günlük bildirim bütçesi
18. Dedupe key
19. Goal target değişikliği sonrası tutarlılık
20. Silinmiş/arşivlenmiş hedefin raporlarda korunması

### 20.2 Widget tests

- Hedef oluşturma formu
- Bugün hedef kartı
- Progress ekleme
- Kapasite uyarısı
- Yeniden dağıtma dialog/sheet
- Haftalık rapor
- Empty/loading/error/success durumları

### 20.3 Integration tests

- Sign-up/login
- Hedef oluştur → allocation oluştur → progress ekle → raporda gör
- Mobilde ekle → webde gör
- Offline progress → online sync
- Bildirimden uygulamayı doğru hedefe aç
- Period kapanışı
- Hesap silme

### 20.4 Fiziksel test

- iPhone 15 gerçek cihaz
- Safari web
- Chrome web
- Bildirim izinleri reddedildi/kabul edildi
- Uygulama foreground/background/terminated

---

## 21. Hata ve durum tasarımı

Her önemli akışta şunlar ele alınmalıdır:

- Loading
- Empty
- Partial data
- Offline
- Sync pending
- Sync conflict
- Permission denied
- Notification permission denied
- Server error
- Validation error
- Success confirmation

Hata durumunda kullanıcının verisi kaybolmamalı ve mümkünse tekrar deneme yolu sunulmalıdır.

---

## 22. Analitik ve gözlemlenebilirlik

İlk sürümde üçüncü taraf davranış takibi zorunlu değildir.

Uygulama sağlığı için:

- Hata logları
- Notification delivery status
- Cron job geçmişi
- Sync hata sayısı
- Edge Function hata oranı
- Uygulama sürümü

takip edilebilir olmalıdır.

Kişisel hedef içerikleri analitik amacıyla üçüncü taraf servislere gönderilmemelidir.

---

## 23. Performans hedefleri

- Bugün ekranı yerel cache varsa hızlı açılmalıdır.
- Uzun hedef listelerinde gereksiz rebuild önlenmelidir.
- Rapor hesapları UI thread'i kilitlememelidir.
- Büyük tarih aralıkları sayfalama veya aggregate sorgularla yönetilmelidir.
- Web bundle gereksiz paketlerle şişirilmemelidir.
- Görseller optimize edilmelidir.
- Realtime yalnızca gerçekten gereken tablolarda açılmalıdır.

---

## 24. Geliştirme aşamaları

### Phase 0 — Product and domain foundation

- Terminoloji
- User stories
- Acceptance criteria
- Domain model
- Planning engine interfaces
- ADR'ler
- Test senaryoları

Çıkış kriteri: UI olmadan temel planlama kuralları testlerle açıklanabiliyor.

### Phase 1 — Local vertical slice

- Flutter project
- Responsive shell
- Category
- Goal creation
- Goal period
- Daily allocation
- Manual progress
- Local sample persistence

Çıkış kriteri: Kullanıcı yerel veride haftalık hedef oluşturup günlük ilerleme kaydedebiliyor.

### Phase 2 — Auth and cloud sync

- Supabase local setup
- SQL migrations
- Auth
- RLS
- Repository implementation
- Mobile–web sync

Çıkış kriteri: Aynı kullanıcı iPhone ve webde aynı hedefleri görüyor.

### Phase 3 — Focus and offline

- Focus timer
- App lifecycle recovery
- Progress transaction
- Offline queue
- Idempotency
- Conflict handling

Çıkış kriteri: İnternet kesilse bile ilerleme kaybolmuyor.

### Phase 4 — Notifications

- Local notifications
- Push token registration
- FCM/APNs/Web Push
- Cron + Edge Function
- Quiet hours
- Notification budget
- Dedupe

Çıkış kriteri: Günlük ve haftalık hatırlatmalar doğru ve mükerrersiz çalışıyor.

### Phase 5 — Adaptive planning and reports

- Goal debt
- Capacity model
- Redistribution
- Period close
- Review snapshot
- Reports

Çıkış kriteri: Eksik hedef açıklanabiliyor ve kontrollü biçimde yeniden planlanabiliyor.

### Phase 6 — Hardening and release

- Accessibility
- Physical device tests
- Web browser tests
- Security review
- Performance
- Backup/export/delete
- Release pipeline

Çıkış kriteri: Kişisel günlük kullanım için güvenilir iOS ve web sürümü.

### Phase 7 — Optional intelligence

- FastAPI service only if justified
- AI weekly planning suggestions
- Interview/deadline modes
- Behavioral trend analysis
- External integrations

---

## 25. Definition of Done

Bir özellik aşağıdakiler tamamlanmadan bitmiş sayılmaz:

- Acceptance criteria karşılandı.
- Happy path ve beklenen failure path çalışıyor.
- İlgili unit/widget/integration testleri yazıldı.
- Formatter, analyzer ve testler geçti.
- Mobil ve web davranışı kontrol edildi.
- Accessibility labels eklendi.
- Loading/empty/error/success durumları var.
- Güvenlik/RLS etkisi değerlendirildi.
- Migration gerekiyorsa versioned migration yazıldı.
- Kullanıcı metinleri lokalizasyon sisteminde.
- İlgili dokümantasyon güncellendi.
- Kullanıcı özelliğin mantığını kendi cümleleriyle açıklayabiliyor.

---

## 26. AI ile çalışma sözleşmesi

Claude veya başka bir AI aracı:

- Tüm uygulamayı tek seferde üretmeye çalışmamalıdır.
- Önce mevcut repository ve bu dosyayı okumalıdır.
- Varsayım yaptığında açıkça belirtmelidir.
- Bloklayıcı olmayan ayrıntılar için sürekli soru sormamalıdır.
- Bloklayıcı ürün kararlarını kullanıcıya sormalıdır.
- Kod yazmadan önce değişiklik kapsamını belirtmelidir.
- Büyük değişiklikleri küçük, test edilebilir adımlara bölmelidir.
- Kullanıcının anlamadığı kodu yalnızca “çalışıyor” diye bırakmamalıdır.
- Her özellik sonunda veri akışını ve kritik tasarım kararını açıklamalıdır.
- Gereksiz dependency, abstraction veya design pattern eklememelidir.
- Secret istememeli veya repository'ye yazmamalıdır.
- Dosyaları, migration'ları veya kullanıcı verisini izinsiz silmemelidir.
- Destructive git komutları kullanmamalıdır.
- Push/deploy işlemini açık yetki olmadan yapmamalıdır.
- Yeni özellik fikirlerini Innovation Review formatıyla önermelidir.

### Innovation Review formatı

```text
Özellik adı:
Çözdüğü kullanıcı problemi:
Kullanıcı akışı:
Neden klasik todo uygulamalarından farklı:
Kullanıcı değeri (1-5):
Günlük kullanım değeri (1-5):
Portföy/teknik değer (1-5):
Karmaşıklık (1-5):
Risk (1-5):
MVP gecikme riski (1-5):
Önerilen sürüm: MVP / v1.1 / v2 / reddedilmeli
Gerekli veri modeli değişikliği:
Gerekli bildirim/senkronizasyon etkisi:
Test yaklaşımı:
```

---

## 27. Öğrenme hedefleri

Bu proje yalnızca ürün çıkarmak için değil, kullanıcıya mühendislik öğretmek için yapılmaktadır.

Kullanıcı proje sonunda şunları açıklayabilmelidir:

- Flutter widget lifecycle
- State management mantığı
- Responsive mobil/web tasarım
- Domain/data/presentation ayrımı
- PostgreSQL ilişkisel modelleme
- Supabase Auth ve RLS
- Offline sync ve idempotency
- Local vs remote notification
- Cron job ve Edge Function
- Timezone ve tarih aralığı semantiği
- Unit/widget/integration test farkı
- CI/CD ve release süreci
- Güvenlik ve privacy kararları

Her geliştirme oturumunun sonunda:

1. Ne yaptık?
2. Neden böyle yaptık?
3. Veri nereden nereye akıyor?
4. Hangi edge case'i çözdük?
5. Hangi test bunu koruyor?

soruları cevaplanmalıdır.

---

## 28. İlk başarı ölçütleri

İlk kişisel kullanım döneminde:

- Haftalık hedef oluşturma 2 dakikadan kısa sürmeli.
- Günlük progress ekleme 10 saniyeden kısa sürmeli.
- Mobil ve web verisi tutarlı olmalı.
- Eksik hedef bildirimi mükerrer olmamalı.
- Kullanıcı bir haftanın sonunda planlanan/gerçekleşen farkını anlayabilmeli.
- Uygulama, kullanıcıya kapasitesinin üzerinde plan yaptığını gösterebilmeli.
- Kullanıcı en az bir hedefi odak sayacıyla tamamlayabilmeli.
- Offline progress bağlantı gelince kaybolmadan sync olmalı.

---

## 29. Açık ürün kararları

Kodlamadan önce veya ilgili faza gelindiğinde netleştirilecek konular:

- Uygulamanın nihai adı ve ikon yönü
- E-posta girişi yanında Sign in with Apple zamanı
- İlk web hosting hedefi
- İlk iOS dağıtım biçimi
- Namaz vakitlerinin manuel mi harici servisle mi başlayacağı
- Kanıt dosyalarının ilk sürümde bulunup bulunmayacağı
- HealthKit ve takvim entegrasyonlarının önceliği
- AI servisinin net use case'i

Bu kararlar MVP çekirdeğini engellememelidir.

---

## 30. Son ürün pusulası

Bir özellik veya teknik karar tartışıldığında şu sıra kullanılmalıdır:

1. Kullanıcının gerçek problemini çözüyor mu?
2. Haftalık–günlük hedef ilişkisinin doğruluğunu koruyor mu?
3. Mobil ve webde tutarlı mı?
4. Güvenli ve gizliliğe uygun mu?
5. Offline/senkronizasyon davranışı belli mi?
6. Test edilebilir mi?
7. Kullanıcı bunu anlayarak geliştirebilir mi?
8. MVP'yi gereksiz yere geciktiriyor mu?

İlk yedi sorudan geçmeyen veya sekizinci soruda aşırı riskli olan özellik uygulanmamalıdır.

