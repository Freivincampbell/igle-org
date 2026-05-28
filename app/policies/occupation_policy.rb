class OccupationPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("occupations", "read")
  end

  def show?
    super_admin? || (same_church? && permission?("occupations", "read"))
  end

  def create?
    super_admin? || permission?("occupations", "create")
  end

  def update?
    super_admin? || (same_church? && permission?("occupations", "update"))
  end

  def activate?
    super_admin? || (same_church? && permission?("occupations", "activate"))
  end

  def deactivate?
    super_admin? || (same_church? && permission?("occupations", "deactivate"))
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
