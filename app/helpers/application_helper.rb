module ApplicationHelper
  def permission_module_label(module_key)
    t("permissions.modules.#{module_key}", default: module_key.to_s.humanize)
  end

  def permission_action_label(action_key)
    t("permissions.actions.#{action_key}", default: action_key.to_s.humanize)
  end
end
