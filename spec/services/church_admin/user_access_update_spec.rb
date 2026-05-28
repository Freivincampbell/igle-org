require "rails_helper"

RSpec.describe ChurchAdmin::UserAccessUpdate do
  describe "#save" do
    it "updates user details, password, and roles" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      update = described_class.new(
        church_membership: membership,
        user_attributes: {
          email: "updated@example.test",
          first_name: "Updated",
          last_name: "User",
          access_code: "new-password-123",
          access_code_confirmation: "new-password-123"
        },
        role_public_ids: [ role.public_id ]
      )

      expect(update.save).to be(true)

      expect(membership.user.reload.email).to eq("updated@example.test")
      expect(membership.user.first_name).to eq("Updated")
      expect(membership.user.valid_password?("new-password-123")).to be(true)
      expect(membership.roles.reload).to contain_exactly(role)
    end

    it "keeps the current password when password fields are blank" do
      membership = create(:church_membership)
      membership.user.update!(password: "current-password-123", password_confirmation: "current-password-123")
      update = described_class.new(
        church_membership: membership,
        user_attributes: {
          email: membership.user.email,
          first_name: "Same",
          access_code: "",
          access_code_confirmation: ""
        },
        role_public_ids: []
      )

      expect(update.save).to be(true)
      expect(membership.user.reload.valid_password?("current-password-123")).to be(true)
    end

    it "rejects roles from another church" do
      membership = create(:church_membership)
      other_role = create(:role)
      update = described_class.new(
        church_membership: membership,
        user_attributes: { email: membership.user.email },
        role_public_ids: [ other_role.public_id ]
      )

      expect(update.save).to be(false)
      expect(update.errors[:base]).to include("no es valido")
    end
  end
end
