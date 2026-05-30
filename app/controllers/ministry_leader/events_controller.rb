module MinistryLeader
  class EventsController < BaseController
    skip_after_action :verify_policy_scoped
    skip_after_action :verify_authorized

    before_action :set_event, only: %i[show]

    def index
      base = @church.events.where(ministry: led_ministries).includes(:ministry)
      base = base.search_by_name(params[:q]) if params[:q].present?

      @filter = params[:filter].presence || "upcoming"
      filtered = case @filter
                 when "past" then base.past
                 when "all"  then base.ordered
                 else             base.upcoming
                 end

      @pagy, @events = pagy(filtered, limit: 25)
    end

    def show
      unless led_ministries.include?(@event.ministry)
        raise Pundit::NotAuthorizedError
      end

      @rsvps      = @event.event_rsvps.includes(:member)
      @attendances = @event.event_attendances.includes(:member)
    end

    private

    def set_event
      @event = @church.events.find_by_public_id!(params[:public_id])
    end
  end
end
