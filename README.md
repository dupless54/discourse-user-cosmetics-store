# Discourse User Cosmetics Store

`discourse-user-cosmetics` için Discord mağazasına benzeyen, forum içi **Orbs** para birimiyle çalışan tamamlayıcı Discourse eklentisidir.

Bu eklenti kozmetik verilerini kopyalamaz. Ürün ve paketleri mevcut kozmetik kayıtlarına bağlar; satın alma tamamlandığında sahipliği doğrudan `discourse-user-cosmetics` eklentisinin `UserItem` tablosuna verir. Kullanıcı ürünü mevcut **My Cosmetics** arayüzünden seçip takabilir.

## Özellikler

- `/store` adresinde responsive mağaza vitrini
- Öne çıkanlar, editör seçimleri, en çok kullanılanlar, paketler ve yeni ürünler
- Ürün adına, türüne, nadirliğine, etikete, fiyata ve sahipliğe göre filtreleme
- Kozmetik önizleme kartları ve ayrıntı/satın alma penceresi
- Favoriler
- Orbs cüzdanı ve değiştirilemez işlem defteri
- Sunucuda doğrulanan tek seferlik görev ödülleri
- Tekli kozmetik veya çok öğeli paket satışları
- Satın alınan ürünlerin mevcut kozmetik seçicisine otomatik açılması
- Ürün, görev ve kullanıcı cüzdanı için yönetim ekranı
- Eşzamanlı satın alma, çift tıklama ve çift görev talebine karşı satır kilidi + idempotency

## Gereksinim

Önce `discourse-user-cosmetics` kurulmuş ve etkin olmalıdır. Mağaza eklentisi açılışta bu bağımlılığı kontrol eder; eksikse açık bir hata vererek başlatmayı durdurur.

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
- Kullanıcı paketin bazı parçalarına önceden sahipse, satın almada yalnız eksik sahiplikler fiilen eklenir; tekrar satır oluşturulmaz.

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

## Önemli ayarlar

- Mağazayı etkinleştirme
- Para birimi adı ve simgesi
- Başlangıç bakiyesi
- En yüksek cüzdan bakiyesi
- Katalog ürün limiti
- Görevler, favoriler ve hover önizlemesi
- Hero ve editör seçimi başlıkları

## Güncelleme / kaldırma

Güncellemeden önce veritabanı yedeği alın. Eklentiyi devre dışı bırakmak ürünleri ve cüzdanları silmez. Eklenti klasörünü kaldırmadan önce mağazayı kapatın ve rebuild yapın. Satın alma geçmişi bulunan ürünler bütünlük için silinemez; yönetim ekranından pasifleştirilir.

## Sürüm

`1.0.0`
"# discourse-user-cosmetics-store" 
