class PermissionPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("permissions", "read")
  end

  def show?
    index?
  end

  def manage?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      scope.joins(role_permissions: { role: :church })
        .where(roles: { church_id: current_church.id })
        .distinct
    end
  end
end
