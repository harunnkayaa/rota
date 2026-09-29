# Rota — Nerede kaldık?

> Son güncelleme: 2026-09-28 (akşam). Yeni bir oturuma başlarken önce bu dosyayı,
> sonra [CLAUDE.md](../CLAUDE.md)'yi oku.
>
> Çalışma dalı: `feat/deadline-route` (GitHub'da). `main`'e birleştirme
> kullanıcı tarafından PR ile yapılacak.

## Kısa özet

MVP akışının (CLAUDE.md §5) **bütün adımları yerel geliştirme ortamında**
çalışıyor: giriş, hedef oluşturma (haftalık ve tarihli), günlere dağıtma,
ilerleme (elle ve odak sayacıyla), eksik tespiti ve onaylı yeniden
planlama, hafta kapanışı ve rapor, iPhone hatırlatmaları, telefon ↔ web
eşitleme (yerel Supabase ile uçtan uca test edildi).

Bulut Supabase projesi (`qhzbfivoffjumbaueygs`, Frankfurt) kuruldu: 3
migration uygulandı, 25 güvenlik testi bulutta da geçti, girişsiz istekler
401 ile reddediliyor. Kalan: iPhone 15 fiziksel test, TestFlight/web yayını.

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

| Supabase veritabanı (28.09) | ✅ | 3 migration: tablolar, her tabloda RLS, `(id, user_id)` bağlantılarıyla IDOR koruması, sadece eklenebilir ilerleme, kapanıştan önceki işin geç eşitlemesi, hesap silme fonksiyonu. 25 pgTAP testi. |
| Hesap ve eşitleme (28.09) | ✅ | E-posta/şifre ile hesap; önce-yerel eşitleme (itme / çekme / çakışmada kullanıcı seçer, iki taraftaki ilerleme korunur); çevrimdışı değişiklikler bekler; çıkış, hesap silme. Gerçek yerel Supabase'e karşı uçtan uca test. |

| Bulut Supabase (28.09) | ✅ | `supabase link` + `db push`; `supabase test db --linked` 25/25. Kayıtta e-posta onayı açık; uygulama "onay bağlantısı gönderdik" der. |

| Giriş ekranı (28.09) | ✅ | Sunucu tanımlı derlemede ilk ekran giriş / hesap oluşturma; oturum saklıysa doğrudan uygulama açılır; çıkış yapınca giriş ekranına dönülür, veriler cihazda kalır. Sunucusuz derleme eskisi gibi doğrudan açılır. |

| Derin test ve iyileştirmeler (29.09) | ✅ | Ekranlar gerçek fontlarla tek tek çizilip incelendi. "Hedef ekle" başlığa taşındı (günlük butonları kapatmıyordu); kart altında yan yana "İlerleme ekle / Odaklan"; geniş ekranda başlık içerikle hizalı; büyük yazıda başlık kesilmiyor. Yeniden dağıtma 5 dk adımlarla (+10/+10/+5/+5, 8/8/7/7 değil). "Günlük yük" grafiği plan / kapasite gösteriyor. Yanlış girilen ilerleme geri alınabiliyor (silinmez; eksi düzeltme kaydı). Hedef adı ve hedef süresi değiştirilebiliyor. |
| Eşitleme düzeltmeleri (29.09) | ✅ | **Gizlilik:** aynı cihazda başka hesapla girilince önceki hesabın verisi yeni hesaba yüklenmiyor. Çıkışta gönderilmemiş değişiklik varsa uyarı. **Pazartesi çakışması:** yeni hafta her cihazda aynı kimliklerle açılıyor ve kullanıcı değişikliği sayılmıyor. **Otomatik birleştirme:** iki cihaz farklı şeyleri değiştirdiyse sormadan birleşiyor (ortak sürüm saklanıyor); yalnızca aynı kayıt iki tarafta farklı değiştiyse soruluyor. Açık uygulama dakikada bir küçük bir sorguyla diğer cihazın değişikliğini çekiyor. "Tüm verileri sil" hesaba bağlıyken hesaptan da siliyor ve bunu açıkça söylüyor. |

| Web yayını (29.09) | ✅ | Cloudflare Pages: **https://rota-3t6.pages.dev** (proje `rota`). Supabase Site URL ve Redirect URL bu adrese ayarlı (kullanıcı panelden yaptı). |
| Şifremi unuttum (29.09) | ✅ | Bağlantı yerine e-postayla 6 haneli kod (iPhone'da bağlantı Safari'de açılırdı): kod + yeni şifre → giriş. Supabase'in "Reset Password" e-posta şablonunda `{{ .Token }}` olmalı (kullanıcı panelden düzenler). Gerçek yerel Supabase'te kod doğrulama yolu denendi. |

Doğrulama: 263 uygulama testi (gerçek yerel Supabase'e karşı 4 uçtan uca test dahil) + 25 veritabanı testi geçiyor, `flutter analyze` temiz.

### Yerel çalıştırma

```bash
supabase start
flutter run --dart-define-from-file=env/local.json
```

Buluta bağlı çalıştırma: `flutter run --dart-define-from-file=env/prod.json`
(`env/prod.json` yalnızca URL ve publishable key içerir, git'e girmez;
yeniden üretmek için `supabase projects api-keys --project-ref <ref>`).

Yayın komutları:

```bash
# Web (Cloudflare Pages; `npx wrangler login` bir kez yapıldı)
flutter build web --release --pwa-strategy=none --dart-define-from-file=env/prod.json
npx wrangler pages deploy build/web --project-name rota --branch main

# iPhone (ücretsiz Apple hesabı: 7 günde bir yeniden kur)
flutter build ios --release --dart-define-from-file=env/prod.json
xcrun devicectl device install app --device <cihaz-id> build/ios/iphoneos/Runner.app
```

`env/local.json` git'e girmez; yerel test hesabının bilgileri de oradadır.

## Sıradaki adımlar (öncelik sırasıyla)

1. **iPhone 15 fiziksel test** — hatırlatma teslimatı, odak sayacı, gerçek
   cihazdan buluta eşitleme (CLAUDE.md §20.4).
3. **Yayın** — web hosting seçimi ve iOS TestFlight (Apple Developer hesabı).
4. İsteğe bağlı: sunucu tarafı hatırlatmalar (Edge Function + Cron), hassas
   veriler için cihazda şifreleme.

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
