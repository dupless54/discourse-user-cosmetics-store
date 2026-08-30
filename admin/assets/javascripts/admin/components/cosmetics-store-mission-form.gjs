import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import BackButton from "discourse/components/back-button";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";
const MISSIONS_ROUTE = "adminPlugins.show.cosmetics-store-missions";

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

export default class CosmeticsStoreMissionForm extends Component {
  @service router;

  @tracked saving = false;

  @cached
  get formData() {
    return {
      ...EMPTY_MISSION,
      ...(this.args.mission ?? {}),
    };
  }

  get isUpdate() {
    return Boolean(this.args.mission?.id);
  }

  get heading() {
    return this.isUpdate
      ? "discourse_cosmetics_store.admin.mission.edit"
      : "discourse_cosmetics_store.admin.mission.add";
  }

  get missionMetrics() {
    return this.args.catalog?.mission_metrics ?? [];
  }

  @action
  async save(data) {
    if (this.saving) {
      return;
    }

    this.saving = true;
    const payload = {
      ...data,
      available_from: data.available_from || null,
      available_until: data.available_until || null,
    };
    const url = this.isUpdate
      ? `${ADMIN_API_BASE}/missions/${this.args.mission.id}.json`
      : `${ADMIN_API_BASE}/missions.json`;

    try {
      const saved = await ajax(url, {
        type: this.isUpdate ? "PUT" : "POST",
        data: { mission: payload },
      });
      const missions = this.args.catalog.missions ?? [];
      this.args.catalog.missions = this.isUpdate
        ? missions.map((row) => (row.id === saved.id ? saved : row))
        : [...missions, saved];
      this.router.transitionTo(MISSIONS_ROUTE);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <BackButton
      @route={{MISSIONS_ROUTE}}
      @label="discourse_cosmetics_store.admin.mission.back"
    />

    <div class="admin-config-area cstore-admin-mission-form-page">
      <div class="admin-config-area__primary-content">
        <AdminConfigAreaCard @heading={{this.heading}}>
          <:content>
            <p>{{i18n "discourse_cosmetics_store.admin.mission.verification_help"}}</p>

            <Form @onSubmit={{this.save}} @data={{this.formData}} as |form|>
              <form.Field
                @name="name"
                @title={{i18n "discourse_cosmetics_store.admin.mission.name"}}
                @validation="required"
                @format="large"
                @type="input"
                as |field|
              >
                <field.Control maxlength="120" />
              </form.Field>

              <form.Field
                @name="key"
                @title={{i18n "discourse_cosmetics_store.admin.mission.key"}}
                @format="large"
                @type="input"
                as |field|
              >
                <field.Control
                  maxlength="120"
                  placeholder={{i18n "discourse_cosmetics_store.admin.mission.key_placeholder"}}
                />
              </form.Field>

              <form.Field
                @name="metric"
                @title={{i18n "discourse_cosmetics_store.admin.mission.metric"}}
                @validation="required"
                @type="select"
                as |field|
              >
                <field.Control @includeNone={{false}} as |select|>
                  {{#each this.missionMetrics as |metric|}}
                    <select.Option @value={{metric.value}}>{{metric.label}}</select.Option>
                  {{/each}}
                </field.Control>
              </form.Field>

              <form.Field
                @name="target"
                @title={{i18n "discourse_cosmetics_store.admin.mission.target"}}
                @validation="required"
                @type="input-number"
                as |field|
              >
                <field.Control min="1" step="1" />
              </form.Field>

              <form.Field
                @name="reward"
                @title={{i18n "discourse_cosmetics_store.admin.mission.reward"}}
                @validation="required"
                @type="input-number"
                as |field|
              >
                <field.Control min="0" step="1" />
              </form.Field>

              <form.Field
                @name="icon"
                @title={{i18n "discourse_cosmetics_store.admin.mission.icon"}}
                @type="input"
                as |field|
              >
                <field.Control maxlength="20" />
              </form.Field>

              <form.Field
                @name="sort_order"
                @title={{i18n "discourse_cosmetics_store.admin.mission.sort_order"}}
                @type="input-number"
                as |field|
              >
                <field.Control min="0" step="1" />
              </form.Field>

              <form.Field
                @name="enabled"
                @title={{i18n "discourse_cosmetics_store.admin.mission.enabled"}}
                @type="checkbox"
                as |field|
              >
                <field.Control />
              </form.Field>

              <form.Field
                @name="available_from"
                @title={{i18n "discourse_cosmetics_store.admin.mission.available_from"}}
                @type="input"
                as |field|
              >
                <field.Control type="datetime-local" />
              </form.Field>

              <form.Field
                @name="available_until"
                @title={{i18n "discourse_cosmetics_store.admin.mission.available_until"}}
                @type="input"
                as |field|
              >
                <field.Control type="datetime-local" />
              </form.Field>

              <form.Field
                @name="description"
                @title={{i18n "discourse_cosmetics_store.admin.mission.description"}}
                @format="large"
                @type="textarea"
                as |field|
              >
                <field.Control maxlength="500" rows="3" />
              </form.Field>

              <form.Submit
                @label="discourse_cosmetics_store.admin.mission.save"
                @disabled={{this.saving}}
              />
            </Form>
          </:content>
        </AdminConfigAreaCard>
      </div>
    </div>
  </template>
}
