module ChurchAdmin
  class ServiceDirectoryController < BaseController
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize ServiceDirectoryPolicy, :index?, policy_class: ServiceDirectoryPolicy

      @filter = params[:filter].presence || "all"

      member_ids = member_ids_for_filter

      # Narrow by specific occupation
      if params[:occupation_id].present?
        occ_ids = @church.member_occupations
          .where(occupation_id: params[:occupation_id])
          .pluck(:member_id)
        member_ids &= occ_ids
      end

      # Narrow by specific skill
      if params[:skill_id].present?
        skill_ids = @church.member_skills
          .where(skill_id: params[:skill_id])
          .pluck(:member_id)
        member_ids &= skill_ids
      end

      @members = @church.members.active
        .where(id: member_ids.uniq)
        .preload(member_occupations: :occupation, member_skills: :skill)
        .order(:last_name, :first_name)

      @occupation_options = @church.occupations.active.order(:name).pluck(:name, :id)
      @skill_options      = @church.skills.active.order(:name).pluck(:name, :id)
    end

    private

    def member_ids_for_filter
      active = ->(scope) { scope.joins(:member).where(members: { member_status: "active" }) }

      case @filter
      when "offers"
        occ = active.(@church.member_occupations.where(offers_services: true)).pluck(:member_id)
        sk  = active.(@church.member_skills.where(offers_service: true)).pluck(:member_id)
        occ + sk

      when "looking_for_work"
        active.(@church.member_occupations.where(looking_for_work: true)).pluck(:member_id)

      when "skills"
        active.(@church.member_skills.where(offers_service: true)).pluck(:member_id)

      else
        # "all" — any member with at least one occupation or skill
        occ = active.(@church.member_occupations).pluck(:member_id)
        sk  = active.(@church.member_skills).pluck(:member_id)
        occ + sk
      end
    end
  end
end
