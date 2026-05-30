module ChurchAdmin
  class ServiceTimesController < BaseController
    before_action :set_service_time, only: %i[edit update activate deactivate]

    def index
      authorize ChurchServiceTime

      base = policy_scope(ChurchServiceTime).where(church: @church)
      base = base.search_by_name(params[:q]) if params[:q].present?
      base = base.where(status: params[:status]) if params[:status].present?

      @pagy, @service_times = pagy(base.ordered, limit: 25)
    end

    def new
      @service_time = @church.church_service_times.new(status: "active")
      authorize @service_time
    end

    def create
      @service_time = @church.church_service_times.new(service_time_params)
      authorize @service_time

      if @service_time.save
        redirect_to church_admin_service_times_path(@church), notice: t("church_admin.service_times.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @service_time
    end

    def update
      authorize @service_time

      if @service_time.update(service_time_params)
        redirect_to church_admin_service_times_path(@church), notice: t("church_admin.service_times.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @service_time
      @service_time.active!
      redirect_to church_admin_service_times_path(@church), notice: t("church_admin.service_times.activated")
    end

    def deactivate
      authorize @service_time
      @service_time.inactive!
      redirect_to church_admin_service_times_path(@church), notice: t("church_admin.service_times.deactivated")
    end

    private

    def set_service_time
      @service_time = @church.church_service_times.find_by_public_id!(params[:public_id])
    end

    def service_time_params
      params.require(:church_service_time).permit(
        :name,
        :day_of_week,
        :starts_at,
        :ends_at,
        :location,
        :status,
        :position,
        :notes
      )
    end
  end
end
