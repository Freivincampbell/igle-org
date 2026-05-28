require "rails_helper"

RSpec.describe "Church admin settings" do
  describe "GET /churches/:church_public_id/admin/settings" do
    it "requires authentication" do
      church = create(:church)

      get church_admin_settings_path(church)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "blocks users without access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_settings_path(church)

      expect(response).to redirect_to(root_path)
    end

    it "renders settings page for owner" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      get church_admin_settings_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Configuracion de iglesia")
    end
  end

  describe "PATCH /churches/:church_public_id/admin/settings" do
    it "updates the church configuration for owner" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      patch church_admin_settings_path(church), params: {
        church: {
          description: "Iglesia local activa",
          slug: "mi-iglesia",
          primary_color: "#0F172A",
          public_page_enabled: "1",
          service_directory_enabled: "1"
        }
      }

      expect(response).to redirect_to(church_admin_settings_path(church))
      expect(church.reload.description).to eq("Iglesia local activa")
      expect(church.slug).to eq("mi-iglesia")
      expect(church.primary_color).to eq("#0F172A")
      expect(church.public_page_enabled).to be(true)
      expect(church.service_directory_enabled).to be(true)
    end

    it "rejects invalid color format" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      patch church_admin_settings_path(church), params: {
        church: { primary_color: "rojo" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(church.reload.primary_color).to be_nil
    end

    it "rejects users without permission" do
      church = create(:church)
      membership = create(:church_membership, church:)

      sign_in membership.user

      patch church_admin_settings_path(church), params: { church: { description: "Hack" } }

      expect(response).to redirect_to(root_path)
      expect(church.reload.description).to be_nil
    end
  end
end
