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

  describe "scope" do
    it "por defecto es church" do
      rp = create(:role_permission)
      expect(rp.scope).to eq("church")
    end

    it "acepta own y assigned_ministry" do
      expect(build(:role_permission, scope: "own")).to be_valid
      expect(build(:role_permission, scope: "assigned_ministry")).to be_valid
    end

    it "rechaza un scope inválido" do
      rp = build(:role_permission, scope: "galaxy")
      expect(rp).not_to be_valid
      expect(rp.errors[:scope]).to be_present
    end
  end
end
