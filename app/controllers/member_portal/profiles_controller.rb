module MemberPortal
  class ProfilesController < BaseController
    def show
      redirect_to root_path, alert: t("member_portal.no_profile") and return unless current_member

      @member = current_member
      @pending_request = @member.profile_change_requests.pending.order(created_at: :desc).first
    end
  end
end
