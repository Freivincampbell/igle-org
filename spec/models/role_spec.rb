require "rails_helper"

RSpec.describe Role do
  it "keeps role names unique inside each church" do
    church = create(:church)

    create(:role, church:, name: "Lider")
    duplicate = build(:role, church:, name: "Lider")

    expect(duplicate).not_to be_valid
  end

  it "requires pastoral roles for pastoral note permissions" do
    role = create(:role, :pastoral)
    permission = create(:permission, module_key: "pastoral_notes", action_key: "read", name: "Notas pastorales - Leer")

    create(:role_permission, role:, permission:)

    role.pastoral = false

    expect(role).not_to be_valid
  end
end
