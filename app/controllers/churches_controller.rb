class ChurchesController < ApplicationController
  before_action :authenticate_user!

  def index
    @churches = policy_scope(Church).order(:name)
  end

  def show
    @church = Church.find_by_public_id!(params[:public_id])
    authorize @church

    Current.church = @church
    Current.church_membership = current_user.active_membership_for(@church)
    session[:current_church_public_id] = @church.public_id
  end
end
