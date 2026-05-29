module MemberPortal
  class ProfileChangeRequestsController < BaseController
    def new
      redirect_to root_path, alert: t("member_portal.no_profile") and return unless current_member

      @member = current_member
      @change_request = @member.profile_change_requests.new(church: @church)
    end

    def create
      redirect_to root_path, alert: t("member_portal.no_profile") and return unless current_member

      @member = current_member
      payload = filtered_payload

      @change_request = @member.profile_change_requests.new(
        church: @church,
        requested_by: current_user,
        status: "pending",
        changes_payload: payload
      )

      if payload.empty?
        @change_request.errors.add(:base, "Debes proponer al menos un cambio respecto al perfil actual.")
        render :new, status: :unprocessable_content
      elsif @change_request.save
        redirect_to church_member_portal_profile_path(@church), notice: t("member_portal.profile_change_requests.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def filtered_payload
      allowed = params.require(:profile_change_request).permit(*ProfileChangeRequest::ALLOWED_ATTRIBUTES)
      allowed.to_h.each_with_object({}) do |(key, value), result|
        normalized = value.is_a?(String) ? value.strip.presence : value
        result[key] = normalized if normalized != current_member.public_send(key) && normalized.present?
      end
    end
  end
end
