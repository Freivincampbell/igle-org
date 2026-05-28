require "rails_helper"

RSpec.describe MemberPolicy do
  describe "#update?" do
    it "allows an owner inside the current church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      member = create(:member, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, member).update?).to be(true)
      end
    end

    it "denies members from another church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      other_member = create(:member)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, other_member).update?).to be(false)
      end
    end

    it "allows users with explicit member permission" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      member = create(:member, church:)
      permission = create(:permission, module_key: "members", action_key: "create", name: "Miembros - Crear/editar")

      create(:membership_role, church_membership: membership, role:)
      create(:role_permission, role:, permission:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, member).update?).to be(true)
      end
    end
  end

  describe "scope" do
    it "only returns members for the current church" do
      church = create(:church)
      visible_member = create(:member, church:)
      create(:member)
      membership = create(:church_membership, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Member).resolve

        expect(resolved).to contain_exactly(visible_member)
      end
    end
  end
end
