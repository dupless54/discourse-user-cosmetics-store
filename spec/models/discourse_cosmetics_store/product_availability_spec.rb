# frozen_string_literal: true

RSpec.describe DiscourseCosmeticsStore::Product do
  let(:now) { Time.zone.parse("2026-08-29 12:00:00") }

  def product!(**attributes)
    described_class.create!(
      {
        name: "Availability #{SecureRandom.hex(4)}",
        product_type: "item",
        price: 25,
      }.merge(attributes),
    )
  end

  it "classifies standard, limited, and seasonal acquisition windows" do
    standard = product!
    limited = product!(available_until: now + 2.days)
    seasonal = product!(available_from: now - 1.day, available_until: now + 2.days)

    expect(standard.availability_type).to eq("standard")
    expect(limited.availability_type).to eq("limited")
    expect(seasonal.availability_type).to eq("seasonal")
  end

  it "classifies active, upcoming, ended, and disabled sale states" do
    active = product!(available_until: now + 1.day)
    upcoming = product!(available_from: now + 1.hour, available_until: now + 1.day)
    ended = product!(available_from: now - 2.days, available_until: now - 1.hour)
    disabled = product!(enabled: false)

    expect(active.sale_state(at: now)).to eq("active")
    expect(upcoming.sale_state(at: now)).to eq("upcoming")
    expect(ended.sale_state(at: now)).to eq("ended")
    expect(disabled.sale_state(at: now)).to eq("disabled")
  end

  it "keeps upcoming products catalog-visible while excluding expired products" do
    allow(Time.zone).to receive(:now).and_return(now)

    active = product!(available_until: now + 1.day)
    upcoming = product!(available_from: now + 1.hour, available_until: now + 2.days)
    expired = product!(available_until: now - 1.minute)

    visible_ids = described_class.catalog_visible.pluck(:id)

    expect(visible_ids).to include(active.id, upcoming.id)
    expect(visible_ids).not_to include(expired.id)
  end
end
