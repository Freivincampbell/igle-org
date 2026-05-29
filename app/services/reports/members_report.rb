module Reports
  class MembersReport < BaseReport
    def title = "Reporte de miembros"
    def filename = "miembros"

    def columns
      [
        { key: :full_name, label: "Nombre completo" },
        { key: :gender, label: "Género" },
        { key: :marital_status, label: "Estado civil" },
        { key: :phone, label: "Teléfono" },
        { key: :email, label: "Email" },
        { key: :baptized_on, label: "Fecha de bautismo" },
        { key: :official_membership_on, label: "Fecha de membresía" },
        { key: :status, label: "Estado" }
      ]
    end

    def rows
      scope.map do |member|
        {
          full_name: member.full_name,
          gender: I18n.t("activerecord.attributes.member.genders.#{member.gender}", default: member.gender),
          marital_status: I18n.t("activerecord.attributes.member.marital_statuses.#{member.marital_status}", default: member.marital_status),
          phone: member.phone,
          email: member.email,
          baptized_on: member.baptized_on,
          official_membership_on: member.official_membership_on,
          status: member.active? ? "Activo" : "Inactivo"
        }
      end
    end

    private

    def scope
      relation = church.members.ordered
      case filters[:status]
      when "active" then relation.where(member_status: "active")
      when "inactive" then relation.where(member_status: "inactive")
      else relation
      end
    end
  end
end
