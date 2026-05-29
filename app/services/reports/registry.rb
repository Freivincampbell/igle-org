module Reports
  module Registry
    REGISTRY = {
      "members"               => { class: Reports::MembersReport,             category: :members,    label: "Miembros" },
      "new_members"           => { class: Reports::NewMembersReport,          category: :members,    label: "Miembros nuevos por mes" },
      "birthdays"             => { class: Reports::BirthdaysReport,           category: :birthdays,  label: "Cumpleaños por mes" },
      "members_by_ministry"   => { class: Reports::MembersByMinistryReport,   category: :ministries, label: "Miembros por ministerio" },
      "members_by_occupation" => { class: Reports::MembersByOccupationReport, category: :labor,      label: "Miembros por ocupación" },
      "members_by_skill"      => { class: Reports::MembersBySkillReport,      category: :labor,      label: "Miembros por habilidad" },
      "job_seekers"           => { class: Reports::JobSeekersReport,          category: :labor,      label: "Miembros buscando trabajo" },
      "service_providers"     => { class: Reports::ServiceProvidersReport,    category: :labor,      label: "Miembros que ofrecen servicios" },
      "upcoming_events"       => { class: Reports::UpcomingEventsReport,      category: :events,     label: "Eventos próximos" },
      "event_rsvps"           => { class: Reports::EventRsvpsReport,          category: :events,     label: "Confirmaciones de asistencia" },
      "event_attendance"      => { class: Reports::EventAttendanceReport,     category: :events,     label: "Asistencia real por evento" }
    }.freeze

    CATEGORY_LABELS = {
      members: "Miembros",
      birthdays: "Cumpleaños",
      ministries: "Ministerios",
      labor: "Laborales",
      events: "Eventos y asistencia"
    }.freeze
  end
end
