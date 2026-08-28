import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";

const ACTION_LABELS = {
  product_created: "Ürün oluşturuldu",
  product_updated: "Ürün güncellendi",
  product_deleted: "Ürün silindi",
  mission_created: "Görev oluşturuldu",
  mission_updated: "Görev güncellendi",
  mission_deleted: "Görev silindi",
  mission_disabled: "Görev kapatıldı",
  wallet_adjusted: "Cüzdan ayarlandı",
  orb_package_created: "Orb paketi oluşturuldu",
  orb_package_updated: "Orb paketi güncellendi",
  orb_package_deleted: "Orb paketi silindi",
  orb_package_disabled: "Orb paketi kapatıldı",
  refund_recorded: "İade kaydedildi",
};

const DETAIL_LABELS = {
  entity_id: "Kayıt ID",
  entity_name: "Ad",
  entity_type: "Tür",
  changed_fields: "Değişen alanlar",
  target_user_id: "Kullanıcı ID",
  target_username: "Kullanıcı",
  amount: "Miktar",
  balance_after: "Yeni bakiye",
  debt_after: "Yeni borç",
  orb_amount: "Orb miktarı",
  price_minor: "Fiyat (minor)",
  currency: "Para birimi",
  payment_id: "Ödeme ID",
  refund_id: "İade ID",
  refund_amount_minor: "İade tutarı (minor)",
  refunded_orb_amount: "Geri alınan Orb",
};

export default class CosmeticsStoreAuditAdmin extends Component {
  @tracked query = "";
  @tracked selectedAction = "";

  get entries() {
    return this.args.entries ?? [];
  }

  get actionOptions() {
    return [...new Set(this.entries.map((entry) => entry.action))]
      .sort()
      .map((actionName) => ({
        value: actionName,
        label: ACTION_LABELS[actionName] ?? actionName,
      }));
  }

  get filteredEntries() {
    const query = this.query.trim().toLocaleLowerCase("tr-TR");

    return this.entries.filter((entry) => {
      if (this.selectedAction && entry.action !== this.selectedAction) {
        return false;
      }

      if (!query) {
        return true;
      }

      const searchable = [
        entry.actor?.username,
        ACTION_LABELS[entry.action] ?? entry.action,
        entry.subject,
        ...Object.values(entry.details ?? {}),
      ]
        .filter(Boolean)
        .join(" ")
        .toLocaleLowerCase("tr-TR");

      return searchable.includes(query);
    });
  }

  get rows() {
    return this.filteredEntries.map((entry) => ({
      ...entry,
      actionLabel: ACTION_LABELS[entry.action] ?? entry.action,
      detailRows: Object.entries(entry.details ?? {}).map(([key, value]) => ({
        key,
        label: DETAIL_LABELS[key] ?? key,
        value,
      })),
    }));
  }

  @action
  updateQuery(event) {
    this.query = event.target.value;
  }

  @action
  updateAction(event) {
    this.selectedAction = event.target.value;
  }

  @action
  resetFilters() {
    this.query = "";
    this.selectedAction = "";
  }

  <template>
    <section class="cstore-audit" aria-labelledby="cstore-audit-title">
      <div class="cstore-audit__heading">
        <div>
          <p>YÖNETİCİ İŞLEM GÜNLÜĞÜ</p>
          <h2 id="cstore-audit-title">Audit Log</h2>
          <span>Discourse StaffActionLogger üzerinden tutulan son {{this.entries.length}} Store yönetici işlemi.</span>
        </div>
        <small>Salt okunur · sayfa yenilendiğinde güncellenir</small>
      </div>

      <div class="cstore-audit__filters">
        <label>
          Ara
          <input
            type="search"
            value={{this.query}}
            placeholder="Yönetici, işlem veya kayıt ara"
            {{on "input" this.updateQuery}}
          />
        </label>
        <label>
          İşlem
          <select value={{this.selectedAction}} {{on "change" this.updateAction}}>
            <option value="">Tüm işlemler</option>
            {{#each this.actionOptions as |option|}}
              <option value={{option.value}}>{{option.label}}</option>
            {{/each}}
          </select>
        </label>
        <button
          class="btn btn-default"
          type="button"
          disabled={{if (or this.query this.selectedAction) false true}}
          {{on "click" this.resetFilters}}
        >
          Filtreleri temizle
        </button>
      </div>

      <div class="cstore-audit__list">
        {{#each this.rows as |row|}}
          <article class="cstore-audit__entry">
            <header>
              <div>
                <strong>{{row.actionLabel}}</strong>
                <span>@{{row.actor.username}}</span>
              </div>
              <time datetime={{row.created_at}}>{{row.created_at}}</time>
            </header>

            <div class="cstore-audit__subject">{{row.subject}}</div>

            {{#if row.detailRows.length}}
              <dl>
                {{#each row.detailRows as |detail|}}
                  <div>
                    <dt>{{detail.label}}</dt>
                    <dd>{{detail.value}}</dd>
                  </div>
                {{/each}}
              </dl>
            {{/if}}
          </article>
        {{else}}
          <div class="cstore-audit__empty">
            <strong>Eşleşen yönetici işlemi yok.</strong>
            <span>Filtreleri temizleyebilir veya yeni işlemler için sayfayı yenileyebilirsin.</span>
          </div>
        {{/each}}
      </div>
    </section>
  </template>
}
