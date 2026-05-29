module ChurchAdmin
  class DashboardController < BaseController
    def index
      skip_authorization
      skip_policy_scope

      @stats = {
        members_active:          @church.members.active.count,
        ministries_active:       @church.ministries.where(status: "active").count,
        events_upcoming:         @church.events.upcoming.count,
        pending_change_requests: @church.profile_change_requests.where(status: "pending").count
      }

      @upcoming_events   = @church.events.upcoming.includes(:ministry).limit(5)
      @recent_members    = @church.members.active.order(created_at: :desc).limit(5)
      @pending_requests  = @church.profile_change_requests.where(status: "pending")
                             .includes(:member).order(created_at: :desc).limit(5)
    end
  end
end
