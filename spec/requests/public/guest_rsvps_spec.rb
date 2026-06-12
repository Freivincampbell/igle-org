require "rails_helper"

RSpec.describe "Public guest RSVPs" do
  def public_church(slug: "central")
    create(:church, slug:, public_page_enabled: true, status: "active")
  end

  def valid_params(overrides = {})
    { guest_rsvp: { name: "Ana Mora", email: "ana@example.com", phone: "", guests_count: 1 }.merge(overrides) }
  end

  describe "POST /c/:slug/eventos/:public_id/rsvp" do
    it "crea el RSVP y redirige a la página del token" do
      church = public_church
      event = create(:event, church:, visibility: "public")

      expect {
        post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp", params: valid_params
      }.to change(EventGuestRsvp, :count).by(1)

      rsvp = EventGuestRsvp.last
      expect(rsvp.church).to eq(church)
      expect(response).to redirect_to("/c/#{church.slug}/rsvp/#{rsvp.access_token}")
    end

    it "descarta silenciosamente cuando el honeypot viene lleno" do
      church = public_church
      event = create(:event, church:, visibility: "public")

      expect {
        post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp",
             params: valid_params.merge(website: "spam")
      }.not_to change(EventGuestRsvp, :count)

      expect(response).to redirect_to("/c/#{church.slug}/eventos/#{event.public_id}")
    end

    it "404 en eventos members_only" do
      church = public_church
      event = create(:event, church:, visibility: "members_only")

      post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp", params: valid_params

      expect(response).to have_http_status(:not_found)
    end

    it "404 en eventos cancelados" do
      church = public_church
      event = create(:event, church:, visibility: "public", status: "cancelled")

      post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp", params: valid_params

      expect(response).to have_http_status(:not_found)
    end

    it "rechaza cuando no hay cupo y re-renderiza con el error" do
      church = public_church
      event = create(:event, church:, visibility: "public", capacity: 1)

      post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp", params: valid_params(guests_count: 5)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("No hay cupos suficientes")
      expect(EventGuestRsvp.count).to eq(0)
    end

    it "404 con evento de otra iglesia bajo el slug (aislamiento)" do
      church_a = public_church(slug: "iglesia-a")
      church_b = public_church(slug: "iglesia-b")
      event_b = create(:event, church: church_b, visibility: "public")

      post "/c/#{church_a.slug}/eventos/#{event_b.public_id}/rsvp", params: valid_params

      expect(response).to have_http_status(:not_found)
      expect(EventGuestRsvp.count).to eq(0)
    end

    it "aplica throttle por IP cuando se excede el límite" do
      church = public_church
      event = create(:event, church:, visibility: "public")
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)

      6.times do |i|
        post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp",
             params: valid_params(email: "ana#{i}@example.com")
      end

      expect(EventGuestRsvp.count).to eq(5)
      expect(response).to redirect_to("/c/#{church.slug}/eventos/#{event.public_id}")
      follow_redirect!
      expect(response.body).to include("Demasiados intentos")
    end
  end
end
