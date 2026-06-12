module Public
  class ChurchesController < BaseController
    UPCOMING_EVENTS_LIMIT = 6

    def show
      resolve_public_church!

      @service_times = @church.church_service_times.active.ordered
      @upcoming_events = @church.events
        .visibility_public
        .where(status: "scheduled")
        .upcoming
        .limit(UPCOMING_EVENTS_LIMIT)
    end
  end
end
