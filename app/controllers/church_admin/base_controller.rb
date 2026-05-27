module ChurchAdmin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :set_church_context
    before_action :authorize_church_access

    private

    def set_church_context
      @church = Church.find_by_public_id!(params[:church_public_id])
      Current.church = @church
      Current.church_membership = current_user.active_membership_for(@church)
      session[:current_church_public_id] = @church.public_id
    end

    def authorize_church_access
      authorize @church, :show?
    end
  end
end
