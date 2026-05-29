require "rails_helper"

RSpec.describe "Church admin reports" do
  def member_with_reports(church, action_key)
    membership = create(:church_membership, church:)
    role = create(:role, church:)
    perm = Permission.find_by(module_key: "reports", action_key:) ||
           create(:permission, module_key: "reports", action_key:, name: "Reportes - #{action_key}")
    create(:role_permission, role:, permission: perm)
    create(:membership_role, church_membership: membership, role:)
    membership
  end

  describe "access control" do
    it "requiere autenticación" do
      church = create(:church)
      get church_admin_reports_path(church)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET index" do
    it "muestra el índice con permiso reports/read" do
      church = create(:church)
      membership = member_with_reports(church, "read")
      sign_in membership.user

      get church_admin_reports_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Reportes")
    end
  end

  describe "GET show (HTML)" do
    it "renderiza un reporte con datos de la iglesia actual" do
      church = create(:church)
      membership = member_with_reports(church, "read")
      member = create(:member, church:, first_name: "Visible")
      sign_in membership.user

      get church_admin_report_path(church, "members")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member.full_name)
    end

    it "404 para un reporte inexistente" do
      church = create(:church)
      membership = member_with_reports(church, "read")
      sign_in membership.user

      get church_admin_report_path(church, "no_existe")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET show (CSV)" do
    it "permite exportar con reports/manage" do
      church = create(:church)
      membership = member_with_reports(church, "manage")
      create(:member, church:, first_name: "Exportable")
      sign_in membership.user

      get church_admin_report_path(church, "members", format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      expect(response.body).to include("Nombre completo")
    end

    it "deniega exportar con solo reports/read" do
      church = create(:church)
      membership = member_with_reports(church, "read")
      sign_in membership.user

      get church_admin_report_path(church, "members", format: :csv)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET show (XLSX)" do
    it "permite exportar xlsx con reports/manage" do
      church = create(:church)
      membership = member_with_reports(church, "manage")
      create(:member, church:)
      sign_in membership.user

      get church_admin_report_path(church, "members", format: :xlsx)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("spreadsheetml")
    end
  end

  describe "auditoría de exportación" do
    it "registra una versión de exportación" do
      church = create(:church)
      membership = member_with_reports(church, "manage")
      create(:member, church:)
      sign_in membership.user

      expect {
        get church_admin_report_path(church, "members", format: :csv)
      }.to change { PaperTrail::Version.where(item_type: "Report", event: "export").count }.by(1)
    end
  end
end
