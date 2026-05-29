module Public
  class ChurchesController < BaseController
    def show
      @church = Church.publicly_visible.find_by(slug: params[:slug].to_s.downcase)
      raise ActiveRecord::RecordNotFound if @church.nil?

      @service_times = @church.church_service_times.active.ordered
    end
  end
end
