module ApplicationHelper
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
end
