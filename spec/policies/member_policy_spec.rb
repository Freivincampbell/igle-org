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
    def grant(membership, scope:)
      role = create(:role, church: membership.church)
      create(:membership_role, church_membership: membership, role:)
      perm = Permission.find_by(module_key: "members", action_key: "read") ||
             create(:permission, module_key: "members", action_key: "read", name: "Miembros leer")
      create(:role_permission, role:, permission: perm, scope:)
    end

    it "con permiso de alcance church devuelve solo miembros de la iglesia actual" do
      church = create(:church)
      visible_member = create(:member, church:)
      create(:member)
      membership = create(:church_membership, church:)
      grant(membership, scope: "church")

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Member).resolve

        expect(resolved).to contain_exactly(visible_member)
      end
    end

    it "sin permiso no devuelve miembros" do
      church = create(:church)
      create(:member, church:)
      membership = create(:church_membership, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Member).resolve

        expect(resolved).to be_empty
      end
    end

    it "con alcance own devuelve solo el propio registro" do
      church = create(:church)
      membership = create(:church_membership, church:)
      own = create(:member, church:, user: membership.user)
      create(:member, church:)
      grant(membership, scope: "own")

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Member).resolve

        expect(resolved).to contain_exactly(own)
      end
    end

    it "con alcance assigned_ministry devuelve solo miembros de ministerios liderados" do
      church = create(:church)
      membership = create(:church_membership, church:)
      leader = create(:member, church:, user: membership.user)
      led = create(:ministry, church:)
      create(:ministry_membership, ministry: led, member: leader, ministry_role: "leader", status: "active")
      teammate = create(:member, church:)
      create(:ministry_membership, ministry: led, member: teammate, ministry_role: "member", status: "active")
      outsider = create(:member, church:)
      grant(membership, scope: "assigned_ministry")

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Member).resolve

        expect(resolved).to include(teammate, leader)
        expect(resolved).not_to include(outsider)
      end
    end
  end
end
