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

    @stats = {
      members_active:    @church.members.active.count,
      members_total:     @church.members.count,
      families_total:    @church.families.count,
      ministries_active: @church.ministries.active.count,
      events_upcoming:   @church.events.upcoming.count,
      pending_requests:  @church.profile_change_requests.where(status: "pending").count
    }

    @upcoming_events = @church.events.upcoming.includes(:ministry).limit(5)
    @recent_members  = @church.members.active.order(created_at: :desc)
                         .includes(photo_attachment: :blob).limit(5)
    @pending_requests = @church.profile_change_requests.where(status: "pending")
                          .includes(:member).order(created_at: :desc).limit(3)
  end
end
