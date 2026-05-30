module ChurchAdmin
  class ProfileChangeRequestsController < BaseController
    before_action :set_request, only: %i[show approve reject]

    def index
      authorize ProfileChangeRequest

      base = policy_scope(ProfileChangeRequest).where(church: @church)
               .includes(:member, :requested_by)
      if params[:q].present?
        base = base.joins(:member)
                   .where("(members.first_name || ' ' || members.last_name) ILIKE ?", "%#{params[:q].strip}%")
      end
      base = base.where(status: params[:status]) if params[:status].present?

      @pagy, @requests = pagy(base.ordered, limit: 25)
    end

    def show
      authorize @request
    end

    def approve
      authorize @request, :review?

      if @request.approve!(reviewer: current_user, notes: params[:review_notes])
        redirect_to church_admin_profile_change_requests_path(@church), notice: t("church_admin.profile_change_requests.approved")
      else
        redirect_to church_admin_profile_change_request_path(@church, @request), alert: t("church_admin.profile_change_requests.not_pending")
      end
    end

    def reject
      authorize @request, :review?

      if @request.reject!(reviewer: current_user, notes: params[:review_notes])
        redirect_to church_admin_profile_change_requests_path(@church), notice: t("church_admin.profile_change_requests.rejected")
      else
        redirect_to church_admin_profile_change_request_path(@church, @request), alert: t("church_admin.profile_change_requests.not_pending")
      end
    end

    private

    def set_request
      @request = @church.profile_change_requests.find_by_public_id!(params[:public_id])
    end
  end
end
