module MinistryLeader
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :set_church_context
    before_action :authorize_leader_access

    private

    def set_church_context
      @church = Church.find_by_public_id!(params[:church_public_id])
      Current.church = @church
      Current.church_membership = current_user.active_membership_for(@church)
      session[:current_church_public_id] = @church.public_id
    end

    def authorize_leader_access
      membership = Current.church_membership
      unless membership&.active? && led_ministries.any?
        raise Pundit::NotAuthorizedError
      end
    end

    def led_ministries
      @led_ministries ||= begin
        member = @church.members.find_by(user: current_user)
        return Ministry.none unless member

        Ministry.joins(:ministry_memberships)
          .where(ministry_memberships: {
            member: member,
            ministry_role: %w[leader co_leader],
            status: "active"
          })
          .where(church: @church)
      end
    end
    helper_method :led_ministries
  end
end
