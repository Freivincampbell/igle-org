module Platform
  class ChurchesController < BaseController
    before_action :set_church, only: %i[show edit update activate deactivate]

    def index
      @churches = Church.order(:name)
    end

    def show
      @owner_memberships = @church.church_memberships
        .joins(:user)
        .includes(:user)
        .where(owner: true)
        .order("users.email")
    end

    def new
      @church = Church.new(default_church_attributes)
    end

    def create
      @church = Church.new(church_params)

      if @church.save
        redirect_to platform_church_path(@church), notice: t("platform.churches.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @church.update(church_params)
        redirect_to platform_church_path(@church), notice: t("platform.churches.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def activate
      @church.active!
      redirect_to platform_church_path(@church), notice: t("platform.churches.activated")
    end

    def deactivate
      @church.inactive!
      redirect_to platform_church_path(@church), notice: t("platform.churches.deactivated")
    end

    private

    def set_church
      @church = Church.find_by_public_id!(params[:public_id])
    end

    def church_params
      params.require(:church).permit(
        :name,
        :email,
        :phone,
        :website,
        :status,
        :locale,
        :time_zone,
        :address_line_1,
        :address_line_2,
        :city,
        :state,
        :postal_code,
        :country,
        :service_times
      )
    end

    def default_church_attributes
      {
        locale: I18n.locale.to_s,
        time_zone: ENV.fetch("TIME_ZONE", "America/Costa_Rica")
      }
    end
  end
end
