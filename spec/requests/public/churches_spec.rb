require "rails_helper"

RSpec.describe "Public church page" do
  it "muestra la página cuando está habilitada y la iglesia activa" do
    church = create(:church, name: "Iglesia Central", slug: "central",
                    public_page_enabled: true, status: "active")

    get "/c/#{church.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Iglesia Central")
  end

  it "es accesible sin autenticación (no redirige a login)" do
    create(:church, slug: "central", public_page_enabled: true, status: "active")

    get "/c/central"

    expect(response).to have_http_status(:ok)
    expect(response).not_to redirect_to(new_user_session_path)
  end

  it "404 cuando el slug no existe" do
    get "/c/no-existe"
    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando la página pública está deshabilitada" do
    create(:church, slug: "central", public_page_enabled: false, status: "active")
    get "/c/central"
    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando la iglesia está inactiva" do
    create(:church, slug: "central", public_page_enabled: true, status: "inactive")
    get "/c/central"
    expect(response).to have_http_status(:not_found)
  end

  it "no muestra datos de otra iglesia (aislamiento)" do
    create(:church, name: "Iglesia A", slug: "iglesia-a", public_page_enabled: true, status: "active")
    create(:church, name: "Iglesia B", slug: "iglesia-b", public_page_enabled: true, status: "active")

    get "/c/iglesia-a"

    expect(response.body).to include("Iglesia A")
    expect(response.body).not_to include("Iglesia B")
  end

  describe "contenido" do
    it "muestra descripción y horarios de culto activos, pero no los inactivos" do
      church = create(:church, name: "Iglesia Central", slug: "central",
                      description: "Una iglesia para la familia",
                      public_page_enabled: true, status: "active")
      create(:church_service_time, church:, name: "Culto dominical",
             day_of_week: 0, starts_at: "10:00", ends_at: "12:00",
             location: "Templo", status: "active")
      create(:church_service_time, church:, name: "Reunion interna oculta",
             day_of_week: 3, starts_at: "19:00", ends_at: "20:00", status: "inactive")

      get "/c/central"

      expect(response.body).to include("Una iglesia para la familia")
      expect(response.body).to include("Culto dominical")
      expect(response.body).to include("Templo")
      expect(response.body).not_to include("Reunion interna oculta")
    end

    it "no expone datos sensibles ni notas de horarios" do
      church = create(:church, name: "Iglesia Central", slug: "central",
                      phone: "555-1234", email: "secreto@iglesia.test",
                      address_line_1: "Calle Privada 123",
                      public_page_enabled: true, status: "active")
      create(:church_service_time, church:, name: "Culto", day_of_week: 0,
             starts_at: "10:00", ends_at: "12:00", notes: "Nota interna confidencial",
             status: "active")
      member = create(:member, church:, first_name: "MiembroPrivado")

      get "/c/central"

      expect(response.body).not_to include("555-1234")
      expect(response.body).not_to include("secreto@iglesia.test")
      expect(response.body).not_to include("Calle Privada 123")
      expect(response.body).not_to include("Nota interna confidencial")
      expect(response.body).not_to include(member.full_name)
    end
  end
end
