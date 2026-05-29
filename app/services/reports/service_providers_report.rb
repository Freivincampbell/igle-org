module Reports
  class ServiceProvidersReport < BaseReport
    def title = "Miembros que ofrecen servicios"
    def filename = "ofrecen-servicios"

    def columns
      [
        { key: :member, label: "Miembro" },
        { key: :occupation, label: "Ocupación" },
        { key: :job_title, label: "Cargo" },
        { key: :professional_contact, label: "Contacto profesional" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |mo|
        {
          member: mo.member.full_name,
          occupation: mo.occupation&.name,
          job_title: mo.job_title,
          professional_contact: mo.professional_contact,
          phone: mo.member.phone
        }
      end
    end

    private

    def scope
      church.member_occupations
        .where(offers_services: true)
        .includes(:member, :occupation)
        .joins(:member)
        .order("members.last_name")
    end
  end
end
