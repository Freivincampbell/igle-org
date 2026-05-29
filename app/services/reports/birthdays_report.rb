module Reports
  class BirthdaysReport < BaseReport
    def title = "Cumpleaños por mes"
    def filename = "cumpleanos"

    def columns
      [
        { key: :full_name, label: "Nombre completo" },
        { key: :day, label: "Día" },
        { key: :month, label: "Mes" },
        { key: :turning_age, label: "Edad que cumple" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |member|
        {
          full_name: member.full_name,
          day: member.birth_date.day,
          month: member.birth_date.month,
          turning_age: turning_age(member.birth_date),
          phone: member.phone
        }
      end
    end

    private

    def scope
      relation = church.members
      month = filters[:month].to_i
      relation = relation.where("EXTRACT(MONTH FROM birth_date) = ?", month) if month.between?(1, 12)
      relation.order(Arel.sql("EXTRACT(DAY FROM birth_date)"))
    end

    def turning_age(birth_date)
      Date.current.year - birth_date.year
    end
  end
end
