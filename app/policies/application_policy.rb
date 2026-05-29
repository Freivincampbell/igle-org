# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def activate?
    false
  end

  def deactivate?
    false
  end

  def export?
    false
  end

  def manage?
    false
  end

  private

  def super_admin?
    user&.super_admin?
  end

  def current_church
    Current.church
  end

  def current_membership
    Current.church_membership
  end

  def owner?
    current_membership&.owner?
  end

  def active_church_member?
    current_membership&.active?
  end

  def permission?(module_key, action_key)
    return false unless active_church_member?

    Permissions::PermissionChecker.allow?(
      user_context: Permissions::UserContext.new(
        user:,
        current_church:,
        church_membership: current_membership
      ),
      module_key:,
      action: action_key
    )
  end

  def record_church
    record.respond_to?(:church) ? record.church : record
  end

  def same_church?
    current_church.present? && record_church == current_church
  end

  def ministry_leader_of?(ministry)
    return false unless active_church_member?

    current_member = Member.find_by(user:, church: current_church)
    return false unless current_member

    MinistryMembership.exists?(
      ministry: ministry,
      member: current_member,
      ministry_role: %w[leader co_leader],
      status: "active"
    )
  end

  def user_led_ministries
    current_member = Member.find_by(user:, church: current_church)
    return Ministry.none unless current_member

    Ministry.joins(:ministry_memberships)
            .where(
              ministry_memberships: {
                member: current_member,
                ministry_role: %w[leader co_leader],
                status: "active"
              }
            )
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope

    def super_admin?
      user&.super_admin?
    end

    def current_church
      Current.church
    end

    def current_membership
      return if user.blank? || current_church.blank?

      user.active_membership_for(current_church)
    end

    def owner?
      current_membership&.owner?
    end

    def permission?(module_key, action_key)
      return false unless current_membership&.active?

      Permissions::PermissionChecker.allow?(
        user_context: Permissions::UserContext.new(
          user:,
          current_church:,
          church_membership: current_membership
        ),
        module_key:,
        action: action_key
      )
    end

    def ministry_leader_of?(ministry)
      return false unless current_membership&.active?

      current_member = Member.find_by(user:, church: current_church)
      return false unless current_member

      MinistryMembership.exists?(
        ministry: ministry,
        member: current_member,
        ministry_role: %w[leader co_leader],
        status: "active"
      )
    end

    def user_led_ministries
      current_member = Member.find_by(user:, church: current_church)
      return Ministry.none unless current_member

      Ministry.joins(:ministry_memberships)
              .where(
                ministry_memberships: {
                  member: current_member,
                  ministry_role: %w[leader co_leader],
                  status: "active"
                }
              )
    end
  end
end
