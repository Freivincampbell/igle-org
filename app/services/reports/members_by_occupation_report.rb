module Reports
  class MembersByOccupationReport < BaseReport
    def title = "Miembros por ocupación"
    def filename = "miembros-por-ocupacion"

    def columns
      [
        { key: :occupation, label: "Ocupación" },
        { key: :member, label: "Miembro" },
        { key: :job_title, label: "Cargo" },
        { key: :employment_status, label: "Estado de empleo" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |mo|
        {
          occupation: mo.occupation&.name,
          member: mo.member.full_name,
          job_title: mo.job_title,
          employment_status: mo.employment_status,
          phone: mo.member.phone
        }
      end
    end

    private

    def scope
      relation = church.member_occupations
        .includes(:member, :occupation)
        .joins(:member)
        .order("members.last_name")
      occupation_id = filters[:occupation_id].presence
      occupation_id ? relation.where(occupation_id:) : relation
    end
  end
end
