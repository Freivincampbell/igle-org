module ChurchAdmin
  class SkillsController < BaseController
    before_action :set_skill, only: %i[edit update activate deactivate]

    def index
      authorize Skill

      @skills = policy_scope(Skill).where(church: @church).ordered
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
