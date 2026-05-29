module Reports
  class UpcomingEventsReport < BaseReport
    def title = "Eventos próximos"
    def filename = "eventos-proximos"

    def columns
      [
        { key: :title, label: "Título" },
        { key: :starts_at, label: "Fecha" },
        { key: :event_type, label: "Tipo" },
        { key: :ministry, label: "Ministerio" },
        { key: :location, label: "Lugar" },
        { key: :confirmed, label: "Confirmados" }
      ]
    end

    def rows
      scope.map do |event|
        {
          title: event.title,
          starts_at: event.starts_at,
          event_type: event.event_type,
          ministry: event.ministry&.name,
          location: event.location,
          confirmed: event.confirmed_attendees_count
        }
      end
    end

    private

    def scope
      church.events.includes(:ministry).upcoming
    end
  end
end
