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

      configured = permission_filter("ministries", "read", scope.where(church: current_church))
      led = user_led_ministries
      scope.where(id: configured.select(:id)).or(scope.where(id: led.select(:id)))
    end
  end
end
