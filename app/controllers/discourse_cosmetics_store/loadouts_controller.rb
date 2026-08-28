# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class LoadoutsController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    before_action :ensure_store_enabled
    before_action :ensure_logged_in
    before_action :ensure_loadouts_supported

    def index
      no_store!
      render json: payload
    end

    def create
      no_store!
      loadout = integration.create_loadout!(user: current_user, name: params[:name])
      render json: { loadout: loadout }, status: :created
    rescue Discourse::InvalidParameters
      render_error(I18n.t("discourse_cosmetics_store.errors.loadout_limit"), :unprocessable_entity)
    rescue ActiveRecord::RecordInvalid
      render_error(I18n.t("discourse_cosmetics_store.errors.invalid_loadout_name"), :unprocessable_entity)
    end

    def update
      no_store!
      loadout =
        integration.rename_loadout!(
          user: current_user,
          loadout_id: params[:id],
          name: params[:name],
        )
      render json: { loadout: loadout }
    rescue ActiveRecord::RecordInvalid
      render_error(I18n.t("discourse_cosmetics_store.errors.invalid_loadout_name"), :unprocessable_entity)
    end

    def destroy
      no_store!
      integration.delete_loadout!(user: current_user, loadout_id: params[:id])
      render json: { deleted: true }
    end

    def apply
      no_store!
      render json: integration.apply_loadout!(user: current_user, loadout_id: params[:id])
    rescue Discourse::InvalidAccess
      render_error(I18n.t("discourse_cosmetics_store.errors.loadout_unavailable"), :unprocessable_entity)
    end

    private

    def integration
      ::DiscourseUserCosmetics::Integration
    end

    def ensure_store_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_cosmetics_store_enabled
    end

    def ensure_loadouts_supported
      available =
        DiscourseCosmeticsStore.load_base_plugin! &&
          DiscourseCosmeticsStore.base_integration_ready? &&
          integration.respond_to?(:loadouts_supported?) &&
          integration.loadouts_supported?
      raise Discourse::NotFound unless available
    end

    def payload
      {
        loadouts: integration.loadouts_for(user: current_user),
        viewer: {
          logged_in: true,
          username: current_user.username,
        },
      }
    end

    def no_store!
      response.headers["Cache-Control"] = "private, no-store"
    end

    def render_error(message, status)
      render json: { errors: [message] }, status: status
    end
  end
end
