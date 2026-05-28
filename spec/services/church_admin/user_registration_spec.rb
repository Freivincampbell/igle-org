require "rails_helper"

RSpec.describe ChurchAdmin::UserRegistration do
  describe "#save" do
    it "creates a non-owner user membership with selected roles" do
      church = create(:church)
      role = create(:role, church:)
      registration = described_class.new(
        church:,
        email: "nuevo@example.test",
        first_name: "Nuevo",
        last_name: "Usuario",
        initial_access: "password123",
        initial_access_confirmation: "password123",
        role_public_ids: [ role.public_id ]
      )

      expect { registration.save }.to change(User, :count).by(1)
        .and change(ChurchMembership, :count).by(1)
        .and change(MembershipRole, :count).by(1)

      expect(registration.user.email).to eq("nuevo@example.test")
      expect(registration.membership).to be_active
      expect(registration.membership).not_to be_owner
      expect(registration.membership.roles.reload).to contain_exactly(role)
    end

    it "reuses an existing user without changing the password" do
      church = create(:church)
      user = create(:user, email: "existing@example.test", password: "old-password-123")
      registration = described_class.new(church:, email: user.email)

      expect { registration.save }.to change(User, :count).by(0)
        .and change(ChurchMembership, :count).by(1)

      expect(registration.user).to eq(user)
      expect(registration.membership).not_to be_owner
      expect(user.reload.valid_password?("old-password-123")).to be(true)
    end

    it "requires a password for new users" do
      registration = described_class.new(church: create(:church), email: "new@example.test")

      expect(registration.save).to be(false)
      expect(registration.errors[:initial_access]).to include("no puede estar en blanco")
    end

    it "does not create a duplicate membership in the same church" do
      membership = create(:church_membership)
      registration = described_class.new(church: membership.church, email: membership.user.email)

      expect(registration.save).to be(false)
      expect(registration.errors[:email]).to include("ya esta en uso")
    end

    it "rejects roles from another church" do
      church = create(:church)
      other_role = create(:role)
      registration = described_class.new(
        church:,
        email: "nuevo@example.test",
        initial_access: "password123",
        initial_access_confirmation: "password123",
        role_public_ids: [ other_role.public_id ]
      )

      expect(registration.save).to be(false)
      expect(registration.errors[:base]).to include("no es valido")
    end
  end
end
