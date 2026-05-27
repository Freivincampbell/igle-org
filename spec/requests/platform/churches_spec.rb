require "rails_helper"

RSpec.describe "Platform churches" do
  describe "access control" do
    it "requires authentication" do
      get platform_churches_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires a super admin" do
      sign_in create(:user)

      get platform_churches_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("authorization.not_authorized"))
    end
  end

  describe "GET /platform/churches" do
    it "lists churches for super admins" do
      church = create(:church, name: "Iglesia Central")

      sign_in create(:user, :super_admin)
      get platform_churches_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Iglesia Central")
      expect(response.body).to include(church.public_id)
    end
  end

  describe "POST /platform/churches" do
    it "creates churches using public identifiers" do
      sign_in create(:user, :super_admin)

      expect do
        post platform_churches_path, params: {
          church: {
            name: "Iglesia Nueva",
            email: "nueva@example.test",
            phone: "555-0100",
            status: "active",
            locale: "es",
            time_zone: "America/Costa_Rica"
          }
        }
      end.to change(Church, :count).by(1)

      church = Church.find_by!(name: "Iglesia Nueva")

      expect(response).to redirect_to(platform_church_path(church))
      expect(response.location).to include(church.public_id)
      expect(response.location).not_to include("/#{church.id}")
    end
  end

  describe "PATCH /platform/churches/:public_id" do
    it "updates church basics" do
      church = create(:church, name: "Nombre viejo")

      sign_in create(:user, :super_admin)
      patch platform_church_path(church), params: {
        church: {
          name: "Nombre nuevo",
          email: "nuevo@example.test",
          status: "active",
          locale: "es",
          time_zone: "America/Costa_Rica"
        }
      }

      expect(response).to redirect_to(platform_church_path(church))
      expect(church.reload.name).to eq("Nombre nuevo")
      expect(church.email).to eq("nuevo@example.test")
    end
  end

  describe "activation" do
    it "deactivates and activates a church" do
      church = create(:church)

      sign_in create(:user, :super_admin)

      patch deactivate_platform_church_path(church)
      expect(response).to redirect_to(platform_church_path(church))
      expect(church.reload).to be_inactive

      patch activate_platform_church_path(church)
      expect(response).to redirect_to(platform_church_path(church))
      expect(church.reload).to be_active
    end
  end

  describe "public id routing" do
    it "does not resolve database ids" do
      church = create(:church)

      sign_in create(:user, :super_admin)
      get "/platform/churches/#{church.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
