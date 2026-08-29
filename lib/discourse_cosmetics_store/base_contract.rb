# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class BaseContract
    SUPPORTED_VERSIONS = [1].freeze
    CONTRACT_RELATIVE_PATH = "lib/discourse_user_cosmetics/integration_contract.rb"
    LEGACY_CAPABILITY_METHODS = {
      ownership: %i[owned_item_ids owns?],
      entitlements: %i[
        register_entitlement_provider
        unregister_entitlement_provider
        entitled_item_ids
        entitled?
      ],
      grants: %i[grant! revoke!],
      selections: %i[current_selections_for apply_selections!],
      loadouts: %i[
        loadouts_supported?
        loadouts_for
        create_loadout!
        rename_loadout!
        delete_loadout!
        apply_loadout!
      ],
      showcase: %i[showcase_supported? showcase_for update_showcase!],
    }.freeze

    class << self
      def manifest_available?
        ensure_manifest_loaded!
        integration&.respond_to?(:contract_manifest) == true
      end

      def manifest
        return nil unless manifest_available?

        value = integration.contract_manifest
        value.is_a?(Hash) ? value : {}
      rescue StandardError => error
        Rails.logger.warn(
          "[#{DiscourseCosmeticsStore::PLUGIN_NAME}] Base Integration manifest failed: " \
            "#{error.class}: #{error.message}",
        )
        {}
      end

      def version
        value = fetch_key(manifest, :version)
        Integer(value, exception: false)
      end

      def supported_version?
        SUPPORTED_VERSIONS.include?(version)
      end

      def mode
        return :legacy unless manifest_available?
        return :manifest if supported_version?

        :unsupported
      end

      def capability?(capability)
        capability = capability.to_s.strip.to_sym
        return false unless LEGACY_CAPABILITY_METHODS.key?(capability)

        if manifest_available?
          return false unless supported_version?

          capabilities = fetch_key(manifest, :capabilities)
          return false unless capabilities.is_a?(Hash)

          fetch_key(capabilities, capability) == true
        else
          legacy_capability?(capability)
        end
      end

      def core_ready?
        %i[ownership entitlements grants].all? { |capability| capability?(capability) }
      end

      def diagnostics
        {
          mode: mode,
          version: version,
          supported_versions: SUPPORTED_VERSIONS,
          capabilities:
            LEGACY_CAPABILITY_METHODS.keys.index_with { |capability| capability?(capability) },
        }
      end

      private

      def integration
        DiscourseCosmeticsStore.load_base_plugin! unless defined?(::DiscourseUserCosmetics::Integration)
        return unless defined?(::DiscourseUserCosmetics::Integration)

        ::DiscourseUserCosmetics::Integration
      end

      def ensure_manifest_loaded!
        api = integration
        return unless api
        return if api.respond_to?(:contract_manifest)

        path = File.join(DiscourseCosmeticsStore.base_plugin_root, CONTRACT_RELATIVE_PATH)
        require path if File.file?(path)
      rescue StandardError, LoadError => error
        Rails.logger.warn(
          "[#{DiscourseCosmeticsStore::PLUGIN_NAME}] Base Integration manifest could not load: " \
            "#{error.class}: #{error.message}",
        )
      end

      def legacy_capability?(capability)
        api = integration
        return false unless api

        methods = LEGACY_CAPABILITY_METHODS.fetch(capability)
        return false unless methods.all? { |method_name| api.respond_to?(method_name) }

        case capability
        when :loadouts
          api.loadouts_supported? == true
        when :showcase
          api.showcase_supported? == true
        else
          true
        end
      end

      def fetch_key(hash, key)
        return unless hash.is_a?(Hash)

        hash[key] || hash[key.to_s]
      end
    end
  end
end
