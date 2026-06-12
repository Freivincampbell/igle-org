require "rails_helper"

RSpec.describe Event do
  describe "validations" do
    it "requires church, title and starts_at" do
      event = Event.new

      event.valid?

      expect(event.errors).to include(:church, :title, :starts_at)
    end

    it "rejects ends_at before starts_at" do
      event = build(:event, starts_at: 1.day.from_now, ends_at: 1.day.ago)

      expect(event).not_to be_valid
      expect(event.errors[:ends_at]).to be_present
    end

    it "rejects recurrence_until before starts_at" do
      event = build(:event, starts_at: 5.days.from_now, recurring: true, recurrence_frequency: "weekly", recurrence_until: 1.day.from_now.to_date)

      expect(event).not_to be_valid
      expect(event.errors[:recurrence_until]).to be_present
    end

    it "rejects ministry from another church" do
      church = create(:church)
      other_ministry = create(:ministry)
      event = build(:event, church:, ministry: other_ministry)

      expect(event).not_to be_valid
      expect(event.errors[:ministry]).to be_present
    end

    it "rejects responsible member from another church" do
      church = create(:church)
      other_member = create(:member)
      event = build(:event, church:, responsible_member: other_member)

      expect(event).not_to be_valid
      expect(event.errors[:responsible_member]).to be_present
    end
  end

  describe "scopes" do
    it "lists upcoming separately from past" do
      church = create(:church)
      upcoming = create(:event, church:, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours)
      past = create(:event, church:, starts_at: 1.week.ago, ends_at: 1.week.ago + 2.hours)

      expect(church.events.upcoming).to include(upcoming)
      expect(church.events.upcoming).not_to include(past)
      expect(church.events.past).to include(past)
    end
  end

  describe "multi-tenant isolation" do
    it "scopes events to the church" do
      church_a = create(:church)
      church_b = create(:church)
      event_a = create(:event, church: church_a)
      event_b = create(:event, church: church_b)

      expect(church_a.events).to include(event_a)
      expect(church_a.events).not_to include(event_b)
    end
  end

  describe "conteo de confirmados" do
    it "suma miembros, acompañantes e invitados confirmados" do
      church = create(:church)
      event = create(:event, church:, visibility: "public")
      create(:event_rsvp, church:, event:, status: "attending", guests_count: 2)   # 3
      create(:event_rsvp, church:, event:, status: "maybe", guests_count: 5)       # 0
      create(:event_guest_rsvp, church:, event:, guests_count: 1)                  # 2
      create(:event_guest_rsvp, :cancelled, church:, event:)                       # 0

      expect(event.confirmed_attendees_count).to eq(5)
      expect(event.member_attending_count).to eq(1)
      expect(event.member_guests_count).to eq(2)
      expect(event.guest_attendees_count).to eq(2)
      expect(event.maybe_count).to eq(1)
      expect(event.not_attending_count).to eq(0)
    end
  end
end
