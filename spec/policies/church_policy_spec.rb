require "rails_helper"

RSpec.describe ChurchPolicy do
  describe "#show?" do
    it "allows active church members" do
      church = create(:church)
      membership = create(:church_membership, church:)

      policy = described_class.new(membership.user, church)

      expect(policy.show?).to be(true)
    end

    it "denies users from another church" do
      church = create(:church)
      other_membership = create(:church_membership)

      policy = described_class.new(other_membership.user, church)

      expect(policy.show?).to be(false)
    end

    it "allows super admins" do
      super_admin = create(:user, :super_admin)
      church = create(:church)

      policy = described_class.new(super_admin, church)

      expect(policy.show?).to be(true)
    end
  end

  describe "scope" do
    it "only returns churches where the user has active membership" do
      visible_church = create(:church)
      hidden_church = create(:church)
      membership = create(:church_membership, church: visible_church)
      create(:church_membership, :inactive, user: membership.user, church: hidden_church)

      resolved = described_class::Scope.new(membership.user, Church).resolve

      expect(resolved).to contain_exactly(visible_church)
    end
  end
end
