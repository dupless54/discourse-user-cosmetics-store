# frozen_string_literal: true

RSpec.describe DiscourseCosmeticsStore::GiftNotification do
  fab!(:sender, :user)
  fab!(:recipient, :user)

  let!(:product) do
    DiscourseCosmeticsStore::Product.create!(
      name: "Gift notification frame",
      product_type: "item",
      price: 250,
      enabled: true,
      exclusive: true,
    )
  end

  let!(:gift) do
    DiscourseCosmeticsStore::Gift.create!(
      sender: sender,
      recipient: recipient,
      product: product,
      price_paid: product.price,
      status: "completed",
      idempotency_key: "gift-notification:#{sender.id}:#{recipient.id}:#{product.id}",
    )
  end

  before do
    enable_current_plugin
    expect(DiscourseCosmeticsStore.install_notification_type!).to eq(true)
  end

  it "creates one native unread notification with safe presentation data" do
    notification =
      described_class.deliver(gift: gift, sender: sender, recipient: recipient, product: product)

    expect(notification).to be_persisted
    expect(notification.user_id).to eq(recipient.id)
    expect(notification.notification_type).to eq(DiscourseCosmeticsStore::GIFT_NOTIFICATION_TYPE)
    expect(notification.read).to eq(false)
    expect(notification.topic_id).to be_nil
    expect(notification.data_hash).to include(
      "gift_id" => gift.id,
      "display_username" => sender.username,
      "product_name" => product.name,
    )
  end

  it "is idempotent when delivery is retried for the same committed gift" do
    2.times do
      described_class.deliver(gift: gift, sender: sender, recipient: recipient, product: product)
    end

    expect(
      Notification.where(
        user_id: recipient.id,
        notification_type: DiscourseCosmeticsStore::GIFT_NOTIFICATION_TYPE,
      ).count,
    ).to eq(1)
  end

  it "never raises when notification persistence fails after the gift committed" do
    allow(Notification).to receive(:find_or_initialize_by).and_raise(StandardError, "notification unavailable")

    expect do
      result = described_class.deliver(gift: gift, sender: sender, recipient: recipient, product: product)
      expect(result).to be_nil
    end.not_to raise_error

    expect(gift.reload.status).to eq("completed")
  end
end
