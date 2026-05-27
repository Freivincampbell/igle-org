require "rails_helper"

RSpec.describe User do
  describe "#active_for_authentication?" do
    it "rejects inactive users" do
      user = build(:user, :inactive)

      expect(user.active_for_authentication?).to be(false)
    end
  end

  describe "#active_membership_for" do
    it "returns the active membership for a church" do
      church = create(:church)
      membership = create(:church_membership, church:)

      expect(membership.user.active_membership_for(church)).to eq(membership)
    end
  end
end
