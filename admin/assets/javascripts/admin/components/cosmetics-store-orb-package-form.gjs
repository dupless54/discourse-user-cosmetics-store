import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import BackButton from "discourse/components/back-button";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";
const PAYMENTS_ROUTE = "adminPlugins.show.cosmetics-store-payments";

const EMPTY_PACKAGE = {
  name: "",
  description: "",
  orb_amount: 100,
  price: "49.90",
  currency: "TRY",
  sort_order: 0,
  enabled: true,
  featured: false,
  shopier_product_id: "",
  shopier_checkout_url: "",
};

export default class CosmeticsStoreOrbPackageForm extends Component {
  @service router;

  @tracked saving = false;
  @tracked validationError = null;
  @tracked providerIds = this.args.package
    ? [...(this.args.package.providers ?? [])]
    : (this.args.catalog?.payment_providers ?? [])
        .filter((provider) => provider.enabled)
        .map((provider) => provider.id);

  @cached
  get formData() {
    return {
      ...EMPTY_PACKAGE,
      ...(this.args.package ?? {}),
      providers: undefined,
      price_minor: undefined,
      payment_count: undefined,
    };
  }

  get isUpdate() {
    return Boolean(this.args.package?.id);
  }

  get heading() {
    return this.isUpdate
      ? "discourse_cosmetics_store.admin.orb_package.edit"
      : "discourse_cosmetics_store.admin.orb_package.add";
  }

  get providerRows() {
    return (this.args.catalog?.payment_providers ?? []).map((provider) => ({
      ...provider,
      selected: this.providerIds.includes(provider.id),
    }));
  }

  @action
  toggleProvider(provider, event) {
    const selected = new Set(this.providerIds);
    if (event.target.checked) {
      selected.add(provider.id);
    } else {
      selected.delete(provider.id);
    }
    this.providerIds = [...selected];
  }

  @action
  async save(data) {
    if (this.saving) {
      return;
    }

    const priceMinor = Math.round(
      Number.parseFloat(String(data.price).replace(",", ".")) * 100
    );
    if (!Number.isFinite(priceMinor) || priceMinor <= 0) {
      this.validationError = i18n(
        "discourse_cosmetics_store.admin.orb_package.invalid_price"
      );
      return;
    }

    this.validationError = null;
    this.saving = true;
    const payload = {
      ...data,
      price_minor: priceMinor,
      providers: this.providerIds,
    };
    const url = this.isUpdate
      ? `${ADMIN_API_BASE}/orb-packages/${this.args.package.id}.json`
      : `${ADMIN_API_BASE}/orb-packages.json`;

    try {
      const saved = await ajax(url, {
        type: this.isUpdate ? "PUT" : "POST",
        data: { orb_package: payload },
      });
      const packages = this.args.catalog.orb_packages ?? [];
      this.args.catalog.orb_packages = this.isUpdate
        ? packages.map((row) => (row.id === saved.id ? saved : row))
        : [...packages, saved];
      this.router.transitionTo(PAYMENTS_ROUTE);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <BackButton
      @route={{PAYMENTS_ROUTE}}
      @label="discourse_cosmetics_store.admin.orb_package.back"
    />

    <div class="admin-config-area cstore-admin-orb-package-form-page">
      <div class="admin-config-area__primary-content">
        <AdminConfigAreaCard @heading={{this.heading}}>
          <:content>
            <p>{{i18n "discourse_cosmetics_store.admin.orb_package.snapshot_help"}}</p>

            {{#if this.validationError}}
              <div class="alert alert-error" role="alert">
                {{this.validationError}}
              </div>
            {{/if}}

            <Form @onSubmit={{this.save}} @data={{this.formData}} as |form|>
              <form.Field
                @name="name"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.name"}}
                @validation="required"
                @format="large"
                @type="input"
                as |field|
              >
                <field.Control maxlength="120" />
              </form.Field>

              <form.Field
                @name="orb_amount"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.orb_amount"}}
                @validation="required"
                @type="input-number"
                as |field|
              >
                <field.Control min="1" />
              </form.Field>

              <form.Field
                @name="price"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.price"}}
                @description={{i18n "discourse_cosmetics_store.admin.orb_package.price_help"}}
                @validation="required"
                @type="input"
                as |field|
              >
                <field.Control inputmode="decimal" placeholder="49.90" />
              </form.Field>

              <form.Field
                @name="currency"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.currency"}}
                @validation="required"
                @type="select"
                as |field|
              >
                <field.Control as |select|>
                  <select.Option @value="TRY">TRY</select.Option>
                  <select.Option @value="USD">USD</select.Option>
                  <select.Option @value="EUR">EUR</select.Option>
                  <select.Option @value="GBP">GBP</select.Option>
                </field.Control>
              </form.Field>

              <form.Field
                @name="sort_order"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.sort_order"}}
                @type="input-number"
                as |field|
              >
                <field.Control min="0" />
              </form.Field>

              <form.Field
                @name="description"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.description"}}
                @format="large"
                @type="textarea"
                as |field|
              >
                <field.Control maxlength="500" rows="3" />
              </form.Field>

              <form.Field
                @name="shopier_checkout_url"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.shopier_checkout_url"}}
                @description={{i18n "discourse_cosmetics_store.admin.orb_package.shopier_checkout_help"}}
                @format="large"
                @type="input"
                as |field|
              >
                <field.Control
                  type="url"
                  placeholder="https://www.shopier.com/..."
                />
              </form.Field>

              <form.Field
                @name="shopier_product_id"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.shopier_product_id"}}
                @type="input"
                as |field|
              >
                <field.Control maxlength="190" />
              </form.Field>

              <fieldset class="cstore-admin-provider-flags">
                <legend>{{i18n "discourse_cosmetics_store.admin.orb_package.providers"}}</legend>
                <p>{{i18n "discourse_cosmetics_store.admin.orb_package.providers_help"}}</p>
                {{#each this.providerRows as |provider|}}
                  <label>
                    <input
                      type="checkbox"
                      checked={{provider.selected}}
                      disabled={{if provider.enabled false true}}
                      {{on "change" (fn this.toggleProvider provider)}}
                    />
                    {{provider.label}}
                    <small>
                      {{if
                        provider.enabled
                        (i18n "discourse_cosmetics_store.admin.orb_package.provider_ready")
                        (i18n "discourse_cosmetics_store.admin.orb_package.provider_unconfigured")
                      }}
                    </small>
                  </label>
                {{/each}}
              </fieldset>

              <form.Field
                @name="enabled"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.enabled"}}
                @type="checkbox"
                as |field|
              >
                <field.Control />
              </form.Field>

              <form.Field
                @name="featured"
                @title={{i18n "discourse_cosmetics_store.admin.orb_package.featured"}}
                @type="checkbox"
                as |field|
              >
                <field.Control />
              </form.Field>

              <form.Submit
                @label="discourse_cosmetics_store.admin.orb_package.save"
                @disabled={{this.saving}}
              />
            </Form>
          </:content>
        </AdminConfigAreaCard>
      </div>
    </div>
  </template>
}
