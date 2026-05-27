require "rails_helper"

RSpec.describe ChurchMembership do
  describe "#has_permission?" do
    it "allows every permission for church owners" do
      membership = create(:church_membership, :owner)

      expect(membership).to have_permission("roles", "deactivate")
    end

    it "does not allow pastoral notes through owner bootstrap" do
      membership = create(:church_membership, :owner)

      expect(membership).not_to have_permission("pastoral_notes", "read")
    end

    it "allows permissions granted through roles" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      permission = create(:permission, module_key: "roles", action_key: "update", name: "Roles - Editar")

      create(:membership_role, church_membership: membership, role:)
      create(:role_permission, role:, permission:)

      expect(membership).to have_permission("roles", "update")
      expect(membership).not_to have_permission("roles", "export")
    end

    it "treats manage permission as full module access" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      permission = create(:permission, module_key: "roles", action_key: "manage", name: "Roles - Administrar")

      create(:membership_role, church_membership: membership, role:)
      create(:role_permission, role:, permission:)

      expect(membership).to have_permission("roles", "deactivate")
    end
  end
end
