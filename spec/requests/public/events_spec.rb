require "rails_helper"

RSpec.describe "Public event page" do
  def public_church(slug: "central")
    create(:church, slug:, public_page_enabled: true, status: "active")
  end

  it "muestra un evento público de una iglesia habilitada, sin autenticación" do
    church = public_church
    event = create(:event, church:, visibility: "public", title: "Concierto de adoración")

    get "/c/#{church.slug}/eventos/#{event.public_id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Concierto de adoración")
  end

  it "404 cuando el evento es members_only" do
    church = public_church
    event = create(:event, church:, visibility: "members_only")

    get "/c/#{church.slug}/eventos/#{event.public_id}"

    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando el evento es private" do
    church = public_church
    event = create(:event, church:, visibility: "private")

    get "/c/#{church.slug}/eventos/#{event.public_id}"

    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando la página pública está deshabilitada" do
    church = create(:church, slug: "central", public_page_enabled: false, status: "active")
    event = create(:event, church:, visibility: "public")

    get "/c/central/eventos/#{event.public_id}"

    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando el evento pertenece a otra iglesia (aislamiento)" do
    church_a = public_church(slug: "iglesia-a")
    church_b = public_church(slug: "iglesia-b")
    event_b = create(:event, church: church_b, visibility: "public")

    get "/c/#{church_a.slug}/eventos/#{event_b.public_id}"

    expect(response).to have_http_status(:not_found)
  end

  it "no resuelve ids internos de la base" do
    church = public_church
    event = create(:event, church:, visibility: "public")

    get "/c/#{church.slug}/eventos/#{event.id}"

    expect(response).to have_http_status(:not_found)
  end
end
