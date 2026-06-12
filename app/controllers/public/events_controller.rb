module Public
  class EventsController < BaseController
    def show
      @church = Church.publicly_visible.find_by(slug: params[:slug].to_s.downcase)
      raise ActiveRecord::RecordNotFound if @church.nil?

      @event = @church.events.visibility_public.find_by_public_id!(params[:public_id])
    end
  end
end
