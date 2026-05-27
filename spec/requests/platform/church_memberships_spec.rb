require "rails_helper"

RSpec.describe "Platform church memberships" do
  describe "GET /platform/churches/:church_public_id/admins/new" do
    it "requires a super admin" do
      church = create(:church)
      sign_in create(:user)

      get new_platform_church_church_membership_path(church)

      expect(response).to redirect_to(root_path)
    end

    it "renders the owner assignment form for super admins" do
      church = create(:church)
      sign_in create(:user, :super_admin)

      get new_platform_church_church_membership_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Asignar administrador owner")
      expect(response.body).to include(church.name)
    end
  end

  describe "POST /platform/churches/:church_public_id/admins" do
    it "creates the initial owner and lets that user see only assigned churches" do
      church = create(:church, name: "Iglesia Asignada")
      other_church = create(:church, name: "Iglesia Oculta")
      super_admin = create(:user, :super_admin)

      sign_in super_admin

      post platform_church_church_memberships_path(church), params: {
        platform_owner_assignment: {
          email: "owner@example.test",
          first_name: "Owner",
          last_name: "User",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      owner = User.find_by!(email: "owner@example.test")
      membership = ChurchMembership.find_by!(church:, user: owner)

      expect(response).to redirect_to(platform_church_path(church))
      expect(membership).to be_owner
      expect(membership).to be_active

      sign_out super_admin
      sign_in owner

      get churches_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(church.name)
      expect(response.body).not_to include(other_church.name)
    end

    it "reuses existing users" do
      church = create(:church)
      user = create(:user, email: "existing@example.test")

      sign_in create(:user, :super_admin)

      expect do
        post platform_church_church_memberships_path(church), params: {
          platform_owner_assignment: {
            email: "existing@example.test",
            first_name: "Existing",
            last_name: "Owner",
            password: "",
            password_confirmation: ""
          }
        }
      end.to change(User, :count).by(0)
        .and change(ChurchMembership, :count).by(1)

      expect(ChurchMembership.find_by!(church:, user:)).to be_owner
    end
  end
end
