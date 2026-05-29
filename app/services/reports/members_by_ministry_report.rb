module Reports
  class MembersByMinistryReport < BaseReport
    ROLE_LABELS = { "member" => "Miembro", "leader" => "Líder", "co_leader" => "Co-líder" }.freeze

    def title = "Miembros por ministerio"
    def filename = "miembros-por-ministerio"

    def columns
      [
        { key: :ministry, label: "Ministerio" },
        { key: :member, label: "Miembro" },
        { key: :ministry_role, label: "Rol en ministerio" },
        { key: :status, label: "Estado" }
      ]
    end

    def rows
      scope.map do |mm|
        {
          ministry: mm.ministry.name,
          member: mm.member.full_name,
          ministry_role: ROLE_LABELS.fetch(mm.ministry_role, mm.ministry_role),
          status: mm.active? ? "Activo" : "Inactivo"
        }
      end
    end

    private

    def scope
      relation = MinistryMembership
        .joins(:ministry, :member)
        .where(ministries: { church_id: church.id })
        .where(ministry_memberships: { status: "active" })
        .includes(:ministry, :member)
        .order("ministries.name", "members.last_name")

      ministry_id = filters[:ministry_id].presence
      ministry_id ? relation.where(ministry_id:) : relation
    end
  end
end
