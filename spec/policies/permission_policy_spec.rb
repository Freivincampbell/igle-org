require "rails_helper"

RSpec.describe PermissionPolicy do
  describe "scope" do
    it "returns only permissions attached to roles in the current church" do
      church = create(:church)
      role = create(:role, church:)
      membership = create(:church_membership, church:)
      visible_permission = create(:permission, module_key: "roles", action_key: "read", name: "Roles - Leer")
      create(:role_permission, role:, permission: visible_permission)
      create(:permission, module_key: "events", action_key: "read", name: "Eventos - Leer")

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Permission).resolve

        expect(resolved).to contain_exactly(visible_permission)
      end
    end
  end
end
