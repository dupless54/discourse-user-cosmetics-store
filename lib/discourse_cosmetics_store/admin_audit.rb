# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class AdminAudit
    TYPE_PREFIX = "cosmetics_store_"
    MAX_RECENT = 100

    ACTION_TYPES = %w[
      product_created
      product_updated
      product_deleted
      mission_created
      mission_updated
      mission_deleted
      mission_disabled
      wallet_adjusted
      orb_package_created
      orb_package_updated
      orb_package_deleted
      orb_package_disabled
      refund_recorded
    ].to_h { |action| [action.to_sym, "#{TYPE_PREFIX}#{action}"] }.freeze

    SAFE_DETAIL_KEYS = %w[
      entity_id
      entity_name
      entity_type
      changed_fields
      target_user_id
      target_username
      amount
      balance_after
      debt_after
      orb_amount
      price_minor
      currency
      payment_id
      refund_id
      refund_amount_minor
      refunded_orb_amount
    ].freeze

    def self.recent(limit: MAX_RECENT)
      limit = limit.to_i.clamp(1, MAX_RECENT)

      UserHistory
        .where(
          action: UserHistory.actions[:custom_staff],
          custom_type: ACTION_TYPES.values,
        )
        .includes(:acting_user)
        .order(id: :desc)
        .limit(limit)
        .map { |history| serialize(history) }
    end

    def self.log_product!(actor:, action:, product:, changed_fields: [])
      log_entity!(
        actor: actor,
        action: action_key(:product, action),
        entity: product,
        entity_type: "product",
        changed_fields: changed_fields,
        extra: { "entity_name" => product.name, "entity_type" => product.product_type },
      )
    end

    def self.log_mission!(actor:, action:, mission:, changed_fields: [])
      log_entity!(
        actor: actor,
        action: action_key(:mission, action),
        entity: mission,
        entity_type: "mission",
        changed_fields: changed_fields,
        extra: { "entity_name" => mission.name, "entity_type" => mission.metric },
      )
    end

    def self.log_orb_package!(actor:, action:, package:, changed_fields: [])
      log_entity!(
        actor: actor,
        action: action_key(:orb_package, action),
        entity: package,
        entity_type: "orb_package",
        changed_fields: changed_fields,
        extra: {
          "entity_name" => package.name,
          "orb_amount" => package.orb_amount,
          "price_minor" => package.price_minor,
          "currency" => package.currency,
        },
      )
    end

    def self.log_wallet_adjustment!(actor:, user:, amount:, wallet:)
      log!(
        actor: actor,
        action: :wallet_adjusted,
        subject: "user:#{user.id}",
        details: {
          "target_user_id" => user.id,
          "target_username" => user.username,
          "amount" => amount.to_i,
          "balance_after" => wallet.balance.to_i,
          "debt_after" => wallet.debt.to_i,
        },
      )
    end

    def self.log_refund!(actor:, payment:, refund:)
      log!(
        actor: actor,
        action: :refund_recorded,
        subject: "payment:#{payment.id}",
        details: {
          "payment_id" => payment.id,
          "refund_id" => refund.id,
          "refund_amount_minor" => refund.amount_minor.to_i,
          "refunded_orb_amount" => refund.orb_amount.to_i,
          "currency" => refund.currency,
        },
      )
    end

    def self.serialize(history)
      {
        id: history.id,
        action: history.custom_type.to_s.delete_prefix(TYPE_PREFIX),
        subject: history.subject,
        details: parse_safe_details(history.details),
        actor: {
          id: history.acting_user&.id,
          username: history.acting_user&.username,
        },
        created_at: history.created_at&.iso8601,
      }
    end

    def self.action_key(entity, action)
      key = "#{entity}_#{action}".to_sym
      raise ArgumentError, "unsupported audit action" unless ACTION_TYPES.key?(key)

      key
    end
    private_class_method :action_key

    def self.log_entity!(actor:, action:, entity:, entity_type:, changed_fields:, extra: {})
      log!(
        actor: actor,
        action: action,
        subject: "#{entity_type}:#{entity.id}",
        details: {
          "entity_id" => entity.id,
          "changed_fields" => sanitize_changed_fields(changed_fields),
        }.merge(extra),
      )
    end
    private_class_method :log_entity!

    def self.log!(actor:, action:, subject:, details:)
      custom_type = ACTION_TYPES.fetch(action)
      safe_details =
        details
          .stringify_keys
          .slice(*SAFE_DETAIL_KEYS)
          .transform_values { |value| sanitize_value(value) }
          .compact

      StaffActionLogger.new(actor).log_custom(
        custom_type,
        safe_details.merge(
          subject: subject.to_s.first(500),
          context: PLUGIN_NAME,
        ),
      )
    end
    private_class_method :log!

    def self.sanitize_changed_fields(fields)
      Array(fields).map(&:to_s).reject(&:blank?).uniq.sort.join("|").first(2_000)
    end
    private_class_method :sanitize_changed_fields

    def self.sanitize_value(value)
      case value
      when Integer, TrueClass, FalseClass
        value
      else
        value.to_s.first(2_000)
      end
    end
    private_class_method :sanitize_value

    def self.parse_safe_details(details)
      details
        .to_s
        .lines
        .filter_map do |line|
          key, value = line.strip.split(": ", 2)
          next if key.blank? || value.nil? || SAFE_DETAIL_KEYS.exclude?(key)

          [key, value]
        end
        .to_h
    end
    private_class_method :parse_safe_details
  end
end
