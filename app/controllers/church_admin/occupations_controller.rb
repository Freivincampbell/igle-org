module ChurchAdmin
  class OccupationsController < BaseController
    before_action :set_occupation, only: %i[edit update activate deactivate]

    def index
      authorize Occupation

      base = policy_scope(Occupation).where(church: @church)
      base = base.where("LOWER(name) LIKE ?", "%#{params[:q].downcase.strip}%") if params[:q].present?
      base = base.where(status: params[:status]) if params[:status].present?

      @pagy, @occupations = pagy(base.ordered, limit: 25)
    end

    def search
      authorize Occupation, :index?
      skip_policy_scope
      q = params[:q].to_s.strip
      @results      = q.length >= 1 ? @church.occupations.active.where("LOWER(name) LIKE ?", "%#{q.downcase}%").ordered.limit(8) : []
      @exact_match  = @church.occupations.exists?(name: q)
      @query        = q
      @frame_id     = "occupation-results-#{params[:frame_suffix].to_s.gsub(/[^a-z0-9-]/, '')}"
      render layout: false
    end

    def new
      @occupation = @church.occupations.new(status: "active")
      authorize @occupation
    end

    def create
      @occupation = @church.occupations.new(occupation_params)
      authorize @occupation

      if @occupation.save
        redirect_to church_admin_occupations_path(@church), notice: t("church_admin.occupations.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @occupation
    end

    def update
      authorize @occupation

      if @occupation.update(occupation_params)
        redirect_to church_admin_occupations_path(@church), notice: t("church_admin.occupations.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @occupation
      @occupation.active!
      redirect_to church_admin_occupations_path(@church), notice: t("church_admin.occupations.activated")
    end

    def deactivate
      authorize @occupation
      @occupation.inactive!
      redirect_to church_admin_occupations_path(@church), notice: t("church_admin.occupations.deactivated")
    end

    private

    def set_occupation
      @occupation = @church.occupations.find_by_public_id!(params[:public_id])
    end

    def occupation_params
      params.require(:occupation).permit(:name, :description, :status)
    end
  end
end
