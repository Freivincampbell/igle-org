require "rails_helper"

RSpec.describe RolePolicy do
  describe "#update?" do
    it "allows an owner inside the current church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      role = create(:role, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, role).update?).to be(true)
      end
    end

    it "denies a role from another church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      other_role = create(:role)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, other_role).update?).to be(false)
      end
    end

    it "allows users with explicit role permission" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      manageable_role = create(:role, church:)
      permission = create(:permission, module_key: "roles", action_key: "update", name: "Roles - Editar")

      create(:membership_role, church_membership: membership, role:)
      create(:role_permission, role:, permission:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, manageable_role).update?).to be(true)
      end
    end
  end

  describe "scope" do
    it "only returns roles for the current church" do
      church = create(:church)
      visible_role = create(:role, church:)
      create(:role)
      membership = create(:church_membership, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Role).resolve

        expect(resolved).to contain_exactly(visible_role)
      end
    end
  end
end
