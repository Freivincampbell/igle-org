module Reports
  class EventAttendanceReport < BaseReport
    def title = "Asistencia real por evento"
    def filename = "asistencia"

    def columns
      [
        { key: :event, label: "Evento" },
        { key: :member, label: "Miembro" },
        { key: :attended, label: "¿Asistió?" },
        { key: :checked_in_at, label: "Hora de check-in" }
      ]
    end

    def rows
      scope.map do |attendance|
        {
          event: attendance.event.title,
          member: attendance.member.full_name,
          attended: attendance.attended? ? "Sí" : "No",
          checked_in_at: attendance.checked_in_at
        }
      end
    end

    private

    def scope
      relation = church.event_attendances.includes(:event, :member).joins(:member).order("members.last_name")
      event_id = filters[:event_id].presence
      event_id ? relation.where(event_id:) : relation
    end
  end
end
