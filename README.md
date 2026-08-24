# Discourse User Cosmetics Store

`discourse-user-cosmetics` için Discord mağazasına benzeyen, forum içi **Orbs** para birimiyle çalışan tamamlayıcı Discourse eklentisidir.

Bu eklenti kozmetik verilerini kopyalamaz. Ürün ve paketleri mevcut kozmetik kayıtlarına bağlar; satın alma tamamlandığında sahipliği doğrudan `discourse-user-cosmetics` eklentisinin `UserItem` tablosuna verir. Kullanıcı ürünü mevcut **My Cosmetics** arayüzünden seçip takabilir.

## Özellikler

- `/store` adresinde responsive mağaza vitrini
- Öne çıkanlar, editör seçimleri, en çok kullanılanlar, paketler ve yeni ürünler
- Ürün adına, türüne, nadirliğine, etikete, fiyata ve sahipliğe göre filtreleme
- Oturum açmış üyenin gerçek avatarını kullanan kozmetik önizleme kartları
- Ürünü üyenin profil kapağı ve kimliğiyle gösteren 304 × 444 user-card önizlemesi
- Kozmetik ayrıntı ve satın alma penceresi
- Favoriler
- Orbs cüzdanı ve değiştirilemez işlem defteri
- Sunucuda doğrulanan tek seferlik görev ödülleri
- Tekli kozmetik veya çok öğeli paket satışları
- Paketleri katalog limitinden bağımsız vitrinleyen güvenli paket bölümü
- Ürün kartında satın alma ve kullanıcıya hediye etme işlemleri
- Aynı temadaki ürünleri ayrı URL altında toplayan koleksiyon sayfaları
- URL tabanlı mağaza bölümleri ve Discord tarzı **Göz At** açılır menüsü
- Profil efektleri ve çok öğeli paketler için ayrı vitrin bölümleri ve katmanlı önizleme
- Satın alınan ürünlerin mevcut kozmetik seçicisine otomatik açılması
- Stripe, PayPal, PayTR, iyzico, Shopier ve Shipy ile isteğe bağlı gerçek para karşılığı Orb yükleme
- Ürün, görev, Orb paketi, ödeme geçmişi ve kullanıcı cüzdanı için yönetim ekranı
- Eşzamanlı satın alma, çift tıklama ve çift görev talebine karşı satır kilidi + idempotency

## Gereksinim

Önce `discourse-user-cosmetics` kurulmuş ve etkin olmalıdır. Mağaza eklentisi bu bağımlılığı açılışta kontrol eder. Discourse migrasyonlarında eklenti callback sırası garanti edilmediği için mağaza, ihtiyaç duyduğu ana eklenti modellerini güvenli ve idempotent biçimde yükler; bağımlılık gerçekten yoksa rebuild'i kilitlemek yerine sunucu günlüğüne açık bir hata yazar ve mağazayı kullanılamaz bırakır.

## Kurulum

Discourse `containers/app.yml` dosyanızdaki `hooks.after_code` bölümüne, ana kozmetik eklentisinin **altına** ekleyin:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://GITHUB-ADRESINIZ/discourse-user-cosmetics.git
          - git clone https://GITHUB-ADRESINIZ/discourse-user-cosmetics-store.git
```

Ardından standart launcher komutuyla yeniden kurun:

```bash
cd /var/discourse
./launcher rebuild app
```

ZIP kullanıyorsanız klasörü `/var/discourse/shared/standalone/plugins/discourse-user-cosmetics-store` olarak açıp yine rebuild yapabilirsiniz; kalıcı kurulum için Git deposu önerilir.

## Kullanım

- Mağaza: `/store`
- Göz At: `/store/browse`
- Paketler: `/store/browse/bundles`
- Koleksiyonlar: `/store/collections`
- Orbs: `/store/orbs`
- Favoriler: `/store/favorites`
- Yönetim: **Yönetici → Eklentiler → Cosmetics Store**
- Genel ayarlar: **Yönetici → Eklentiler → Cosmetics Store → Ayarlar**

İlk kurulumda örnek görevler otomatik oluşturulur. Ürünler otomatik oluşturulmaz; yönetim ekranından mevcut kozmetik öğeleri seçerek ürün veya paket hazırlayın.

### Ürün erişimi

`Satın alma gerektirir (exclusive)` işaretli bir ürüne bağlı kozmetik, kullanıcı satın alana kadar normal kozmetik seçicisinde kilitli kalır. Şu istisnalar korunur:

- Varsayılan kozmetikler
- Kozmetiğe doğrudan izin veren Discourse grupları
- Ana eklentiden yönetici tarafından daha önce verilmiş sahiplikler

Bir ürünü sadece vitrine koymak, fakat herkese açık bırakmak istiyorsanız `exclusive` seçeneğini kapatın. Herkese açık bir kozmetik zaten kullanılabilir sayıldığı için bu ürün satın alınabilir olarak gösterilmez.

### Paketler

- Tekli ürün tam olarak 1 kozmetik ister.
- Paket en az 2 kozmetik ister.
- Kullanıcı paketin parçalarından birine zaten sahipse aynı paket yeniden satın alınamaz veya hediye edilemez.
- Paketler genel katalog limiti dolsa bile mağazanın paket vitrini ve **Göz At → Paketler** sayfasında tutulur.

### Hediye ve koleksiyonlar

Ürün kartındaki hediye düğmesiyle başka bir aktif forum üyesine tekli kozmetik veya paket gönderilebilir. Tarayıcı yalnız ürün kimliği ve alıcı kullanıcı adını gönderir; fiyat, bakiye, ürünün satış durumu ve alıcının sahipliği sunucuda kilitli bir veritabanı işlemi içinde yeniden okunur. Alıcı paketteki öğelerden birine sahipse, gönderici kendisine hediye göndermeye çalışırsa veya bakiye yetersizse işlem yapılmaz ve hiçbir Orbs düşülmez.

Yönetimde ürünlere aynı **Koleksiyon adı** verildiğinde mağaza bunları `/store/collections/<koleksiyon-slug>` altında toplar. İsteğe bağlı koleksiyon kapak görseli, koleksiyon liste ve ayrıntı sayfalarında kullanılır.

### Görevler

Görev ilerlemesi istemciden kabul edilmez. Aşağıdaki Discourse verilerinden sunucuda hesaplanır:

- Oluşturulan gönderi
- Oluşturulan konu
- Alınan beğeni
- Ziyaret edilen gün
- Güven seviyesi
- Kazanılan rozet
- Hesap yaşı

Bir kullanıcı aynı görevin ödülünü yalnız bir kez alabilir. Her ödül ve satın alma benzersiz idempotency anahtarıyla işlem defterine yazılır.

## Gerçek para ile Orb yükleme

Bu özellik ilk kurulumda kapalıdır. Önce bir sağlayıcıyı test/sandbox ortamında yapılandırın, yönetimde **Ödemeler** sekmesinden bir Orb paketi oluşturun ve yalnız bundan sonra `discourse_cosmetics_store_payments_enabled` ayarını açın.

Kart verisi Discourse'a gelmez. Kullanıcı sağlayıcının barındırdığı ödeme sayfasına yönlendirilir. Orb bakiyesi yalnız şu kontrollerden sonra yüklenir:

- Sağlayıcı webhook/callback imzası doğrulandı.
- Sağlayıcı işlem kimliği daha önce işlenmedi.
- Satın alma anında kaydedilen tutar ve para birimi callback ile birebir eşleşti.
- Cüzdan hareketi benzersiz `payment:<id>` anahtarıyla, veritabanı kilidi içinde yazıldı.
- Sağlayıcı API istekleri yalnız sabit HTTPS alan adı izin listesine, TLS doğrulaması ve kısa zaman aşımıyla gönderildi.
- API anahtarları istemci JSON'una veya ödeme kaydına yazılmadı.

### Sağlayıcı ayarları

| Sağlayıcı | Model | Bildirim adresi |
| --- | --- | --- |
| Stripe | Hosted Checkout | `/cosmetics-store/webhooks/stripe` |
| PayPal | Orders v2 / hosted approval | `/cosmetics-store/webhooks/paypal` |
| PayTR | iFrame API | `/cosmetics-store/callbacks/paytr` |
| iyzico | Checkout Form | `/cosmetics-store/callbacks/iyzico` |
| Shopier | Paket başına hosted ürün bağlantısı | Modern: `/cosmetics-store/webhooks/shopier`, OSB: `/cosmetics-store/callbacks/shopier-osb` |
| Shipy | API v2 hosted ödeme | `/cosmetics-store/callbacks/shipy` |

Bildirim adreslerinin tamamı herkese açık HTTPS URL olmalıdır. PayTR ve Shopier OSB callback'lerine oturum veya CSRF şartı koymayın; sağlayıcı aynı sonucu tekrar gönderebildiği için uç noktalar idempotent çalışır. Stripe `whsec_…`, PayPal webhook ID, PayTR merchant key/salt, iyzico secret key, Shopier webhook token veya OSB kullanıcı adı/şifresi ve Shipy API key yalnız eklenti ayarlarında sunucu tarafında tutulur.

Shopier dinamik checkout oturumu yerine mağazanızda oluşturduğunuz ürün bağlantısını kullanır. Bu nedenle her Orb paketinde ilgili Shopier ürün kimliği ve `shopier.com` HTTPS bağlantısı birlikte girilmelidir. Shopier siparişindeki alıcı e-postası, Orb yüklemesini başlatan etkin Discourse hesabının doğrulanmış birincil e-postasıyla aynı olmalıdır; aksi hâlde teslimat güvenli biçimde reddedilir.

Shopier'in eski Otomatik Sipariş Bildirimi (OSB) ekranını kullanmak için `discourse_cosmetics_store_shopier_osb_username` ve `discourse_cosmetics_store_shopier_osb_password` gizli ayarlarını doldurun. Shopier'deki Bildirim URL alanına `https://FORUM-ADRESINIZ/cosmetics-store/callbacks/shopier-osb` yazın. OSB adaptörü `hash_hmac('sha256', res + username, password)` özetini sabit zamanlı karşılaştırmayla doğrular, Base64 JSON içeriğini boyut sınırlamasıyla ayrıştırır ve test bildirimlerinde Orb yüklemeden tam olarak `success` döndürür. Canlı bildirimlerde `orderid`, ürün kimliği, doğrulanmış birincil e-posta, tutar ve para birimi eşleşmeden cüzdana yazılmaz. Aynı sipariş kimliğinin yeniden gönderilmesi ikinci kez Orb yüklemez.

Modern Shopier webhook kullanılıyorsa OSB kimlik bilgileri yerine `discourse_cosmetics_store_shopier_webhook_token` ayarlanır ve `/cosmetics-store/webhooks/shopier` adresi kullanılır. İki yöntem aynı anda yapılandırılabilir; tek bir yöntemin eksiksiz yapılandırılması Shopier sağlayıcısını hazır duruma getirir. Shipy sağlayıcı sözleşmeleri mağaza hesabına göre değişebildiğinden canlı moda geçmeden önce güncel API v2 callback alanlarını test hesabınızla doğrulayın.

Ödeme sağlayıcı panelinde canlı moda geçmeden önce en az şu senaryoları test edin: başarılı ödeme, başarısız ödeme, kullanıcı dönüş sayfasını kapatma, callback tekrarı, yanlış tutar/para birimi ve zaman aşımı. Geri ödeme/chargeback süreçlerini ayrıca işletme politikanıza bağlayın; eklenti otomatik iade kararı vermez.

## Önemli ayarlar

- Mağazayı etkinleştirme
- Para birimi adı ve simgesi
- Başlangıç bakiyesi
- En yüksek cüzdan bakiyesi
- Katalog ürün limiti
- Görevler, favoriler ve hover önizlemesi
- Hero ve editör seçimi başlıkları
- Gerçek para ile Orb yükleme ana anahtarı
- Sağlayıcı etkinleştirme, sandbox/test ve yalnız sunucuda saklanan API/webhook sırları

## Güncelleme / kaldırma

Güncellemeden önce veritabanı yedeği alın. Eklentiyi devre dışı bırakmak ürünleri ve cüzdanları silmez. Eklenti klasörünü kaldırmadan önce mağazayı kapatın ve rebuild yapın. Satın alma geçmişi bulunan ürünler bütünlük için silinemez; yönetim ekranından pasifleştirilir.

## Sürüm

`1.2.2`

### 1.2.2

- `/store/orbs` bakiye kartına doğrudan **Orb Yükle** düğmesi eklendi.
- Satış yapılandırılmamış olsa bile Orb yükleme alanının görünmesi ve yöneticiye gerekli yapılandırma adımlarını göstermesi sağlandı.
- Orb paketi seçerken giriş yapan kullanıcıların `/store/orbs` sayfasına geri dönmesi sağlandı.

### 1.2.1

- Shopier'in legacy OSB `res`/`hash` protokolü için ayrı, imza doğrulamalı callback eklendi.
- OSB test bildirimleri ödeme ana anahtarı kapalıyken de güvenli şekilde doğrulanıp `success` yanıtı verecek hale getirildi.
- Canlı OSB teslimatı ürün, kullanıcı e-postası, tutar ve para birimi eşleşmesi ile mükerrer `orderid` korumasına bağlandı.
- Modern Shopier webhook desteği korunurken yönetim ekranında OSB Bildirim URL'si de gösterildi.

### 1.2.0

- Paketlerin katalog limiti dolduğunda vitrinden kaybolması engellendi; paket ve koleksiyon ürünleri katalog yüküne açıkça dahil edildi.
- **Göz At** açılır menüsü, aramadan otomatik geçiş ve her mağaza bölümüne doğrudan açılabilen URL rotaları eklendi.
- Ürün kartlarına hover satın alma/hediye düğmeleri ve sunucu doğrulamalı kozmetik hediye sistemi eklendi.
- Aynı kozmetiğe sahip alıcıya hediye gönderme, istemciden fiyat değiştirme, tekrarlı işlem ve eşzamanlı bakiye harcama girişimleri sunucuda engellendi.
- Yönetilebilir koleksiyon adı, slug ve kapak görseli alanları ile koleksiyon liste/ayrıntı sayfaları eklendi.

### 1.1.0

- Profil efekti katman görselinin boş değerle ezilmesi giderildi; profil efektleri ve paketler vitrine ayrı bölümler olarak eklendi.
- Katmanlı profil efekti önizlemesi ve ürün görseli için ilk geçerli kozmetik görseline güvenli geri dönüş eklendi.
- Yönetilebilir Orb paketleri ile Stripe, PayPal, PayTR, iyzico, Shopier ve Shipy ödeme adaptörleri eklendi.
- İmzalı webhook/callback doğrulama, değiştirilemez ödeme anlık görüntüsü, tutar/para birimi doğrulaması ve idempotent cüzdan teslimatı eklendi.
- Sağlayıcı API hedefleri ve kullanıcı yönlendirmeleri HTTPS alan adı izin listeleriyle sınırlandı; kart verisinin forum sunucusundan geçmediği hosted checkout modeli kullanıldı.

### 1.0.6

- Avatar çerçeveleri mağaza kartlarında artık ürünü inceleyen üyenin gerçek forum avatarına uygulanıyor.
- Ürün penceresine, üyenin avatarını ve varsa kart/profil kapak görselini kullanan responsive 304 × 444 user-card önizlemesi eklendi.
- Paket önizlemesinde avatar çerçevesi, isim plakası, kart dekorasyonu ve profil efekti aynı kart üzerinde birlikte gösteriliyor.
- Oturum açmamış ziyaretçiler için güvenli varsayılan avatar ve kapak görünümü korunuyor.

### 1.0.5

- Yönetim bileşeni Discourse admin asset namespace'ine uygun olarak `admin/assets/javascripts/admin/components/` dizinine taşındı.
- `.gjs` şablonundaki `CosmeticsStoreAdminPage` importunun `undefined.default` hatası giderildi.

### 1.0.4

- Yönetim katalog şablonu deprecated `.hbs` yerine `.gjs` ve `RouteTemplate` yapısına geçirildi.
- Katalog route dosyası Ember'ın yeni resolver normalizasyonuna uygun olarak `routes/admin-plugins/show/` klasör hiyerarşisine taşındı.
- `discourse.hbs-extension` ve `discourse.deprecated-resolver-normalization` yönetici uyarıları kaldırıldı.

### 1.0.3

- Yönetim bağlantısı Discourse 2026'nın `adminPlugins.show` eklenti yapılandırma rotasına taşındı.
- Eklenti sayfasına otomatik **Ayarlar** sekmesinin yanında **Mağaza yönetimi** sekmesi eklendi.
- Ürün, görev ve cüzdan yönetim ekranı yeni admin asset dizinine taşındı; eski ve yapılandırılamayan bağlantı kaldırıldı.

### 1.0.2

- İlk migrasyonun zaman damgası `20260824000001` yerine `20260823000123` olarak değiştirildi. Böylece UTC tarihi hâlâ 23 Ağustos olan Discourse sunucularında "timestamped in the future" hatası oluşmaz.

### 1.0.1

- `db:migrate` sırasında ana kozmetik eklentisinin `after_initialize` sırasına bağlı olan sert başlangıç hatası kaldırıldı.
- Ana eklentinin gerekli model ve sunum katmanı dosyaları açıkça, yalnızca eksik olduklarında yükleniyor.
- Kozmetik erişim entegrasyonu tekrar çalıştırılabilir hâle getirildi; aynı modül ikinci kez eklenmiyor.
