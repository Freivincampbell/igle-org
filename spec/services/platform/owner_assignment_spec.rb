require "rails_helper"

RSpec.describe Platform::OwnerAssignment do
  describe "#save" do
    it "creates a user and owner membership" do
      church = create(:church)
      assignment = described_class.new(
        church:,
        email: "owner@example.test",
        first_name: "Owner",
        last_name: "User",
        password: "password123",
        password_confirmation: "password123"
      )

      expect { assignment.save }.to change(User, :count).by(1)
        .and change(ChurchMembership, :count).by(1)

      membership = ChurchMembership.find_by!(church:, user: assignment.user)

      expect(membership).to be_owner
      expect(membership).to be_active
      expect(assignment.user).to be_user
    end

    it "reuses an existing user without requiring a password" do
      church = create(:church)
      user = create(:user, email: "existing@example.test")
      assignment = described_class.new(church:, email: "existing@example.test")

      expect { assignment.save }.to change(User, :count).by(0)
        .and change(ChurchMembership, :count).by(1)

      expect(assignment.user).to eq(user)
      expect(assignment.membership).to be_owner
    end

    it "requires a password for new users" do
      assignment = described_class.new(church: create(:church), email: "new@example.test")

      expect(assignment.save).to be(false)
      expect(assignment.errors[:password]).to include("no puede estar en blanco")
    end
  end
end
