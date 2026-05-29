module ChurchAdmin
  class MemberSkillsController < BaseController
    before_action :set_member
    before_action :set_member_skill, only: %i[edit update destroy]

    def new
      @member_skill = @member.member_skills.new(church: @church, level: "basic")
      authorize @member, :update?
    end

    def create
      @member_skill = @member.member_skills.new(member_skill_params.merge(church: @church))
      authorize @member, :update?

      if @member_skill.save
        redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.member_skills.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @member, :update?
    end

    def update
      authorize @member, :update?

      if @member_skill.update(member_skill_params)
        redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.member_skills.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @member, :update?

      @member_skill.destroy
      redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.member_skills.removed")
    end

    private

    def set_member
      @member = @church.members.find_by_public_id!(params[:member_public_id])
    end

    def set_member_skill
      @member_skill = @member.member_skills.find_by_public_id!(params[:public_id])
    end

    def member_skill_params
      params.require(:member_skill).permit(:skill_id, :level, :notes)
    end
  end
end
