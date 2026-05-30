module Pastor
  class MembersController < BaseController
    include Pagy::Method

    before_action :set_member, only: %i[show]

    def index
      skip_authorization
      skip_policy_scope
      base = @church.members.active.includes(:ministries)
      base = base.search_by_name(params[:q]) if params[:q].present?

      @pagy, @members = pagy(base.ordered, limit: 30)
    end

    def show
      skip_authorization
      @pastoral_notes = @church.pastoral_notes
        .where(member: @member)
        .where(pastor: current_user)
        .ordered
    end

    private

    def set_member
      @member = @church.members.find_by_public_id!(params[:public_id])
    end
  end
end
