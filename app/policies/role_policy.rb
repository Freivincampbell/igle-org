class RolePolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("roles", "read")
  end

  def show?
    super_admin? || (same_church? && permission?("roles", "read"))
  end

  def create?
    super_admin? || permission?("roles", "create")
  end

  def update?
    super_admin? || (same_church? && permission?("roles", "update"))
  end

  def activate?
    super_admin? || (same_church? && permission?("roles", "activate"))
  end

  def deactivate?
    super_admin? || (same_church? && permission?("roles", "deactivate"))
  end

  def manage?
    super_admin? || (same_church? && permission?("roles", "manage"))
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
