# frozen_string_literal: true

require_relative "../../../lib/discourse_cosmetics_store/base_contract"

module ::DiscourseCosmeticsStore
  class PreviewController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    before_action :ensure_store_enabled
    before_action :ensure_logged_in
    before_action :ensure_preview_supported

    def index
      no_store!

      items = preview_items
      owned_item_ids = CosmeticsAccess.owned_item_ids(user: current_user, items: items)
      entitled_item_ids = CosmeticsAccess.entitled_item_ids(user: current_user, items: items)

      render json: {
               items:
                 items
                   .select { |item| entitled_item_ids.key?(item.id) }
                   .map do |item|
                     serialize_item(item, directly_owned: owned_item_ids.key?(item.id))
                   end,
               selections: integration.current_selections_for(user: current_user),
               viewer: {
                 logged_in: true,
                 username: current_user.username,
                 avatar_template: current_user.avatar_template,
               },
             }
    end

    def apply
      no_store!
      selections =
        params
          .require(:selections)
          .permit(*DiscourseUserCosmetics::Item::KINDS)
          .to_h

      render json: integration.apply_selections!(user: current_user, selections: selections)
    rescue ActionController::ParameterMissing, Discourse::InvalidParameters
      render_error(I18n.t("discourse_cosmetics_store.errors.invalid_preview_selection"))
    rescue Discourse::InvalidAccess, Discourse::NotFound
      render_error(I18n.t("discourse_cosmetics_store.errors.preview_unavailable"))
    end

    private

    def integration
      ::DiscourseUserCosmetics::Integration
    end

    def ensure_store_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_cosmetics_store_enabled
    end

    def ensure_preview_supported
      available = BaseContract.core_ready? && BaseContract.capability?(:selections)
      raise Discourse::NotFound unless available
    end

    def preview_items
      DiscourseUserCosmetics::Item.enabled
        .ordered
        .includes(:image_upload, effect_layers: :image_upload)
        .to_a
    end

    def serialize_item(item, directly_owned:)
      DiscourseUserCosmetics::Presenter.serialize_item(item).merge(
        kind: item.kind,
        rarity_label: item.rarity_label,
        rarity_color: item.rarity_color,
        directly_owned: directly_owned,
      )
    end

    def no_store!
      response.headers["Cache-Control"] = "private, no-store"
    end

    def render_error(message)
      render json: { errors: [message] }, status: :unprocessable_entity
    end
  end
end
