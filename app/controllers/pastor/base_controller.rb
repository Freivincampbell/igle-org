module Pastor
  class BaseController < ApplicationController
    include Pagy::Method
    before_action :authenticate_user!
    before_action :set_church_context
    before_action :authorize_pastor_access

    private

    def set_church_context
      @church = Church.find_by_public_id!(params[:church_public_id])
      Current.church = @church
      Current.church_membership = current_user.active_membership_for(@church)
      session[:current_church_public_id] = @church.public_id
    end

    def authorize_pastor_access
      authorize PastoralNote, :index?
    end
  end
end
