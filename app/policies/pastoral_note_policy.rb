class PastoralNotePolicy < ApplicationPolicy
  def index?
    pastoral_access?("read")
  end

  def show?
    same_church? && pastoral_access?("read")
  end

  def create?
    pastoral_access?("create")
  end

  def update?
    same_church? && pastoral_access?("update")
  end

  def destroy?
    same_church? && pastoral_access?("manage")
  end

  private

  def pastoral_access?(action)
    return false unless active_church_member?
    return false unless user_has_pastoral_role?

    permission?("pastoral_notes", action)
  end

  def user_has_pastoral_role?
    return false if current_membership.blank?

    current_membership.roles.active.where(pastoral: true).exists?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?
      return scope.none unless current_membership.roles.active.where(pastoral: true).exists?

      scope.where(church: current_church)
    end
  end
end
