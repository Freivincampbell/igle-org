class MinistryPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("ministries", "read") || user_led_ministries.any?
  end

  def show?
    super_admin? || (same_church? && (permission?("ministries", "read") || ministry_leader_of?(record)))
  end

  def create?
    super_admin? || permission?("ministries", "create")
  end

  def update?
    super_admin? || (same_church? && (permission?("ministries", "update") || ministry_leader_of?(record)))
  end

  def activate?
    super_admin? || (same_church? && (permission?("ministries", "activate") || ministry_leader_of?(record)))
  end

  def deactivate?
    super_admin? || (same_church? && (permission?("ministries", "deactivate") || ministry_leader_of?(record)))
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      return scope.where(church: current_church) if owner? || permission?("ministries", "read")

      led = user_led_ministries
      led.any? ? led : scope.none
    end
  end
end
