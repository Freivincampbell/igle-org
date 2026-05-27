require "rails_helper"

RSpec.describe Permissions::RoleMatrixAssignment do
  describe "#save" do
    it "replaces permissions using public identifiers" do
      role = create(:role)
      read_permission = create(:permission, module_key: "roles", action_key: "read", name: "Roles - Leer")
      update_permission = create(:permission, module_key: "roles", action_key: "update", name: "Roles - Editar")
      export_permission = create(:permission, module_key: "roles", action_key: "export", name: "Roles - Exportar")

      create(:role_permission, role:, permission: export_permission)

      assignment = described_class.new(
        role:,
        permission_public_ids: [ read_permission.public_id, update_permission.public_id ]
      )

      expect(assignment.save).to be(true)
      expect(role.permissions.reload).to contain_exactly(read_permission, update_permission)
    end

    it "rejects unknown permission identifiers" do
      role = create(:role)
      assignment = described_class.new(role:, permission_public_ids: [ SecureRandom.uuid ])

      expect(assignment.save).to be(false)
      expect(role.permissions.reload).to be_empty
    end

    it "rejects pastoral note permissions for non-pastoral roles" do
      role = create(:role, pastoral: false)
      permission = create(:permission, module_key: "pastoral_notes", action_key: "read", name: "Notas pastorales - Leer")

      assignment = described_class.new(role:, permission_public_ids: [ permission.public_id ])

      expect(assignment.save).to be(false)
      expect(role.permissions.reload).to be_empty
    end
  end
end
