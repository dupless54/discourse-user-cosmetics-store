import Component from "@glimmer/component";

const LABELS = {
  store_enabled: "Mağaza durumu",
  base_plugin: "User Cosmetics bağımlılığı",
  integration: "Resmî Integration API",
  preview_contract: "Önizleme sözleşmesi",
  loadout_contract: "Kozmetik seti sözleşmesi",
  empty_products: "İçeriği boş etkin ürünler",
  disabled_cosmetic_items: "Kapalı kozmetiğe bağlı etkin ürünler",
  invalid_availability: "Geçersiz satış tarihleri",
  payment_providers: "Ödeme sağlayıcıları",
};

const DESCRIPTIONS = {
  store_enabled: "Mağaza site ayarının kullanılabilir durumda olduğunu doğrular.",
  base_plugin: "Store'un kozmetik sahipliği için bağlı olduğu Base plugin modellerini doğrular.",
  integration: "Sahiplik ve entitlement işlemlerinin public Integration API üzerinden kullanılabilir olduğunu doğrular.",
  preview_contract: "Canlı Önizleme için atomik seçim sözleşmesini doğrular.",
  loadout_contract: "Kozmetik setlerini kaydetme ve atomik uygulama sözleşmesini doğrular.",
  empty_products: "Yayında olup hiçbir kozmetik öğesine bağlı olmayan ürünleri sayar.",
  disabled_cosmetic_items: "Yayında olup Base tarafında kapatılmış kozmetiklere bağlı ürünleri sayar.",
  invalid_availability: "Başlangıç tarihi bitiş tarihinden sonra veya eşit olan kayıtları sayar.",
  payment_providers: "Sadece yapılandırılmış sağlayıcı sayısını gösterir; anahtar veya secret göstermez.",
};

export default class CosmeticsStoreHealthAdmin extends Component {
  get health() {
    return this.args.health ?? { status: "critical", checks: [] };
  }

  get statusLabel() {
    return {
      healthy: "Sağlıklı",
      warning: "Kontrol gerekli",
      critical: "Kritik",
    }[this.health.status] ?? "Bilinmiyor";
  }

  get rows() {
    return (this.health.checks ?? []).map((check) => ({
      ...check,
      label: LABELS[check.id] ?? check.id,
      description: DESCRIPTIONS[check.id] ?? "",
      valueLabel: this.valueLabel(check),
      statusLabel:
        { ok: "Tamam", warning: "Uyarı", critical: "Kritik" }[check.status] ??
        check.status,
    }));
  }

  valueLabel(check) {
    if (check.id === "payment_providers") {
      return check.payments_enabled
        ? `${check.value} / ${check.total} yapılandırılmış`
        : `Ödemeler kapalı · ${check.value} / ${check.total} yapılandırılmış`;
    }

    if (
      ["store_enabled", "base_plugin", "integration", "preview_contract", "loadout_contract"].includes(
        check.id,
      )
    ) {
      return check.value ? "Hazır" : "Hazır değil";
    }

    return String(check.value ?? 0);
  }

  <template>
    <section
      class="cstore-health cstore-health--{{this.health.status}}"
      aria-labelledby="cstore-health-title"
    >
      <div class="cstore-health__heading">
        <div>
          <p>SİSTEM TEŞHİSİ</p>
          <h2 id="cstore-health-title">Sistem Sağlığı</h2>
          <span>Bağımlılıkları ve mağaza veri bütünlüğünü salt okunur olarak kontrol eder.</span>
        </div>
        <strong class="cstore-health__overall">{{this.statusLabel}}</strong>
      </div>

      <div class="cstore-health__grid">
        {{#each this.rows as |row|}}
          <article class="cstore-health__check cstore-health__check--{{row.status}}">
            <div class="cstore-health__check-heading">
              <strong>{{row.label}}</strong>
              <span>{{row.statusLabel}}</span>
            </div>
            <b>{{row.valueLabel}}</b>
            <p>{{row.description}}</p>
          </article>
        {{/each}}
      </div>

      {{#if this.health.checked_at}}
        <small class="cstore-health__checked-at">Son kontrol: {{this.health.checked_at}}</small>
      {{/if}}
    </section>
  </template>
}
