import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import DModalCancel from "discourse/ui-kit/d-modal-cancel";
import { i18n } from "discourse-i18n";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";

export default class CosmeticsStorePaymentRefundModal extends Component {
  @tracked busy = false;
  formApi;

  get payment() {
    return this.args.model.payment;
  }

  get subtitle() {
    return i18n("discourse_cosmetics_store.admin.refund.subtitle", {
      username: this.payment.username,
      package_name: this.payment.package_name,
      order_id: this.payment.provider_payment_id,
    });
  }

  @cached
  get formData() {
    return {
      amount: this.payment.remaining_amount,
      refund_reference: "",
      reason: "",
      confirmed: false,
    };
  }

  @action
  registerApi(api) {
    this.formApi = api;
  }

  @action
  submitForm() {
    this.formApi?.submit();
  }

  @action
  async submit(data) {
    if (this.busy || !data.confirmed) {
      return;
    }

    this.busy = true;
    try {
      const response = await ajax(
        `${ADMIN_API_BASE}/payments/${this.payment.token}/refund.json`,
        {
          type: "POST",
          data: {
            amount: data.amount,
            refund_reference: String(data.refund_reference || "").trim(),
            reason: String(data.reason || "").trim(),
          },
        }
      );
      this.args.model.onCompleted?.(response);
      this.args.closeModal(response);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
    }
  }

  <template>
    <DModal
      class="cstore-refund-modal --large"
      @closeModal={{@closeModal}}
      @title={{i18n "discourse_cosmetics_store.admin.refund.title"}}
      @subtitle={{this.subtitle}}
      @dismissable={{if this.busy false true}}
      @submitOnEnter={{false}}
      @inline={{@inline}}
    >
      <:body>
        <div class="cstore-refund-form__warning">
          <strong>{{i18n "discourse_cosmetics_store.admin.refund.warning_title"}}</strong>
          <span>{{i18n "discourse_cosmetics_store.admin.refund.warning_body"}}</span>
        </div>

        <Form
          @data={{this.formData}}
          @onSubmit={{this.submit}}
          @onRegisterApi={{this.registerApi}}
          as |form data|
        >
          <form.Field
            @name="amount"
            @title={{i18n
              "discourse_cosmetics_store.admin.refund.amount"
              currency=this.payment.currency
            }}
            @description={{i18n
              "discourse_cosmetics_store.admin.refund.amount_help"
              amount=this.payment.remaining_amount
              currency=this.payment.currency
            }}
            @validation="required"
            @type="input"
            as |field|
          >
            <field.Control
              type="number"
              min="0.01"
              step="0.01"
              inputmode="decimal"
            />
          </form.Field>

          <form.Field
            @name="refund_reference"
            @title={{i18n "discourse_cosmetics_store.admin.refund.reference"}}
            @description={{i18n "discourse_cosmetics_store.admin.refund.reference_help"}}
            @validation="required"
            @format="large"
            @type="input"
            as |field|
          >
            <field.Control
              maxlength="190"
              placeholder={{i18n "discourse_cosmetics_store.admin.refund.reference_placeholder"}}
            />
          </form.Field>

          <form.Field
            @name="reason"
            @title={{i18n "discourse_cosmetics_store.admin.refund.reason"}}
            @description={{i18n "discourse_cosmetics_store.admin.refund.reason_help"}}
            @format="large"
            @type="input"
            as |field|
          >
            <field.Control maxlength="500" />
          </form.Field>

          <form.Field
            @name="confirmed"
            @title={{i18n
              "discourse_cosmetics_store.admin.refund.confirm"
              amount=data.amount
              currency=this.payment.currency
            }}
            @validation="required"
            @type="checkbox"
            as |field|
          >
            <field.Control />
          </form.Field>
        </Form>
      </:body>
      <:footer>
        <DButton
          class="btn-danger"
          @action={{this.submitForm}}
          @disabled={{this.busy}}
          @label="discourse_cosmetics_store.admin.refund.submit"
        />
        {{#unless this.busy}}
          <DModalCancel @close={{@closeModal}} />
        {{/unless}}
      </:footer>
    </DModal>
  </template>
}
