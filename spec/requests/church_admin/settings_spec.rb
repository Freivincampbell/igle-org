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

  describe "GET check_slug" do
    let(:church) { create(:church) }
    let(:membership) { create(:church_membership, :owner, church:) }

    before { sign_in membership.user }

    it "retorna disponible para un slug libre" do
      get check_slug_church_admin_settings_path(church),
          params: { slug: "iglesia-libre" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => true)
    end

    it "retorna disponible cuando el slug pertenece a la misma iglesia" do
      church.update!(slug: "mi-slug-actual")

      get check_slug_church_admin_settings_path(church),
          params: { slug: "mi-slug-actual" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => true)
    end

    it "retorna no disponible cuando el slug pertenece a otra iglesia" do
      create(:church, slug: "slug-tomado")

      get check_slug_church_admin_settings_path(church),
          params: { slug: "slug-tomado" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => false, "reason" => "taken")
    end

    it "retorna formato inválido para slug con espacios y mayúsculas" do
      get check_slug_church_admin_settings_path(church),
          params: { slug: "SLUG INVALIDO!" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => false, "reason" => "invalid_format")
    end

    it "retorna formato inválido para slug vacío" do
      get check_slug_church_admin_settings_path(church),
          params: { slug: "" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => false, "reason" => "invalid_format")
    end

    it "requiere autenticación" do
      sign_out membership.user

      get check_slug_church_admin_settings_path(church),
          params: { slug: "cualquier-slug" }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
