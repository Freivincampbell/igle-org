require "rails_helper"

RSpec.describe Permissions::PermissionChecker do
  describe ".allow?" do
    it "requires an active membership in the current church" do
      church = create(:church)
      membership = create(:church_membership, :inactive, church:)
      context = Permissions::UserContext.new(user: membership.user, current_church: church, church_membership: membership)

      expect(described_class.allow?(user_context: context, module_key: "roles", action: "read")).to be(false)
    end

    it "grants admin bootstrap permissions to church owners" do
      membership = create(:church_membership, :owner)
      context = Permissions::UserContext.new(user: membership.user, current_church: membership.church, church_membership: membership)

      expect(described_class.allow?(user_context: context, module_key: "roles", action: "deactivate")).to be(true)
    end

    it "does not grant pastoral notes through owner bootstrap" do
      membership = create(:church_membership, :owner)
      context = Permissions::UserContext.new(user: membership.user, current_church: membership.church, church_membership: membership)

      expect(described_class.allow?(user_context: context, module_key: "pastoral_notes", action: "read")).to be(false)
    end

    it "grants explicit role permissions inside the current church" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      permission = create(:permission, module_key: "roles", action_key: "create", name: "Roles - Crear/editar")

      create(:membership_role, church_membership: membership, role:)
      create(:role_permission, role:, permission:)

      context = Permissions::UserContext.new(user: membership.user, current_church: church, church_membership: membership)

      expect(described_class.allow?(user_context: context, module_key: "roles", action: "update")).to be(true)
      expect(described_class.allow?(user_context: context, module_key: "roles", action: "create")).to be(true)
      expect(described_class.allow?(user_context: context, module_key: "roles", action: "read")).to be(true)
      expect(described_class.allow?(user_context: context, module_key: "roles", action: "export")).to be(false)
    end

    it "keeps read-only permissions from creating or administering" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      permission = create(:permission, module_key: "members", action_key: "read", name: "Miembros - Leer")

      create(:membership_role, church_membership: membership, role:)
      create(:role_permission, role:, permission:)

      context = Permissions::UserContext.new(user: membership.user, current_church: church, church_membership: membership)

      expect(described_class.allow?(user_context: context, module_key: "members", action: "read")).to be(true)
      expect(described_class.allow?(user_context: context, module_key: "members", action: "create")).to be(false)
      expect(described_class.allow?(user_context: context, module_key: "members", action: "deactivate")).to be(false)
    end
  end

  describe "alcances" do
    def context_for(membership)
      Permissions::UserContext.new(user: membership.user, current_church: membership.church, church_membership: membership)
    end

    def grant(role:, module_key:, action:, scope:)
      perm = Permission.find_by(module_key:, action_key: action) ||
             create(:permission, module_key:, action_key: action, name: "#{module_key} #{action}")
      create(:role_permission, role:, permission: perm, scope:)
    end

    it "scope_for devuelve el alcance configurado" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      grant(role:, module_key: "members", action: "read", scope: "assigned_ministry")

      result = described_class.scope_for(user_context: context_for(membership), module_key: "members", action: "read")

      expect(result).to eq(:assigned_ministry)
    end

    it "devuelve el alcance más amplio entre roles (church gana)" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role_a = create(:role, church:)
      role_b = create(:role, church:)
      create(:membership_role, church_membership: membership, role: role_a)
      create(:membership_role, church_membership: membership, role: role_b)
      grant(role: role_a, module_key: "members", action: "read", scope: "own")
      grant(role: role_b, module_key: "members", action: "read", scope: "church")

      result = described_class.scope_for(user_context: context_for(membership), module_key: "members", action: "read")

      expect(result).to eq(:church)
    end

    it "filter por own devuelve solo el member del usuario" do
      church = create(:church)
      membership = create(:church_membership, church:)
      own_member = create(:member, church:, user: membership.user)
      _other = create(:member, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      grant(role:, module_key: "members", action: "read", scope: "own")

      relation = described_class.filter(user_context: context_for(membership), module_key: "members", action: "read", relation: church.members)

      expect(relation).to contain_exactly(own_member)
    end

    it "filter por assigned_ministry devuelve solo miembros de ministerios liderados" do
      church = create(:church)
      membership = create(:church_membership, church:)
      leader_member = create(:member, church:, user: membership.user)
      led = create(:ministry, church:)
      create(:ministry_membership, ministry: led, member: leader_member, ministry_role: "leader", status: "active")
      teammate = create(:member, church:)
      create(:ministry_membership, ministry: led, member: teammate, ministry_role: "member", status: "active")
      outsider = create(:member, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      grant(role:, module_key: "members", action: "read", scope: "assigned_ministry")

      relation = described_class.filter(user_context: context_for(membership), module_key: "members", action: "read", relation: church.members)

      expect(relation).to include(teammate)
      expect(relation).not_to include(outsider)
    end

    it "allow? con record fuera del alcance own devuelve false" do
      church = create(:church)
      membership = create(:church_membership, church:)
      create(:member, church:, user: membership.user)
      other = create(:member, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      grant(role:, module_key: "members", action: "read", scope: "own")

      allowed = described_class.allow?(user_context: context_for(membership), module_key: "members", action: "read", record: other)

      expect(allowed).to be(false)
    end

    it "owner siempre tiene alcance church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      result = described_class.scope_for(user_context: context_for(membership), module_key: "members", action: "read")

      expect(result).to eq(:church)
    end
  end
end
