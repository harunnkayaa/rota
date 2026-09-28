# Rota — Nerede kaldık?

> Son güncelleme: 2026-09-28 (akşam). Yeni bir oturuma başlarken önce bu dosyayı,
> sonra [CLAUDE.md](../CLAUDE.md)'yi oku.
>
> Çalışma dalı: `feat/deadline-route` (GitHub'da). `main`'e birleştirme
> kullanıcı tarafından PR ile yapılacak.

## Kısa özet

MVP akışının (CLAUDE.md §5) **giriş ve cihazlar arası senkronizasyon
dışındaki bütün adımları** çalışıyor: hedef oluşturma (haftalık ve tarihli),
günlere dağıtma, ilerleme (elle ve odak sayacıyla), eksik tespiti ve
onaylı yeniden planlama, hafta kapanışı ve rapor, iPhone hatırlatmaları.
Veriler cihazda. Sıradaki büyük adım Supabase ve kullanıcının kurulumunu
bekliyor.

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
| Kayıt şeması v2 | ✅ | v1 dosyaları otomatik taşınır (varsayılan haftalık hedef son haftadan alınır). Simülatördeki gerçek v1 verisiyle doğrulandı. |
| iOS hatırlatmaları (28.09) | ✅ | Kurallar [notification-rules.md](product/notification-rules.md): her zaman henüz çalışılmamış süre, sessiz saatler, günlük bütçe, hassas hedeflerde gizli metin, sabit id ile tekrar yok. Her değişiklikte yeniden planlanır. İzin yalnızca kullanıcı hatırlatmaları açınca istenir (simülatörde gerçek iOS izin penceresiyle doğrulandı). Web'de bildirim yok. Bildirimin gerçek teslimatı otomasyonla doğrulanamadı; iPhone 15'te elle denenmeli. |
| Veri sahipliği (28.09) | ✅ | Ayarlar'dan tüm verileri JSON olarak görüp panoya kopyalama; onaylı "tüm verileri sil" (CLAUDE.md §4.6). |

Doğrulama: 208 test geçiyor, `flutter analyze` temiz.

## Sıradaki adımlar (öncelik sırasıyla)

1. **iPhone 15 fiziksel test** — hatırlatma teslimatı, odak sayacının
   arka planda devamı (CLAUDE.md §20.4).
2. **Phase 2 — Supabase (giriş + telefon/web senkronizasyonu)** —
   kullanıcı gerektiriyor:
   - `brew install supabase/tap/supabase` kurulumu
   - Karar: önce **yerel** Supabase (Docker kurulu) mı, yoksa supabase.com
     bulut projesi mi? Öneri: önce yerel.
   - JSON alan adları SQL sütun adlarıyla aynı tutuldu
     (`lib/features/planning/data/planner_json.dart`); RLS zorunlu.
3. Offline kuyruk ve çakışma yönetimi (Supabase ile birlikte).
4. Hesap silme sunucu tarafı (Supabase ile birlikte; yerel silme hazır).

## Ürün yönü (kullanıcının 26.09 isteği)

Rota basit bir to-do uygulaması gibi algılanmamalı; **kariyer ve kişisel
gelişim rotası** olarak konumlanmalı. Yeni özellikler Innovation Review
formatıyla önerilir, onaysız eklenmez.

- ✅ Hedef tarihi rotası (mülakat / sınav / teslim) — 28.09'da yapıldı.
- ✅ Kategori bazlı zaman dağılımı raporu ("hayat alanları dengesi"nin
  temel hali).
- Sıradaki adaylar (v1.1): hayat alanları için hedef yüzde ve sapma,
  gerçekçilik aynası (geçmiş plan/gerçekleşme oranından kapasite önerisi),
  uzun vadeli rota görünümü, "Haftayı planla" asistanı (tüm hedefleri
  kapasiteye sığdıran haftalık öneri), plan baseline (ilk plan / son plan /
  gerçekleşen).

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
