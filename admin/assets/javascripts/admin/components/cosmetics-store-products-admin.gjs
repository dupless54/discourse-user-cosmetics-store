import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import AdminConfigAreaEmptyList from "discourse/admin/components/admin-config-area-empty-list";
import DButton from "discourse/ui-kit/d-button";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";
const EDIT_ROUTE = "adminPlugins.show.cosmetics-store-products.edit";
const NEW_ROUTE = "adminPlugins.show.cosmetics-store-products.new";

export default class CosmeticsStoreProductsAdmin extends Component {
  @service dialog;

  @tracked products = this.args.model?.products ?? [];
  @tracked status = null;

  get settings() {
    return this.args.model?.settings ?? {
      currency_name: "Orbs",
      currency_symbol: "◈",
    };
  }

  @action
  deleteProduct(product) {
    return this.dialog.confirm({
      message: i18n("discourse_cosmetics_store.admin.product.delete_confirm", {
        name: product.name,
      }),
      didConfirm: async () => {
        try {
          await ajax(`${ADMIN_API_BASE}/products/${product.id}.json`, {
            type: "DELETE",
          });
          const products = this.products.filter((row) => row.id !== product.id);
          this.products = products;
          this.args.model.products = products;
          this.status = i18n("discourse_cosmetics_store.admin.product.deleted");
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  }

  <template>
    <section class="cstore-admin cstore-admin-products">
      {{#if this.status}}
        <div class="cstore-admin__status" role="status">✓ {{this.status}}</div>
      {{/if}}

      {{#if this.products.length}}
        <div class="cstore-admin-table-wrap">
          <table class="d-table cstore-admin-table">
            <thead class="d-table__header">
              <tr>
                <th>{{i18n "discourse_cosmetics_store.admin.product.columns.product"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.product.columns.type"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.product.columns.contents"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.product.columns.price"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.product.columns.storefront"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.product.columns.sales"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.product.columns.actions"}}</th>
              </tr>
            </thead>
            <tbody class="d-table__body">
              {{#each this.products as |product|}}
                <tr class="d-table__row">
                  <td class="d-table__cell --overview">
                    <strong>{{product.name}}</strong><small>/{{product.slug}}</small>
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.product.columns.type"}}</div>
                    {{if (eq product.product_type "bundle") (i18n "discourse_cosmetics_store.admin.product.bundle") (i18n "discourse_cosmetics_store.admin.product.single")}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.product.columns.contents"}}</div>
                    {{i18n "discourse_cosmetics_store.admin.product.item_count" count=product.item_names.length}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.product.columns.price"}}</div>
                    {{this.settings.currency_symbol}} {{product.price}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.product.columns.storefront"}}</div>
                    <span class={{if product.enabled "is-on" "is-off"}}>
                      {{if product.enabled (i18n "discourse_cosmetics_store.admin.product.live") (i18n "discourse_cosmetics_store.admin.product.disabled")}}
                    </span>
                    {{#if product.editor_pick}}
                      <span>{{i18n "discourse_cosmetics_store.admin.product.editor"}}</span>
                    {{/if}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.product.columns.sales"}}</div>
                    {{product.purchase_count}}
                  </td>
                  <td class="d-table__cell --controls">
                    <div class="d-table__cell-actions">
                      <DButton
                        class="btn-default btn-small"
                        @route={{EDIT_ROUTE}}
                        @routeModels={{product.id}}
                        @label="discourse_cosmetics_store.admin.product.edit_action"
                      />
                      <DButton
                        class="btn-transparent --danger btn-small"
                        @action={{fn this.deleteProduct product}}
                        @icon="trash-can"
                        @label="discourse_cosmetics_store.admin.product.delete"
                      />
                    </div>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{else}}
        <AdminConfigAreaEmptyList
          @emptyLabel="discourse_cosmetics_store.admin.product.empty"
          @ctaLabel="discourse_cosmetics_store.admin.product.add"
          @ctaRoute={{NEW_ROUTE}}
        />
      {{/if}}
    </section>
  </template>
}
