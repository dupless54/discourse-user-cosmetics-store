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
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";
const PRODUCTS_ROUTE = "adminPlugins.show.cosmetics-store-products";

const EMPTY_PRODUCT = {
  name: "",
  slug: "",
  description: "",
  product_type: "item",
  price: 0,
  card_image_url: "",
  hero_image_url: "",
  preview_background_url: "",
  collection_name: "",
  collection_slug: "",
  collection_image_url: "",
  rarity_label: "",
  rarity_color: "#000000",
  tags_csv: "",
  sort_order: 0,
  enabled: true,
  featured: false,
  editor_pick: false,
  exclusive: true,
  available_from: "",
  available_until: "",
};

export default class CosmeticsStoreProductForm extends Component {
  @service router;

  @tracked saving = false;
  @tracked cosmeticItemIds = [
    ...(this.args.product?.cosmetic_item_ids ?? []),
  ];

  @cached
  get formData() {
    return {
      ...EMPTY_PRODUCT,
      ...(this.args.product ?? {}),
      cosmetic_item_ids: undefined,
      item_names: undefined,
      tags: undefined,
    };
  }

  get isUpdate() {
    return Boolean(this.args.product?.id);
  }

  get heading() {
    return this.isUpdate
      ? "discourse_cosmetics_store.admin.product.edit"
      : "discourse_cosmetics_store.admin.product.add";
  }

  get cosmeticGroups() {
    const labels = {
      avatar_frame: "discourse_cosmetics_store.admin.product.avatar_frames",
      nameplate: "discourse_cosmetics_store.admin.product.nameplates",
      card_decoration:
        "discourse_cosmetics_store.admin.product.card_decorations",
      profile_effect:
        "discourse_cosmetics_store.admin.product.profile_effects",
    };

    return Object.entries(labels).map(([kind, label]) => ({
      kind,
      label,
      items: (this.args.catalog?.cosmetic_items ?? [])
        .filter((item) => item.kind === kind)
        .map((item) => ({
          ...item,
          selected: this.cosmeticItemIds.includes(item.id),
          disabled: !item.enabled,
        })),
    }));
  }

  @action
  toggleCosmetic(item, productType, event) {
    const ids = new Set(this.cosmeticItemIds);
    if (event.target.checked) {
      if (productType === "item") {
        ids.clear();
      }
      ids.add(item.id);
    } else {
      ids.delete(item.id);
    }
    this.cosmeticItemIds = [...ids];
  }

  @action
  async save(data) {
    if (this.saving) {
      return;
    }

    this.saving = true;
    const cosmeticItemIds =
      data.product_type === "item"
        ? this.cosmeticItemIds.slice(0, 1)
        : this.cosmeticItemIds;
    const payload = {
      ...data,
      cosmetic_item_ids: cosmeticItemIds,
      tags: String(data.tags_csv || "")
        .split(",")
        .map((tag) => tag.trim())
        .filter(Boolean),
      available_from: data.available_from || null,
      available_until: data.available_until || null,
    };
    const url = this.isUpdate
      ? `${ADMIN_API_BASE}/products/${this.args.product.id}.json`
      : `${ADMIN_API_BASE}/products.json`;

    try {
      const saved = await ajax(url, {
        type: this.isUpdate ? "PUT" : "POST",
        data: { product: payload },
      });
      const products = this.args.catalog.products ?? [];
      this.args.catalog.products = this.isUpdate
        ? products.map((row) => (row.id === saved.id ? saved : row))
        : [saved, ...products];
      this.router.transitionTo(PRODUCTS_ROUTE);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <BackButton
      @route={{PRODUCTS_ROUTE}}
      @label="discourse_cosmetics_store.admin.product.back"
    />

    <div class="admin-config-area cstore-admin-product-form-page">
      <div class="admin-config-area__primary-content">
        <AdminConfigAreaCard @heading={{this.heading}}>
          <:content>
            <p>{{i18n "discourse_cosmetics_store.admin.product.exclusive_help"}}</p>

            <Form @onSubmit={{this.save}} @data={{this.formData}} as |form data|>
              <form.Field
                @name="name"
                @title={{i18n "discourse_cosmetics_store.admin.product.name"}}
                @validation="required"
                @format="large"
                @type="input"
                as |field|
              >
                <field.Control maxlength="120" />
              </form.Field>

              <form.Field
                @name="slug"
                @title={{i18n "discourse_cosmetics_store.admin.product.slug"}}
                @format="large"
                @type="input"
                as |field|
              >
                <field.Control
                  maxlength="140"
                  placeholder={{i18n "discourse_cosmetics_store.admin.product.slug_placeholder"}}
                />
              </form.Field>

              <form.Field
                @name="product_type"
                @title={{i18n "discourse_cosmetics_store.admin.product.product_type"}}
                @validation="required"
                @type="select"
                as |field|
              >
                <field.Control as |select|>
                  <select.Option @value="item">{{i18n "discourse_cosmetics_store.admin.product.single"}}</select.Option>
                  <select.Option @value="bundle">{{i18n "discourse_cosmetics_store.admin.product.bundle"}}</select.Option>
                </field.Control>
              </form.Field>

              <form.Field
                @name="price"
                @title={{i18n "discourse_cosmetics_store.admin.product.price"}}
                @validation="required"
                @type="input"
                as |field|
              >
                <field.Control type="number" min="0" />
              </form.Field>

              <form.Field
                @name="rarity_label"
                @title={{i18n "discourse_cosmetics_store.admin.product.rarity_label"}}
                @type="input"
                as |field|
              >
                <field.Control
                  maxlength="40"
                  placeholder={{i18n "discourse_cosmetics_store.admin.product.rarity_placeholder"}}
                />
              </form.Field>

              <form.Field
                @name="rarity_color"
                @title={{i18n "discourse_cosmetics_store.admin.product.rarity_color"}}
                @type="input"
                as |field|
              >
                <field.Control type="color" />
              </form.Field>

              <form.Field
                @name="sort_order"
                @title={{i18n "discourse_cosmetics_store.admin.product.sort_order"}}
                @type="input"
                as |field|
              >
                <field.Control type="number" min="0" />
              </form.Field>

              <form.Field
                @name="tags_csv"
                @title={{i18n "discourse_cosmetics_store.admin.product.tags"}}
                @format="large"
                @type="input"
                as |field|
              >
                <field.Control placeholder={{i18n "discourse_cosmetics_store.admin.product.tags_placeholder"}} />
              </form.Field>

              <form.Field
                @name="collection_name"
                @title={{i18n "discourse_cosmetics_store.admin.product.collection_name"}}
                @type="input"
                as |field|
              >
                <field.Control maxlength="120" placeholder={{i18n "discourse_cosmetics_store.admin.product.collection_placeholder"}} />
              </form.Field>

              <form.Field
                @name="collection_slug"
                @title={{i18n "discourse_cosmetics_store.admin.product.collection_slug"}}
                @type="input"
                as |field|
              >
                <field.Control maxlength="140" placeholder={{i18n "discourse_cosmetics_store.admin.product.collection_slug_placeholder"}} />
              </form.Field>

              <form.Field @name="collection_image_url" @title={{i18n "discourse_cosmetics_store.admin.product.collection_image_url"}} @format="large" @type="input" as |field|>
                <field.Control type="url" />
              </form.Field>
              <form.Field @name="card_image_url" @title={{i18n "discourse_cosmetics_store.admin.product.card_image_url"}} @format="large" @type="input" as |field|>
                <field.Control type="url" />
              </form.Field>
              <form.Field @name="hero_image_url" @title={{i18n "discourse_cosmetics_store.admin.product.hero_image_url"}} @format="large" @type="input" as |field|>
                <field.Control type="url" />
              </form.Field>
              <form.Field @name="preview_background_url" @title={{i18n "discourse_cosmetics_store.admin.product.preview_background_url"}} @format="large" @type="input" as |field|>
                <field.Control type="url" />
              </form.Field>

              <form.Field @name="available_from" @title={{i18n "discourse_cosmetics_store.admin.product.available_from"}} @type="input" as |field|>
                <field.Control type="datetime-local" />
              </form.Field>
              <form.Field @name="available_until" @title={{i18n "discourse_cosmetics_store.admin.product.available_until"}} @type="input" as |field|>
                <field.Control type="datetime-local" />
              </form.Field>

              <form.Field
                @name="description"
                @title={{i18n "discourse_cosmetics_store.admin.product.description"}}
                @format="large"
                @type="textarea"
                as |field|
              >
                <field.Control rows="4" maxlength="4000" />
              </form.Field>

              <form.Field @name="enabled" @title={{i18n "discourse_cosmetics_store.admin.product.enabled"}} @type="checkbox" as |field|><field.Control /></form.Field>
              <form.Field @name="featured" @title={{i18n "discourse_cosmetics_store.admin.product.featured"}} @type="checkbox" as |field|><field.Control /></form.Field>
              <form.Field @name="editor_pick" @title={{i18n "discourse_cosmetics_store.admin.product.editor_pick"}} @type="checkbox" as |field|><field.Control /></form.Field>
              <form.Field @name="exclusive" @title={{i18n "discourse_cosmetics_store.admin.product.exclusive"}} @type="checkbox" as |field|><field.Control /></form.Field>

              <fieldset class="cstore-admin-items">
                <legend>{{i18n "discourse_cosmetics_store.admin.product.cosmetics"}}</legend>
                <p>
                  {{if
                    (eq data.product_type "item")
                    (i18n "discourse_cosmetics_store.admin.product.single_selection_help")
                    (i18n "discourse_cosmetics_store.admin.product.bundle_selection_help")
                  }}
                </p>
                {{#each this.cosmeticGroups as |group|}}
                  <section>
                    <h4>{{i18n group.label}}</h4>
                    <div>
                      {{#each group.items as |item|}}
                        <label class={{if item.enabled "" "is-disabled-item"}}>
                          <input
                            type={{if (eq data.product_type "item") "radio" "checkbox"}}
                            name={{if (eq data.product_type "item") "cosmetic-item" "cosmetic-items"}}
                            checked={{item.selected}}
                            disabled={{item.disabled}}
                            {{on "change" (fn this.toggleCosmetic item data.product_type)}}
                          />
                          <span>
                            {{#if item.image_url}}
                              <img src={{item.image_url}} alt="" loading="lazy" />
                            {{else}}
                              <i>✦</i>
                            {{/if}}
                            <b>{{item.name}}</b>
                            <small>{{item.rarity_label}}</small>
                          </span>
                        </label>
                      {{/each}}
                    </div>
                  </section>
                {{/each}}
              </fieldset>

              <form.Submit
                @label="discourse_cosmetics_store.admin.product.save"
                @disabled={{this.saving}}
              />
            </Form>
          </:content>
        </AdminConfigAreaCard>
      </div>
    </div>
  </template>
}
