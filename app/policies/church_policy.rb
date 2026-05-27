class ChurchPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return true if super_admin?

    user&.active_membership_for(record)&.active? || false
  end

  def create?
    super_admin?
  end

  def update?
    return true if super_admin?
    return false unless same_church?

    owner? || permission?("churches", "update")
  end

  def activate?
    super_admin? || (same_church? && owner?)
  end

  def deactivate?
    activate?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if user.blank?

      scope.joins(:church_memberships)
        .where(church_memberships: { user_id: user.id, status: "active" })
        .distinct
    end
  end
end
