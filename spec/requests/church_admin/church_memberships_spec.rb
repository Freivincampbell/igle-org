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

    it "hides the new user action without create permission" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      permission = create(:permission, module_key: "church_memberships", action_key: "read")
      create(:role_permission, role:, permission:)
      create(:membership_role, church_membership: membership, role:)

      sign_in membership.user

      get church_admin_memberships_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Nuevo usuario")
      expect(response.body).not_to include("Editar")
      expect(response.body).not_to include("Activar")
      expect(response.body).not_to include("Desactivar")
    end
  end

  describe "GET /churches/:church_public_id/admin/memberships/new" do
    it "renders the user creation form for church owners" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      role = create(:role, church:, name: "Servidor")

      sign_in owner_membership.user

      get new_church_admin_membership_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nuevo usuario")
      expect(response.body).to include(role.name)
    end

    it "rejects users without create permission" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      permission = create(:permission, module_key: "church_memberships", action_key: "read")
      create(:role_permission, role:, permission:)
      create(:membership_role, church_membership: membership, role:)

      sign_in membership.user

      get new_church_admin_membership_path(church)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /churches/:church_public_id/admin/memberships" do
    it "creates a non-owner church user with selected roles" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      role = create(:role, church:, name: "Lider")

      sign_in owner_membership.user

      expect do
        post church_admin_memberships_path(church), params: {
          church_admin_user_registration: {
            email: "nuevo@example.test",
            first_name: "Nuevo",
            last_name: "Usuario",
            initial_access: "password123",
            initial_access_confirmation: "password123",
            role_public_ids: [ role.public_id ]
          }
        }
      end.to change(User, :count).by(1)
        .and change(ChurchMembership, :count).by(1)
        .and change(MembershipRole, :count).by(1)

      created_user = User.find_by!(email: "nuevo@example.test")
      membership = ChurchMembership.find_by!(church:, user: created_user)

      expect(response).to redirect_to(church_admin_memberships_path(church))
      expect(membership).not_to be_owner
      expect(membership.roles).to contain_exactly(role)
    end

    it "renders validation errors when the user is already in the church" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      existing_membership = create(:church_membership, church:)

      sign_in owner_membership.user

      post church_admin_memberships_path(church), params: {
        church_admin_user_registration: {
          email: existing_membership.user.email,
          initial_access: "",
          initial_access_confirmation: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("No se pudo crear el usuario.")
    end
  end

  describe "PATCH /churches/:church_public_id/admin/memberships/:public_id" do
    it "updates user details, password, and roles" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      target_membership = create(:church_membership, church:)
      role = create(:role, church:, name: "Lider")

      sign_in owner_membership.user

      patch church_admin_membership_path(church, target_membership), params: {
        church_membership: {
          user: {
            email: "updated@example.test",
            first_name: "Updated",
            last_name: "User",
            access_code: "new-password-123",
            access_code_confirmation: "new-password-123"
          },
          role_public_ids: [ role.public_id ]
        }
      }

      expect(response).to redirect_to(church_admin_memberships_path(church))
      expect(target_membership.user.reload.email).to eq("updated@example.test")
      expect(target_membership.user.first_name).to eq("Updated")
      expect(target_membership.user.valid_password?("new-password-123")).to be(true)
      expect(target_membership.roles.reload).to contain_exactly(role)
    end

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

  describe "PATCH /churches/:church_public_id/admin/memberships/:public_id/activate" do
    it "activates a church membership" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      target_membership = create(:church_membership, :inactive, church:)

      sign_in owner_membership.user

      patch activate_church_admin_membership_path(church, target_membership)

      expect(response).to redirect_to(church_admin_memberships_path(church))
      expect(target_membership.reload).to be_active
    end
  end

  describe "PATCH /churches/:church_public_id/admin/memberships/:public_id/deactivate" do
    it "deactivates a church membership" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      target_membership = create(:church_membership, church:)

      sign_in owner_membership.user

      patch deactivate_church_admin_membership_path(church, target_membership)

      expect(response).to redirect_to(church_admin_memberships_path(church))
      expect(target_membership.reload).to be_inactive
    end

    it "does not deactivate the last active owner" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)

      sign_in owner_membership.user

      patch deactivate_church_admin_membership_path(church, owner_membership)

      expect(response).to redirect_to(church_admin_memberships_path(church))
      expect(owner_membership.reload).to be_active
    end
  end
end
