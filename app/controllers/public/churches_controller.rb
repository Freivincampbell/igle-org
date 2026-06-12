module Public
  class ChurchesController < BaseController
    def show
      resolve_public_church!

      @service_times = @church.church_service_times.active.ordered
    end
  end
end
