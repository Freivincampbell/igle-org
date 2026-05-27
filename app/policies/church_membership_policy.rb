class ChurchMembershipPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("church_memberships", "read")
  end

  def show?
    super_admin? || (same_church? && (record.user == user || permission?("church_memberships", "read")))
  end

  def create?
    super_admin? || (same_church? && permission?("church_memberships", "create"))
  end

  def update?
    super_admin? || (same_church? && permission?("church_memberships", "update"))
  end

  def activate?
    super_admin? || (same_church? && permission?("church_memberships", "activate"))
  end

  def deactivate?
    super_admin? || (same_church? && permission?("church_memberships", "deactivate"))
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
