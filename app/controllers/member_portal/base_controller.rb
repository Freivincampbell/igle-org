module MemberPortal
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :set_church_context
    before_action :authorize_member_access

    private

    def set_church_context
      @church = Church.find_by_public_id!(params[:church_public_id])
      Current.church = @church
      Current.church_membership = current_user.active_membership_for(@church)
      session[:current_church_public_id] = @church.public_id
    end

    def authorize_member_access
      authorize @church, :show?
    end

    def current_member
      @current_member ||= @church.members.find_by(user_id: current_user.id)
    end
  end
end
