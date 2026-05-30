module ChurchAdmin
  class SkillsController < BaseController
    before_action :set_skill, only: %i[edit update activate deactivate]

    def index
      authorize Skill

      base = policy_scope(Skill).where(church: @church)
      base = base.where("LOWER(name) LIKE ?", "%#{params[:q].downcase.strip}%") if params[:q].present?
      base = base.where(status: params[:status]) if params[:status].present?

      @pagy, @skills = pagy(base.ordered, limit: 25)
    end

    def search
      authorize Skill, :index?
      skip_policy_scope
      q = params[:q].to_s.strip
      @results      = q.length >= 1 ? @church.skills.active.where("LOWER(name) LIKE ?", "%#{q.downcase}%").ordered.limit(8) : []
      @exact_match  = @church.skills.exists?(name: q)
      @query        = q
      @frame_id     = "skill-results-#{params[:frame_suffix].to_s.gsub(/[^a-z0-9-]/, '')}"
      render layout: false
    end

    def new
      @skill = @church.skills.new(status: "active")
      authorize @skill
    end

    def create
      @skill = @church.skills.new(skill_params)
      authorize @skill

      if @skill.save
        redirect_to church_admin_skills_path(@church), notice: t("church_admin.skills.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @skill
    end

    def update
      authorize @skill

      if @skill.update(skill_params)
        redirect_to church_admin_skills_path(@church), notice: t("church_admin.skills.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @skill
      @skill.active!
      redirect_to church_admin_skills_path(@church), notice: t("church_admin.skills.activated")
    end

    def deactivate
      authorize @skill
      @skill.inactive!
      redirect_to church_admin_skills_path(@church), notice: t("church_admin.skills.deactivated")
    end

    private

    def set_skill
      @skill = @church.skills.find_by_public_id!(params[:public_id])
    end

    def skill_params
      params.require(:skill).permit(:name, :description, :status)
    end
  end
end
