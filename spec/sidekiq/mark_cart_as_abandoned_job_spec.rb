require "rails_helper"

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe "#perform" do
    let!(:recent_cart) { Cart.create!(last_interaction_at: 2.hours.ago, abandoned_at: nil) }
    let!(:old_cart)    { Cart.create!(last_interaction_at: 5.hours.ago, abandoned_at: nil) }
    let!(:abandoned_recently) { Cart.create!(abandoned_at: 3.days.ago, last_interaction_at: 5.days.ago) }
    let!(:abandoned_old)      { Cart.create!(abandoned_at: 8.days.ago, last_interaction_at: 10.days.ago) }

    it "marks carts inactive for more than 3 hours as abandoned" do
      expect {
        described_class.new.perform
      }.to change { old_cart.reload.abandoned_at }.from(nil)
    end

    it "does not mark carts active within 3 hours as abandoned" do
      described_class.new.perform
      expect(recent_cart.reload.abandoned_at).to be_nil
    end

    it "destroys carts abandoned more than 7 days ago" do
      expect {
        described_class.new.perform
      }.to change { Cart.exists?(abandoned_old.id) }.from(true).to(false)
    end

    it "does not destroy carts abandoned less than 7 days ago" do
      described_class.new.perform
      expect(Cart.exists?(abandoned_recently.id)).to be(true)
    end
  end
end
