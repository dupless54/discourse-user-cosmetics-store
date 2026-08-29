# frozen_string_literal: true

require_relative "base_contract"

module ::DiscourseCosmeticsStore
  class HealthCheck
    def self.call
      new.call
    end

    def call
      checks = [
        store_enabled_check,
        base_plugin_check,
        integration_check,
        integration_contract_check,
        preview_contract_check,
        loadout_contract_check,
        catalog_empty_products_check,
        catalog_disabled_items_check,
        catalog_availability_check,
        payment_providers_check,
      ]

      {
        status: overall_status(checks),
        checked_at: Time.zone.now.iso8601,
        checks: checks,
      }
    end

    private

    def store_enabled_check
      enabled = SiteSetting.discourse_cosmetics_store_enabled
      check("store_enabled", enabled ? "ok" : "warning", enabled ? 1 : 0)
    end

    def base_plugin_check
      ready = base_ready?
      check("base_plugin", ready ? "ok" : "critical", ready ? 1 : 0)
    end

    def integration_check
      ready = integration_ready?
      check("integration", ready ? "ok" : "critical", ready ? 1 : 0)
    end

    def integration_contract_check
      return check("integration_contract", "critical", 0, mode: "missing") unless base_ready?

      diagnostics = BaseContract.diagnostics
      mode = diagnostics[:mode]
      status =
        case mode
        when :manifest
          "ok"
        when :legacy
          "warning"
        else
          "critical"
        end

      check(
        "integration_contract",
        status,
        diagnostics[:version] || 0,
        mode: mode.to_s,
        supported_versions: diagnostics[:supported_versions],
      )
    end

    def preview_contract_check
      ready = integration_ready? && BaseContract.capability?(:selections)
      check("preview_contract", ready ? "ok" : "warning", ready ? 1 : 0)
    end

    def loadout_contract_check
      ready = integration_ready? && BaseContract.capability?(:loadouts)
      check("loadout_contract", ready ? "ok" : "warning", ready ? 1 : 0)
    rescue StandardError
      check("loadout_contract", "warning", 0)
    end

    def catalog_empty_products_check
      count =
        Product
          .where(enabled: true)
          .left_joins(:product_items)
          .group(:id)
          .having("COUNT(discourse_cosmetics_store_product_items.id) = 0")
          .count
          .length
      check("empty_products", count.zero? ? "ok" : "warning", count)
    end

    def catalog_disabled_items_check
      return check("disabled_cosmetic_items", "critical", 0) unless base_ready?

      count =
        Product
          .where(enabled: true)
          .joins(product_items: :cosmetic_item)
          .where(discourse_user_cosmetics_items: { enabled: false })
          .distinct
          .count
      check("disabled_cosmetic_items", count.zero? ? "ok" : "warning", count)
    end

    def catalog_availability_check
      count =
        Product
          .where.not(available_from: nil, available_until: nil)
          .where("available_from >= available_until")
          .count
      check("invalid_availability", count.zero? ? "ok" : "warning", count)
    end

    def payment_providers_check
      statuses = PaymentProviders.configuration_status
      configured = statuses.count { |provider| provider[:enabled] }
      payments_enabled = SiteSetting.discourse_cosmetics_store_payments_enabled
      status = payments_enabled && configured.zero? ? "warning" : "ok"

      check(
        "payment_providers",
        status,
        configured,
        total: statuses.length,
        payments_enabled: payments_enabled,
      )
    end

    def base_ready?
      @base_ready ||=
        DiscourseCosmeticsStore.load_base_plugin! && DiscourseCosmeticsStore.base_plugin_ready?
    end

    def integration_ready?
      @integration_ready ||= base_ready? && BaseContract.core_ready?
    end

    def overall_status(checks)
      return "critical" if checks.any? { |item| item[:status] == "critical" }
      return "warning" if checks.any? { |item| item[:status] == "warning" }

      "healthy"
    end

    def check(id, status, value, **metadata)
      { id: id, status: status, value: value }.merge(metadata)
    end
  end
end
