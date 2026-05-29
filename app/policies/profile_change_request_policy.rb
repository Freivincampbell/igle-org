class ProfileChangeRequestPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("profile_change_requests", "read")
  end

  def show?
    super_admin? || (same_church? && permission?("profile_change_requests", "read"))
  end

  def review?
    super_admin? || (same_church? && permission?("profile_change_requests", "update"))
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      scope.where(church: current_church)
    end
  end
end
