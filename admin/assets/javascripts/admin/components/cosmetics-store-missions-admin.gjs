import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";

const EMPTY_MISSION = {
  key: "",
  name: "",
  description: "",
  metric: "posts_created",
  target: 1,
  reward: 25,
  icon: "✦",
  sort_order: 0,
  enabled: true,
  available_from: "",
  available_until: "",
};

export default class CosmeticsStoreMissionsAdmin extends Component {
  @tracked missions = this.args.model?.missions ?? [];
  @tracked editingMission = null;
  @tracked saving = false;
  @tracked status = null;

  get missionMetrics() {
    return this.args.model?.mission_metrics ?? [];
  }

  get settings() {
    return this.args.model?.settings ?? {
      currency_name: "Orbs",
      currency_symbol: "◈",
    };
  }

  @action
  newMission() {
    this.editingMission = { ...EMPTY_MISSION };
    this.status = null;
  }

  @action
  editMission(mission) {
    this.editingMission = { ...mission };
    this.status = null;
  }

  @action
  cancelMission() {
    this.editingMission = null;
  }

  @action
  updateMission(field, event) {
    let value =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;
    if (["target", "reward", "sort_order"].includes(field)) {
      value = Number.parseInt(value || "0", 10);
    }
    this.editingMission = { ...this.editingMission, [field]: value };
  }

  @action
  async saveMission(event) {
    event?.preventDefault();
    if (this.saving) {
      return;
    }

    this.saving = true;
    const mission = this.editingMission;
    const payload = {
      ...mission,
      available_from: mission.available_from || null,
      available_until: mission.available_until || null,
    };
    const url = mission.id
      ? `${ADMIN_API_BASE}/missions/${mission.id}.json`
      : `${ADMIN_API_BASE}/missions.json`;

    try {
      const saved = await ajax(url, {
        type: mission.id ? "PUT" : "POST",
        data: { mission: payload },
      });
      this.missions = mission.id
        ? this.missions.map((row) => (row.id === saved.id ? saved : row))
        : [...this.missions, saved];
      this.editingMission = null;
      this.status = "Görev kaydedildi.";
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  @action
  async deleteMission(mission) {
    if (
      !window.confirm(`“${mission.name}” görevini kaldırmak istediğine emin misin?`)
    ) {
      return;
    }

    try {
      await ajax(`${ADMIN_API_BASE}/missions/${mission.id}.json`, {
        type: "DELETE",
      });
      if (mission.claim_count > 0) {
        this.missions = this.missions.map((row) =>
          row.id === mission.id ? { ...row, enabled: false } : row
        );
        this.status = "Geçmişi olan görev pasifleştirildi.";
      } else {
        this.missions = this.missions.filter((row) => row.id !== mission.id);
        this.status = "Görev silindi.";
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <section class="cstore-admin cstore-admin__section cstore-admin-missions-section">
      <div class="cstore-admin__section-heading">
        <div>
          <h2>Orbs görevleri</h2>
          <p>İlerleme tarayıcıdan değil, Discourse kullanıcı istatistiklerinden doğrulanır.</p>
        </div>
        <button class="btn btn-primary" type="button" {{on "click" this.newMission}}>+ Yeni görev</button>
      </div>

      {{#if this.status}}
        <div class="cstore-admin__status" role="status">✓ {{this.status}}</div>
      {{/if}}

      {{#if this.editingMission}}
        <form class="cstore-admin-form cstore-admin-form--mission" {{on "submit" this.saveMission}}>
          <div class="cstore-admin-form__title">
            <h3>{{if this.editingMission.id "Görevi düzenle" "Yeni görev"}}</h3>
            <button type="button" {{on "click" this.cancelMission}}>×</button>
          </div>
          <div class="cstore-admin-form__grid">
            <label>Görev adı<input required value={{this.editingMission.name}} {{on "input" (fn this.updateMission "name")}} /></label>
            <label>Anahtar<input value={{this.editingMission.key}} {{on "input" (fn this.updateMission "key")}} placeholder="otomatik-anahtar" /></label>
            <label>Metrik<select value={{this.editingMission.metric}} {{on "change" (fn this.updateMission "metric")}}>{{#each this.missionMetrics as |metric|}}<option value={{metric.value}}>{{metric.label}}</option>{{/each}}</select></label>
            <label>Hedef<input min="1" type="number" value={{this.editingMission.target}} {{on "input" (fn this.updateMission "target")}} /></label>
            <label>Ödül<input min="0" type="number" value={{this.editingMission.reward}} {{on "input" (fn this.updateMission "reward")}} /></label>
            <label>Simge<input maxlength="20" value={{this.editingMission.icon}} {{on "input" (fn this.updateMission "icon")}} /></label>
            <label>Sıra<input min="0" type="number" value={{this.editingMission.sort_order}} {{on "input" (fn this.updateMission "sort_order")}} /></label>
            <label class="cstore-admin-checkbox"><input type="checkbox" checked={{this.editingMission.enabled}} {{on "change" (fn this.updateMission "enabled")}} /> Etkin</label>
            <label>Başlangıç<input type="datetime-local" value={{this.editingMission.available_from}} {{on "input" (fn this.updateMission "available_from")}} /></label>
            <label>Bitiş<input type="datetime-local" value={{this.editingMission.available_until}} {{on "input" (fn this.updateMission "available_until")}} /></label>
            <label class="is-wide">Açıklama<textarea rows="3" maxlength="500" value={{this.editingMission.description}} {{on "input" (fn this.updateMission "description")}}></textarea></label>
          </div>
          <div class="cstore-admin-form__actions">
            <button class="btn" type="button" {{on "click" this.cancelMission}}>İptal</button>
            <button class="btn btn-primary" type="submit" disabled={{this.saving}}>{{if this.saving "Kaydediliyor…" "Kaydet"}}</button>
          </div>
        </form>
      {{/if}}

      <div class="cstore-admin-missions">
        {{#each this.missions as |mission|}}
          <article>
            <span>{{mission.icon}}</span>
            <div>
              <strong>{{mission.name}}</strong>
              <p>{{mission.description}}</p>
              <small>{{mission.metric}} · hedef {{mission.target}} · {{mission.claim_count}} kez alındı</small>
            </div>
            <b>+{{mission.reward}} {{this.settings.currency_symbol}}</b>
            <i class={{if mission.enabled "is-on" "is-off"}}>{{if mission.enabled "Etkin" "Kapalı"}}</i>
            <button class="btn btn-text btn-small" type="button" {{on "click" (fn this.editMission mission)}}>Düzenle</button>
            <button class="btn btn-danger btn-small" type="button" {{on "click" (fn this.deleteMission mission)}}>{{if mission.claim_count "Kapat" "Sil"}}</button>
          </article>
        {{else}}
          <p>Henüz görev yok.</p>
        {{/each}}
      </div>
    </section>
  </template>
}
