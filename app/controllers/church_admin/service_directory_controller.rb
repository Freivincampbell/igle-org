module ChurchAdmin
  class ServiceDirectoryController < BaseController
    # El directorio no es un modelo con policy_scope; se filtra manualmente por
    # @church y se autoriza con ServiceDirectoryPolicy.
    skip_after_action :verify_policy_scoped, only: :index

    def index
      authorize ServiceDirectoryPolicy, :index?, policy_class: ServiceDirectoryPolicy

      scope = @church.member_occupations.includes(:member, :occupation)

      @filter = params[:filter].presence || "offers"
      scope = case @filter
      when "looking_for_work" then scope.where(looking_for_work: true)
      when "offers" then scope.where(offers_services: true)
      else scope
      end

      if params[:occupation_id].present?
        scope = scope.where(occupation_id: params[:occupation_id])
      end

      if params[:skill_id].present?
        skill_member_ids = @church.member_skills.where(skill_id: params[:skill_id]).pluck(:member_id)
        scope = scope.where(member_id: skill_member_ids)
      end

      @entries = scope.joins(:member).where(members: { member_status: "active" }).order("members.last_name")
      @occupation_options = @church.occupations.where(status: "active").order(:name).pluck(:name, :id)
      @skill_options = @church.skills.where(status: "active").order(:name).pluck(:name, :id)
    end
  end
end
