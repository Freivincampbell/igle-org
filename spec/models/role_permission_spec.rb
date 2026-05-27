require "rails_helper"

RSpec.describe RolePermission do
  it "does not allow pastoral notes on non-pastoral roles" do
    role = create(:role)
    permission = create(:permission, module_key: "pastoral_notes", action_key: "read", name: "Notas pastorales - Leer")
    role_permission = build(:role_permission, role:, permission:)

    expect(role_permission).not_to be_valid
    expect(role_permission.errors[:permission]).to include("requires a pastoral role")
  end

  it "allows pastoral notes on pastoral roles" do
    role = create(:role, :pastoral)
    permission = create(:permission, module_key: "pastoral_notes", action_key: "read", name: "Notas pastorales - Leer")
    role_permission = build(:role_permission, role:, permission:)

    expect(role_permission).to be_valid
  end
end
