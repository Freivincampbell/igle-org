module MinistryLeader
  class MinistriesController < BaseController
    skip_after_action :verify_policy_scoped
    skip_after_action :verify_authorized

    before_action :set_ministry, only: %i[show]

    def index
      @ministries = led_ministries.order(:name)
    end

    def show
      unless led_ministries.include?(@ministry)
        raise Pundit::NotAuthorizedError
      end

      @members = @ministry.ministry_memberships
        .where(status: "active")
        .includes(:member)
        .order("members.last_name, members.first_name")
    end

    private

    def set_ministry
      @ministry = @church.ministries.find_by_public_id!(params[:public_id])
    end
  end
end
