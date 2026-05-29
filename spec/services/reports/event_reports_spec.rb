require "rails_helper"

RSpec.describe "Reportes de eventos" do
  let(:church) { create(:church) }

  describe Reports::UpcomingEventsReport do
    it "lista solo eventos futuros de la iglesia" do
      future = create(:event, church:, title: "Futuro", starts_at: 2.days.from_now, ends_at: 2.days.from_now + 2.hours)
      create(:event, church:, title: "Pasado", starts_at: 2.days.ago, ends_at: 2.days.ago + 2.hours)
      create(:event, title: "OtraIglesia", starts_at: 2.days.from_now, ends_at: 2.days.from_now + 2.hours)

      rows = described_class.new(church:).rows

      expect(rows.map { |r| r[:title] }).to contain_exactly(future.title)
    end
  end

  describe Reports::EventRsvpsReport do
    it "lista RSVPs de un evento" do
      event = create(:event, church:, title: "Culto")
      member = create(:member, church:, first_name: "Confirma")
      create(:event_rsvp, church:, event:, member:, status: "attending", guests_count: 2)

      rows = described_class.new(church:, filters: { event_id: event.id }).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:member]).to eq(member.full_name)
      expect(rows.first[:guests_count]).to eq(2)
    end
  end

  describe Reports::EventAttendanceReport do
    it "lista asistencia real de un evento" do
      event = create(:event, church:, title: "Culto")
      member = create(:member, church:, first_name: "Asiste")
      create(:event_attendance, church:, event:, member:, attended: true)

      rows = described_class.new(church:, filters: { event_id: event.id }).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:member]).to eq(member.full_name)
      expect(rows.first[:attended]).to eq("Sí")
    end
  end
end
