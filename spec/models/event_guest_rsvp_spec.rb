require "rails_helper"

RSpec.describe EventGuestRsvp do
  it "es válido con los atributos de la factory" do
    expect(build(:event_guest_rsvp)).to be_valid
  end

  it "genera public_id UUID y access_token al crear" do
    rsvp = create(:event_guest_rsvp)

    expect(rsvp.public_id).to match(PublicIdentifiable::UUID_FORMAT)
    expect(rsvp.to_param).to eq(rsvp.public_id)
    expect(rsvp.access_token).to be_present
  end

  it "requiere nombre" do
    expect(build(:event_guest_rsvp, name: nil)).not_to be_valid
  end

  it "requiere email o teléfono" do
    expect(build(:event_guest_rsvp, email: nil, phone: nil)).not_to be_valid
    expect(build(:event_guest_rsvp, email: nil, phone: "8888-8888")).to be_valid
    expect(build(:event_guest_rsvp, email: "ana@example.com", phone: nil)).to be_valid
  end

  it "normaliza el email a minúsculas" do
    rsvp = create(:event_guest_rsvp, email: " Ana@Example.COM ")

    expect(rsvp.email).to eq("ana@example.com")
  end

  it "rechaza guests_count negativo" do
    expect(build(:event_guest_rsvp, guests_count: -1)).not_to be_valid
  end

  it "rechaza un evento de otra iglesia (aislamiento)" do
    church_a = create(:church)
    church_b = create(:church)
    event_b = create(:event, church: church_b, visibility: "public")

    rsvp = build(:event_guest_rsvp, church: church_a, event: event_b)

    expect(rsvp).not_to be_valid
  end

  it "no permite dos RSVPs con el mismo email en el mismo evento" do
    existing = create(:event_guest_rsvp, email: "ana@example.com")
    duplicate = build(:event_guest_rsvp, event: existing.event, church: existing.church,
                      email: "ANA@example.com")

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "registra versiones con paper_trail" do
    rsvp = create(:event_guest_rsvp)

    expect(rsvp.versions.count).to eq(1)
  end
end
