# frozen_string_literal: true

require_relative "../../../lib/discourse_cosmetics_store/base_contract"

RSpec.describe DiscourseCosmeticsStore::BaseContract do
  def fake_integration(manifest: :absent, methods: [])
    Class.new do
      methods.each do |method_name|
        define_singleton_method(method_name) { true }
      end

      unless manifest == :absent
        define_singleton_method(:contract_manifest) { manifest }
      end
    end
  end

  before do
    allow(described_class).to receive(:ensure_manifest_loaded!)
  end

  it "prefers a supported v1 manifest over legacy probing" do
    integration =
      fake_integration(
        manifest: {
          version: 1,
          capabilities: {
            ownership: true,
            entitlements: true,
            grants: true,
            selections: true,
            loadouts: false,
          },
        },
      )
    allow(described_class).to receive(:integration).and_return(integration)

    expect(described_class.mode).to eq(:manifest)
    expect(described_class.version).to eq(1)
    expect(described_class.core_ready?).to eq(true)
    expect(described_class.capability?(:selections)).to eq(true)
    expect(described_class.capability?(:loadouts)).to eq(false)
  end

  it "rejects capabilities from an unsupported manifest version" do
    integration =
      fake_integration(
        manifest: {
          version: 2,
          capabilities: {
            ownership: true,
            entitlements: true,
            grants: true,
            selections: true,
          },
        },
      )
    allow(described_class).to receive(:integration).and_return(integration)

    expect(described_class.mode).to eq(:unsupported)
    expect(described_class.supported_version?).to eq(false)
    expect(described_class.core_ready?).to eq(false)
    expect(described_class.capability?(:selections)).to eq(false)
  end

  it "fails closed when a manifest exists but is malformed" do
    integration =
      fake_integration(
        manifest: { version: 1, capabilities: "invalid" },
        methods: %i[current_selections_for apply_selections!],
      )
    allow(described_class).to receive(:integration).and_return(integration)

    expect(described_class.mode).to eq(:manifest)
    expect(described_class.supported_version?).to eq(true)
    expect(described_class.capability?(:selections)).to eq(false)
  end

  it "keeps legacy method probes working when the Base manifest is absent" do
    integration =
      fake_integration(
        methods: %i[
          current_selections_for
          apply_selections!
          loadouts_supported?
          loadouts_for
          create_loadout!
          rename_loadout!
          delete_loadout!
          apply_loadout!
        ],
      )
    allow(described_class).to receive(:integration).and_return(integration)

    expect(described_class.mode).to eq(:legacy)
    expect(described_class.capability?(:selections)).to eq(true)
    expect(described_class.capability?(:loadouts)).to eq(true)
    expect(described_class.capability?(:showcase)).to eq(false)
  end
end
