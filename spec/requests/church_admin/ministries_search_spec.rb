require "rails_helper"

RSpec.describe "ChurchAdmin::Ministries#search", type: :request do
  let(:church)      { create(:church) }
  let(:membership)  { create(:church_membership, :owner, church:) }

  before { sign_in membership.user }

  let!(:alabanza)  { create(:ministry, church:, name: "Alabanza",          status: "active") }
  let!(:jovenes)   { create(:ministry, church:, name: "Jóvenes",           status: "active") }
  let!(:inactivo)  { create(:ministry, church:, name: "Alabanza Inactiva", status: "inactive") }
  let!(:otra_igles){ create(:ministry,           name: "Otro",              status: "active") }

  def search(q: "ala", frame_id: "test-frame", exclude: [])
    params = { q:, frame_id: }
    params["exclude[]"] = exclude if exclude.any?
    get search_church_admin_ministries_path(church), params:
  end

  it "retorna ministerios activos de la iglesia que coinciden con la búsqueda" do
    search(q: "ala")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Alabanza")
    expect(response.body).not_to include("Jóvenes")
    expect(response.body).not_to include("Alabanza Inactiva")
    expect(response.body).not_to include("Otro")
  end

  it "excluye los ministerios cuyos public_ids están en exclude[]" do
    search(q: "ala", exclude: [alabanza.public_id])
    expect(response.body).not_to include(alabanza.name)
  end

  it "devuelve cuerpo sin resultados para búsquedas de menos de 2 caracteres" do
    search(q: "a")
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Alabanza")
  end

  it "envuelve el resultado en el turbo-frame solicitado" do
    search(q: "ala", frame_id: "ministry-results-abc123")
    expect(response.body).to include('id="ministry-results-abc123"')
  end
end
