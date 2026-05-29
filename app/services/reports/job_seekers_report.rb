module Reports
  class JobSeekersReport < BaseReport
    def title = "Miembros buscando trabajo"
    def filename = "buscando-trabajo"

    def columns
      [
        { key: :member, label: "Miembro" },
        { key: :occupation, label: "Ocupación" },
        { key: :professional_contact, label: "Contacto profesional" },
        { key: :phone, label: "Teléfono" },
        { key: :email, label: "Email" }
      ]
    end

    def rows
      scope.map do |mo|
        {
          member: mo.member.full_name,
          occupation: mo.occupation&.name,
          professional_contact: mo.professional_contact,
          phone: mo.member.phone,
          email: mo.member.email
        }
      end
    end

    private

    def scope
      church.member_occupations
        .where(looking_for_work: true)
        .includes(:member, :occupation)
        .joins(:member)
        .order("members.last_name")
    end
  end
end
