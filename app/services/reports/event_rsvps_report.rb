module Reports
  class EventRsvpsReport < BaseReport
    STATUS_LABELS = { "attending" => "Asistirá", "not_attending" => "No asistirá", "maybe" => "Tal vez" }.freeze

    def title = "Confirmaciones de asistencia"
    def filename = "confirmaciones"

    def columns
      [
        { key: :event, label: "Evento" },
        { key: :member, label: "Miembro" },
        { key: :status, label: "Estado RSVP" },
        { key: :guests_count, label: "Invitados" },
        { key: :notes, label: "Notas" }
      ]
    end

    def rows
      scope.map do |rsvp|
        {
          event: rsvp.event.title,
          member: rsvp.member.full_name,
          status: STATUS_LABELS.fetch(rsvp.status, rsvp.status),
          guests_count: rsvp.guests_count,
          notes: rsvp.notes
        }
      end
    end

    private

    def scope
      relation = church.event_rsvps.includes(:event, :member).joins(:member).order("members.last_name")
      event_id = filters[:event_id].presence
      event_id ? relation.where(event_id:) : relation
    end
  end
end
