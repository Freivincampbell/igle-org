class ChurchSettingPolicy < ApplicationPolicy
  def show?
    super_admin? || (same_church? && permission?("church_settings", "read"))
  end

  def update?
    super_admin? || (same_church? && permission?("church_settings", "update"))
  end
end
