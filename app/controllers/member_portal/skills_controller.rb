module MemberPortal
  # Self-service: el miembro gestiona sus propias habilidades sin aprobación.
  class SkillsController < BaseController
    skip_after_action :verify_authorized

    def create
      return redirect_to_profile(alert: t("member_portal.no_profile")) unless current_member

      name = params[:skill_name].to_s.strip
      return redirect_to_profile(alert: t("member_portal.skills.name_required")) if name.blank?

      skill = @church.skills.find_or_create_by!(name:) { |s| s.status = "active" }
      member_skill = current_member.member_skills.find_or_initialize_by(skill:, church: @church)
      member_skill.level = MemberSkill::LEVELS.include?(params[:level]) ? params[:level] : "basic"
      member_skill.offers_service = params[:offers_service].present?
      member_skill.save!

      redirect_to_profile(notice: t("member_portal.skills.added"))
    end

    def destroy
      return redirect_to_profile(alert: t("member_portal.no_profile")) unless current_member

      member_skill = current_member.member_skills.find_by_public_id!(params[:public_id])
      member_skill.destroy
      redirect_to_profile(notice: t("member_portal.skills.removed"))
    end

    private

    def redirect_to_profile(**flash)
      redirect_to church_member_portal_profile_path(@church), **flash
    end
  end
end
