module Public
  class EventsController < BaseController
    def show
      resolve_public_church!

      @event = @church.events.visibility_public.find_by_public_id!(params[:public_id])
    end
  end
end
