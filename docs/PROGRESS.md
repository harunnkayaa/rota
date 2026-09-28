# Rota — Nerede kaldık?

> Son güncelleme: 2026-09-28. Yeni bir oturuma başlarken önce bu dosyayı,
> sonra [CLAUDE.md](../CLAUDE.md)'yi oku.
>
> Çalışma dalı: `feat/deadline-route` (GitHub'da). `main`'e birleştirme
> kullanıcı tarafından PR ile yapılacak.

## Tamamlanan aşamalar

| Aşama | Durum | Özet |
|---|---|---|
| Phase 0 — Domain ve planlama motoru | ✅ | `LocalDate`, `PeriodRange`, hedef/dönem/günlük plan/ilerleme modelleri, ilerleme hesabı (mükerrer sayım yok), kapasite, açık (goal debt), yeniden dağıtım, dönem kapanışı ve carry-over. Saf Dart, testli. |
| Phase 1 — Yerel dikey dilim | ✅ | Bugün / Hafta / Hedef oluşturma ekranları, cihazda kalıcı kayıt (`shared_preferences`, JSON, `schema_version: 1`), açık/koyu tema, Türkçe metinler (gen-l10n). |
| Kullanıcı istekleri (26.09) | ✅ | Her güne ayrı süre; planı Bugün ve Hafta ekranından düzenleme; geçmiş günler kilitli; eksik gün sonradan telafi edilince "fazla planlandı" denmiyor (kalan plan ↔ kalan hedef). |
| Hedef tarihi rotası (28.09) | ✅ | Tarihli hedef (sınav/mülakat/teslim): kalan süre, haftalık tempo, bu haftanın payı, kapasiteye göre yetişme riski. Geride kalınca "Tempoyu yakala": önce boş zamandan, yetmezse **kullanıcının seçtiği** hedeflerden süre alır; toplam hedef değiştirilebilir. Motor: `planning/domain/deadline_pace.dart`. |

| Hafta geçişi ve kapanış (28.09) | ✅ | Yeni hafta başlayınca biten dönemler kapanır (snapshot), aktif haftalık hedefler aynı varsayılan hedefle yeni haftaya açılır, gün dağılımı bugünden itibaren kopyalanır. Eksik süre yalnızca kullanıcı "bu haftaya ekle" derse taşınır. Hedef arşivleme. Uygulama öne gelince tarih yeniden kontrol edilir. |
| Ayarlar (28.09) | ✅ | Günlük kapasite, güne özel kapasite, hafta başlangıcı. |
| Odak sayacı (28.09) | ✅ | Başlat / duraklat / devam / bitir; süre zaman damgalarından hesaplanır, uygulama kapanınca kaybolmaz; bitirince tek ilerleme kaydı (`focus:<id>` idempotency). |
| Raporlar (28.09) | ✅ | Bu hafta planlanan–gerçekleşen, kategori dağılımı, geçmiş haftalar (snapshot'lardan), önceki haftayla fark, biten tarihli hedefler. |
| Kayıt şeması v2 | ✅ | v1 dosyaları otomatik taşınır (varsayılan haftalık hedef son haftadan alınır). |

Doğrulama: 183 test geçiyor, `flutter analyze` temiz.

## Sıradaki adımlar (öncelik sırasıyla)

1. **Bildirimler (iOS yerel).** Kurallar:
   [docs/product/notification-rules.md](product/notification-rules.md)
   (her zaman *henüz çalışılmamış* süre; sessiz saatler; günlük bütçe;
   hassas hedeflerde gizli metin). Web'de yerel bildirim yok.
2. **Phase 2 — Supabase (giriş + telefon/web senkronizasyonu)** —
   kullanıcı gerektiriyor:
   - `brew install supabase/tap/supabase` kurulumu
   - Karar: önce **yerel** Supabase (Docker kurulu) mı, yoksa supabase.com
     bulut projesi mi? Öneri: önce yerel.
   - JSON alan adları SQL sütun adlarıyla aynı tutuldu
     (`lib/features/planning/data/planner_json.dart`); RLS zorunlu.
3. Offline kuyruk ve çakışma yönetimi (Supabase ile birlikte).
4. Veri dışa aktarma / hesap-veri silme (CLAUDE.md §4.6).

## Ürün yönü (kullanıcının 26.09 isteği)

Rota basit bir to-do uygulaması gibi algılanmamalı; **kariyer ve kişisel
gelişim rotası** olarak konumlanmalı. Kullanıcı diğer uygulamalarda olmayan
yeni özellikler istiyor. Sonraki oturumda Innovation Review formatıyla
(CLAUDE.md §12.3, §26) değerlendirilecek adaylar:

- Mülakat / sınav modu: tarihe göre kalan süre ve kapasite, esnek
  hedefleri onayla geçici azaltma (CLAUDE.md §6.4, §12.2)
- Uzun vadeli "rota" görünümü: hedeflerin haftalar boyunca ilerleyişi
- Gerçekçilik aynası: geçmiş plan/gerçekleşme oranından sonraki haftaya
  gerçekçi kapasite önerisi
- (Daha önce önerilen) Plan baseline: raporda ilk plan / son plan /
  gerçekleşen

GitHub açıklaması bu konumlandırmaya göre yazıldı ("personal growth
roadmap").

## Açık kararlar

[docs/product/open-decisions.md](product/open-decisions.md) — özellikle:
kapanıştan sonra gelen offline kayıt, rapordaki "planlanan"ın anlamı,
sağlık/ibadet verisinin şifrelenmesi.

## Bilinen notlar

- Yerel Flutter 3.38.7; güncel stable 3.47.5. Supabase'e geçmeden önce
  `flutter upgrade` önerildi.
- iOS debug derlemesi simülatörde tek başına açılmaz; `flutter run` ile
  çalıştır.
- Web'de service worker eski sürümü önbellekten sunabilir; geliştirirken
  `flutter build web --pwa-strategy=none` kullan.

## Çalışma şekli (kullanıcı tercihi)

- Yanıtlar Türkçe, kısa ve pratik; kod/identifier İngilizce.
- Kodu Claude yazar, her adımda ne/neden kısa açıklanır.
- Commit yalnızca istenince; push/deploy yalnızca açık izinle.
