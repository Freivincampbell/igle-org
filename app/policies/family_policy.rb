class FamilyPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("families", "read")
  end

  def show?
    super_admin? || (same_church? && permission?("families", "read"))
  end

  def create?
    super_admin? || permission?("families", "create")
  end

  def update?
    super_admin? || (same_church? && permission?("families", "update"))
  end

  def activate?
    super_admin? || (same_church? && permission?("families", "activate"))
  end

  def deactivate?
    super_admin? || (same_church? && permission?("families", "deactivate"))
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
