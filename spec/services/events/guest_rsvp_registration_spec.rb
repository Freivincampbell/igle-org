require "rails_helper"

RSpec.describe Events::GuestRsvpRegistration do
  def build_event(capacity: nil)
    create(:event, visibility: "public", status: "scheduled", capacity:)
  end

  it "crea un RSVP de invitado attending" do
    event = build_event

    registration = described_class.new(event:, name: "Ana Mora", email: "ana@example.com", guests_count: 2)

    expect(registration.save).to be(true)
    rsvp = registration.guest_rsvp
    expect(rsvp).to be_persisted
    expect(rsvp.church_id).to eq(event.church_id)
    expect(rsvp).to be_attending
    expect(rsvp.guests_count).to eq(2)
  end

  it "actualiza el RSVP existente del mismo email en lugar de duplicar" do
    event = build_event
    existing = create(:event_guest_rsvp, event:, church: event.church, email: "ana@example.com", guests_count: 0)

    registration = described_class.new(event:, name: "Ana Mora", email: "ANA@example.com ", guests_count: 3)

    expect { registration.save }.not_to change(EventGuestRsvp, :count)
    expect(existing.reload.guests_count).to eq(3)
    expect(existing.reload).to be_attending
  end

  it "reactiva un RSVP cancelado validando cupo" do
    event = build_event
    cancelled = create(:event_guest_rsvp, :cancelled, event:, church: event.church, email: "ana@example.com")

    registration = described_class.new(event:, name: cancelled.name, email: "ana@example.com", guests_count: 0)

    expect(registration.save).to be(true)
    expect(cancelled.reload).to be_attending
  end

  it "rechaza cuando no hay cupo suficiente" do
    event = build_event(capacity: 3)
    create(:event_rsvp, church: event.church, event:, status: "attending", guests_count: 1) # ocupa 2

    registration = described_class.new(event:, name: "Ana", email: "ana@example.com", guests_count: 1) # pide 2

    expect(registration.save).to be(false)
    expect(registration.errors[:base]).to be_present
    expect(EventGuestRsvp.count).to eq(0)
  end

  it "permite editar un RSVP existente sin contarse a sí mismo en el cupo" do
    event = build_event(capacity: 2)
    existing = create(:event_guest_rsvp, event:, church: event.church, email: "ana@example.com", guests_count: 1) # ocupa 2

    registration = described_class.new(event:, guest_rsvp: existing, name: existing.name,
                                       email: existing.email, guests_count: 1)

    expect(registration.save).to be(true)
  end

  it "rechaza eventos no programados" do
    event = create(:event, visibility: "public", status: "cancelled")

    registration = described_class.new(event:, name: "Ana", email: "ana@example.com", guests_count: 0)

    expect(registration.save).to be(false)
  end

  it "propaga errores de validación del modelo" do
    event = build_event

    registration = described_class.new(event:, name: "", email: "ana@example.com", guests_count: 0)

    expect(registration.save).to be(false)
    expect(registration.errors[:base]).to be_present
  end
end
