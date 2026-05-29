class EventPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("events", "read") || user_led_ministries.any?
  end

  def show?
    super_admin? || (same_church? && (permission?("events", "read") || leader_of_event_ministry?))
  end

  def create?
    super_admin? || permission?("events", "create")
  end

  def update?
    super_admin? || (same_church? && (permission?("events", "update") || leader_of_event_ministry?))
  end

  def activate?
    super_admin? || (same_church? && (permission?("events", "activate") || leader_of_event_ministry?))
  end

  def deactivate?
    super_admin? || (same_church? && (permission?("events", "deactivate") || leader_of_event_ministry?))
  end

  def attendance?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      return scope.where(church: current_church) if owner? || permission?("events", "read")

      led_ids = user_led_ministries.ids
      return scope.none if led_ids.empty?

      scope.where(church: current_church, ministry_id: led_ids)
    end
  end

  private

  def leader_of_event_ministry?
    record.ministry.present? && ministry_leader_of?(record.ministry)
  end
end
