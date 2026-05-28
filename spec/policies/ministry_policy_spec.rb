require "rails_helper"

RSpec.describe MinistryPolicy do
  describe "#update?" do
    it "allows an owner inside the current church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ministry = create(:ministry, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, ministry).update?).to be(true)
      end
    end

    it "denies a ministry from another church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      other_ministry = create(:ministry)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, other_ministry).update?).to be(false)
      end
    end

    it "allows users with explicit ministry permission" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      ministry = create(:ministry, church:)
      permission = create(:permission, module_key: "ministries", action_key: "update", name: "Ministerios - Editar")

      create(:membership_role, church_membership: membership, role:)
      create(:role_permission, role:, permission:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, ministry).update?).to be(true)
      end
    end
  end

  describe "scope" do
    it "only returns ministries for the current church" do
      church = create(:church)
      visible_ministry = create(:ministry, church:)
      create(:ministry)
      membership = create(:church_membership, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Ministry).resolve

        expect(resolved).to contain_exactly(visible_ministry)
      end
    end
  end
end
