module Reports
  class MembersBySkillReport < BaseReport
    def title = "Miembros por habilidad"
    def filename = "miembros-por-habilidad"

    def columns
      [
        { key: :skill, label: "Habilidad" },
        { key: :member, label: "Miembro" },
        { key: :level, label: "Nivel" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |ms|
        {
          skill: ms.skill.name,
          member: ms.member.full_name,
          level: ms.level,
          phone: ms.member.phone
        }
      end
    end

    private

    def scope
      relation = church.member_skills
        .includes(:member, :skill)
        .joins(:member)
        .order("members.last_name")
      skill_id = filters[:skill_id].presence
      skill_id ? relation.where(skill_id:) : relation
    end
  end
end
