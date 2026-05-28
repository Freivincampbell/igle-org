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
end
