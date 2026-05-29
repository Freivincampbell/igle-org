module Reports
  class NewMembersReport < BaseReport
    def title = "Miembros nuevos por mes"
    def filename = "miembros-nuevos"

    def columns
      [
        { key: :full_name, label: "Nombre completo" },
        { key: :official_membership_on, label: "Fecha de membresía" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |member|
        {
          full_name: member.full_name,
          official_membership_on: member.official_membership_on,
          phone: member.phone
        }
      end
    end

    private

    def scope
      relation = church.members.where.not(official_membership_on: nil).ordered
      month = parse_month
      return relation unless month

      relation.where(official_membership_on: month.all_month)
    end

    def parse_month
      value = filters[:month].to_s
      return nil if value.blank?

      Date.strptime(value, "%Y-%m")
    rescue ArgumentError
      nil
    end
  end
end
