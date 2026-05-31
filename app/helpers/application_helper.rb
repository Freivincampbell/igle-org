module ApplicationHelper
  AVATAR_COLORS = %w[
    bg-blue-500 bg-emerald-500 bg-amber-500 bg-violet-500
    bg-rose-500 bg-cyan-500 bg-indigo-500 bg-teal-500
  ].freeze

  def member_initials(member)
    [ member.first_name, member.last_name ]
      .compact_blank
      .map { |n| n.first&.upcase }
      .join
      .presence || "?"
  end

  def member_avatar_color(public_id)
    AVATAR_COLORS[public_id.to_s.bytes.sum % AVATAR_COLORS.size]
  end

  def permission_module_label(module_key)
    t("permissions.modules.#{module_key}", default: module_key.to_s.humanize)
  end

  def permission_action_label(action_key)
    t("permissions.actions.#{action_key}", default: action_key.to_s.humanize)
  end

  def member_gender_label(gender)
    t("members.genders.#{gender}", default: gender.to_s.humanize)
  end

  def member_marital_status_label(marital_status)
    t("members.marital_statuses.#{marital_status}", default: marital_status.to_s.humanize)
  end

  def member_status_label(member_status)
    t("members.statuses.#{member_status}", default: member_status.to_s.humanize)
  end

  def ministry_status_label(status)
    t("ministries.statuses.#{status}", default: status.to_s.humanize)
  end

  def ministry_role_label(role)
    t("ministries.roles.#{role}", default: role.to_s.humanize)
  end

  def church_setting_visible?(church)
    return false if church.blank?

    ChurchSettingPolicy.new(current_user, church).show?
  rescue Pundit::NotAuthorizedError
    false
  end

  # True para vistas con scope de iglesia donde el sidebar tiene sentido:
  # dashboard (churches#show), ChurchAdmin::*, Pastor::*, MinistryLeader::*, MemberPortal::*.
  # Falso para landing pública, login, índice de iglesias, plataforma super admin.
  def show_church_sidebar?
    return false unless user_signed_in?
    return false unless current_church.present? && current_church_membership&.active?

    controller_class = controller.class.name.to_s

    return true if controller_class.start_with?("ChurchAdmin::")
    return true if controller_class.start_with?("Pastor::")
    return true if controller_class.start_with?("MinistryLeader::")
    return true if controller_class.start_with?("MemberPortal::")
    return true if controller_name == "churches" && action_name == "show"

    false
  end

  def day_of_week_label(day_of_week)
    return "" if day_of_week.blank?

    I18n.t("date.day_names")[day_of_week.to_i]
  end

  def church_service_time_status_label(status)
    t("ministries.statuses.#{status}", default: status.to_s.humanize)
  end

  def family_relationship_label(relationship)
    t("families.relationships.#{relationship}", default: relationship.to_s.humanize)
  end

  def family_status_label(status)
    t("families.statuses.#{status}", default: status.to_s.humanize)
  end

  def event_type_label(event_type)
    t("events.event_types.#{event_type}", default: event_type.to_s.humanize)
  end

  def event_visibility_label(visibility)
    t("events.visibilities.#{visibility}", default: visibility.to_s.humanize)
  end

  def event_status_label(status)
    t("events.statuses.#{status}", default: status.to_s.humanize)
  end

  def event_recurrence_label(recurrence)
    t("events.recurrence_frequencies.#{recurrence}", default: recurrence.to_s.humanize)
  end

  def occupation_status_label(status)
    t("occupations.statuses.#{status}", default: status.to_s.humanize)
  end

  def skill_status_label(status)
    t("skills.statuses.#{status}", default: status.to_s.humanize)
  end

  def skill_level_label(level)
    t("skills.levels.#{level}", default: level.to_s.humanize)
  end

  def employment_status_label(status)
    t("member_occupations.employment_statuses.#{status}", default: status.to_s.humanize)
  end

  def work_type_label(work_type)
    return "" if work_type.blank?

    t("member_occupations.work_types.#{work_type}", default: work_type.to_s.humanize)
  end

  def board_position_label(position)
    t("boards.positions.#{position}", default: position.to_s.humanize)
  end

  def board_status_label(status)
    t("boards.statuses.#{status}", default: status.to_s.humanize)
  end

  def profile_change_request_status_label(status)
    t("profile_change_requests.statuses.#{status}", default: status.to_s.humanize)
  end

  def pastoral_note_type_label(type)
    t("pastoral_notes.note_types.#{type}", default: type.to_s.humanize)
  end

  def sidebar_item_class(active)
    base = "flex items-center gap-2.5 px-4 py-2 text-sm border-r-2 transition-colors w-full"
    if active
      "#{base} font-semibold text-violet-700 bg-violet-50 border-violet-600"
    else
      "#{base} font-medium text-slate-600 border-transparent hover:bg-slate-50 hover:text-slate-900"
    end
  end
end
