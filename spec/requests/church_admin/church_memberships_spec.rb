require "rails_helper"

RSpec.describe "Church admin church memberships" do
  describe "GET /churches/:church_public_id/admin/memberships" do
    it "lists memberships for the current church only" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      visible_membership = create(:church_membership, church:)
      hidden_membership = create(:church_membership)

      sign_in owner_membership.user

      get church_admin_memberships_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible_membership.user.email)
      expect(response.body).not_to include(hidden_membership.user.email)
    end

    it "requires access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_memberships_path(church)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /churches/:church_public_id/admin/memberships/:public_id" do
    it "assigns roles to a church membership" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      target_membership = create(:church_membership, church:)
      role = create(:role, church:, name: "Lider")

      sign_in owner_membership.user

      patch church_admin_membership_path(church, target_membership), params: {
        church_membership: {
          role_public_ids: [ role.public_id ]
        }
      }

      expect(response).to redirect_to(church_admin_memberships_path(church))
      expect(target_membership.roles.reload).to contain_exactly(role)
    end

    it "rejects roles from another church" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      target_membership = create(:church_membership, church:)
      other_role = create(:role)

      sign_in owner_membership.user

      patch church_admin_membership_path(church, target_membership), params: {
        church_membership: {
          role_public_ids: [ other_role.public_id ]
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(target_membership.roles.reload).to be_empty
    end
  end
end
