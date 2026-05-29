class SkillPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("skills", "read")
  end

  def show?
    super_admin? || (same_church? && permission?("skills", "read"))
  end

  def create?
    super_admin? || permission?("skills", "create")
  end

  def update?
    super_admin? || (same_church? && permission?("skills", "update"))
  end

  def activate?
    super_admin? || (same_church? && permission?("skills", "activate"))
  end

  def deactivate?
    super_admin? || (same_church? && permission?("skills", "deactivate"))
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
