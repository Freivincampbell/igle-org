module Pastor
  class MembersController < BaseController
    include Pagy::Method

    before_action :set_member, only: %i[show]

    def index
      skip_authorization
      skip_policy_scope
      @pagy, @members = pagy(
        @church.members.active.ordered.includes(:ministries),
        limit: 30
      )
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
