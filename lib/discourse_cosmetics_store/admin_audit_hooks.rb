# frozen_string_literal: true

require "json"

module ::DiscourseCosmeticsStore
  module AdminAuditHooks
    MUTATION_ACTIONS = %i[
      create_product
      update_product
      destroy_product
      create_mission
      update_mission
      destroy_mission
      adjust_wallet
      create_orb_package
      update_orb_package
      destroy_orb_package
      refund_payment
    ].freeze

    PRODUCT_FIELDS = %w[
      name
      slug
      description
      product_type
      price
      card_image_url
      hero_image_url
      preview_background_url
      collection_name
      collection_slug
      collection_image_url
      rarity_label
      rarity_color
      sort_order
      enabled
      featured
      editor_pick
      exclusive
      available_from
      available_until
      tags
      cosmetic_item_ids
    ].freeze

    MISSION_FIELDS = %w[
      key
      name
      description
      metric
      target
      reward
      icon
      sort_order
      enabled
      available_from
      available_until
    ].freeze

    PACKAGE_FIELDS = %w[
      name
      description
      orb_amount
      price_minor
      currency
      sort_order
      enabled
      featured
      providers
      shopier_product_id
      shopier_checkout_url
    ].freeze

    def self.prepended(base)
      base.around_action :audit_store_admin_mutation, only: MUTATION_ACTIONS
      base.after_action :append_store_admin_audit_log, only: :index
    end

    private

    def audit_store_admin_mutation
      before = store_admin_audit_before_context

      ActiveRecord::Base.transaction do
        yield
        record_store_admin_audit!(before) if response_successful?
      end
    end

    def append_store_admin_audit_log
      return unless response_successful?
      return unless response.media_type == "application/json"

      payload = JSON.parse(response.body)
      payload["audit_log"] = AdminAudit.recent
      self.response_body = JSON.generate(payload)
    end

    def record_store_admin_audit!(before)
      case action_name.to_sym
      when :create_product, :update_product
        product = Product.find(audit_response_id || params[:id])
        AdminAudit.log_product!(
          actor: current_user,
          action: action_name == "create_product" ? :created : :updated,
          product: product,
          changed_fields: audit_param_fields(:product, PRODUCT_FIELDS),
        )
      when :destroy_product
        AdminAudit.log_product!(actor: current_user, action: :deleted, product: before.fetch(:record))
      when :create_mission, :update_mission
        mission = Mission.find(audit_response_id || params[:id])
        AdminAudit.log_mission!(
          actor: current_user,
          action: action_name == "create_mission" ? :created : :updated,
          mission: mission,
          changed_fields: audit_param_fields(:mission, MISSION_FIELDS),
        )
      when :destroy_mission
        AdminAudit.log_mission!(
          actor: current_user,
          action: before.fetch(:disable_instead_of_delete) ? :disabled : :deleted,
          mission: before.fetch(:record),
          changed_fields: before.fetch(:disable_instead_of_delete) ? ["enabled"] : [],
        )
      when :adjust_wallet
        user = before.fetch(:user)
        wallet = Wallet.find_by!(user_id: user.id)
        AdminAudit.log_wallet_adjustment!(
          actor: current_user,
          user: user,
          amount: params[:amount],
          wallet: wallet,
        )
      when :create_orb_package, :update_orb_package
        package = OrbPackage.find(audit_response_id || params[:id])
        AdminAudit.log_orb_package!(
          actor: current_user,
          action: action_name == "create_orb_package" ? :created : :updated,
          package: package,
          changed_fields: audit_param_fields(:orb_package, PACKAGE_FIELDS),
        )
      when :destroy_orb_package
        AdminAudit.log_orb_package!(
          actor: current_user,
          action: before.fetch(:disable_instead_of_delete) ? :disabled : :deleted,
          package: before.fetch(:record),
          changed_fields: before.fetch(:disable_instead_of_delete) ? ["enabled"] : [],
        )
      when :refund_payment
        payment = before.fetch(:payment).reload
        return if payment.refunded_amount_minor.to_i == before.fetch(:refunded_amount_minor)

        refund =
          payment.refunds.find_by(
            provider: payment.provider,
            provider_refund_id: params[:refund_reference].to_s.strip,
          )
        return unless refund

        AdminAudit.log_refund!(actor: current_user, payment: payment, refund: refund)
      end
    end

    def store_admin_audit_before_context
      case action_name.to_sym
      when :destroy_product
        { record: Product.find(params[:id]) }
      when :destroy_mission
        mission = Mission.find(params[:id])
        { record: mission, disable_instead_of_delete: mission.claims.exists? }
      when :adjust_wallet
        { user: audit_user_from_username(params[:username]) }
      when :destroy_orb_package
        package = OrbPackage.find(params[:id])
        { record: package, disable_instead_of_delete: package.payments.exists? }
      when :refund_payment
        payment = Payment.find_by!(token: params[:payment_token], provider: "shopier")
        { payment: payment, refunded_amount_minor: payment.refunded_amount_minor.to_i }
      else
        {}
      end
    end

    def audit_user_from_username(username)
      user = User.find_by(username_lower: username.to_s.strip.downcase)
      raise Discourse::NotFound unless user

      user
    end

    def audit_response_id
      JSON.parse(response.body)["id"]
    rescue JSON::ParserError, TypeError
      nil
    end

    def audit_param_fields(root, allowed)
      raw = params[root]
      return [] unless raw.respond_to?(:keys)

      raw.keys.map(&:to_s) & allowed
    end

    def response_successful?
      response.status.to_i.between?(200, 299)
    end
  end
end
