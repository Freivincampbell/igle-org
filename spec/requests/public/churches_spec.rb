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
end
