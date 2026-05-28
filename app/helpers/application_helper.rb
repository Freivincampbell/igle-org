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
end
