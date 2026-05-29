require "rails_helper"

RSpec.describe "Church admin roles" do
  def permission_for(module_key, action_key)
    create(:permission, module_key:, action_key:, name: "#{module_key} #{action_key}")
  end

  describe "access control" do
    it "requires authentication" do
      church = create(:church)

      get church_admin_roles_path(church)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_roles_path(church)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("authorization.not_authorized"))
    end
  end

  describe "GET /churches/:church_public_id/admin/roles" do
    it "lists roles for the current church only" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      visible_role = create(:role, church:, name: "Servidor")
      create(:role, name: "Rol Oculto")

      sign_in membership.user

      get church_admin_roles_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible_role.name)
      expect(response.body).not_to include("Rol Oculto")
    end
  end

  describe "POST /churches/:church_public_id/admin/roles" do
    it "creates a role without default permissions" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      expect do
        post church_admin_roles_path(church), params: {
          role: {
            name: "Tesoreria",
            description: "Acceso administrativo financiero",
            pastoral: "0",
            status: "active"
          }
        }
      end.to change(Role, :count).by(1)

      role = church.roles.find_by!(name: "Tesoreria")

      expect(response).to redirect_to(church_admin_role_path(church, role))
      expect(role.permissions).to be_empty
    end
  end

  describe "PATCH /churches/:church_public_id/admin/roles/:public_id/permissions" do
    it "shows only the active three-permission matrix for implemented modules" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      role = create(:role, church:)
      permission_for("roles", "read")
      permission_for("roles", "create")
      permission_for("roles", "manage")
      permission_for("pastoral_notes", "read")

      sign_in membership.user

      get edit_church_admin_role_path(church, role)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Solo lectura")
      expect(response.body).to include("Crear/editar")
      expect(response.body).to include("Administrar")
      expect(response.body).to include("Roles")
      expect(response.body).not_to include("Notas pastorales")
    end

    it "updates the role permission matrix" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      role = create(:role, church:)
      read_permission = permission_for("roles", "read")
      create_permission = permission_for("roles", "create")

      sign_in membership.user

      patch permissions_church_admin_role_path(church, role), params: {
        role: {
          permission_public_ids: [ read_permission.public_id, create_permission.public_id ]
        }
      }

      expect(response).to redirect_to(church_admin_role_path(church, role))
      expect(role.permissions.reload).to contain_exactly(read_permission, create_permission)
    end

    it "rejects permissions outside the active church admin matrix" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      role = create(:role, church:)
      # module_key fuera de ASSIGNABLE_MODULE_KEYS: se salta la validación de
      # inclusión para simular un permiso no asignable desde la matriz.
      permission = build(:permission, module_key: "non_assignable_module", action_key: "read", name: "No asignable")
      permission.save!(validate: false)

      sign_in membership.user

      patch permissions_church_admin_role_path(church, role), params: {
        role: {
          permission_public_ids: [ permission.public_id ]
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(role.permissions.reload).to be_empty
    end
  end

  describe "public id routing" do
    it "does not resolve role database ids" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      role = create(:role, church:)

      sign_in membership.user

      get "/churches/#{church.public_id}/admin/roles/#{role.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
