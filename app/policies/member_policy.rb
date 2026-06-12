class MemberPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("members", "read")
  end

  def search?
    index?
  end

  def show?
    super_admin? || (same_church? && permission?("members", "read"))
  end

  def create?
    super_admin? || permission?("members", "create")
  end

  def update?
    super_admin? || (same_church? && permission?("members", "update"))
  end

  def activate?
    super_admin? || (same_church? && permission?("members", "activate"))
  end

  def deactivate?
    super_admin? || (same_church? && permission?("members", "deactivate"))
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      permission_filter("members", "read", scope.where(church: current_church))
    end
  end
end
