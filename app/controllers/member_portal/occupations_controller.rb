module MemberPortal
  # Self-service: el miembro gestiona sus propias ocupaciones sin aprobación.
  # La autorización vive en BaseController (authorize @church, :show?) y todas
  # las operaciones se acotan a current_member (alcance propio implícito).
  class OccupationsController < BaseController
    skip_after_action :verify_authorized

    def create
      return redirect_to_profile(alert: t("member_portal.no_profile")) unless current_member

      name = params[:occupation_name].to_s.strip
      return redirect_to_profile(alert: t("member_portal.occupations.name_required")) if name.blank?

      occupation = @church.occupations.find_or_create_by!(name:) { |o| o.status = "active" }
      member_occupation = current_member.member_occupations.find_or_initialize_by(occupation:, church: @church)
      member_occupation.employment_status = "employed" if member_occupation.new_record?
      member_occupation.offers_services = params[:offers_services].present?
      member_occupation.save!

      redirect_to_profile(notice: t("member_portal.occupations.added"))
    end

    def destroy
      return redirect_to_profile(alert: t("member_portal.no_profile")) unless current_member

      member_occupation = current_member.member_occupations.find_by_public_id!(params[:public_id])
      member_occupation.destroy
      redirect_to_profile(notice: t("member_portal.occupations.removed"))
    end

    private

    def redirect_to_profile(**flash)
      redirect_to church_member_portal_profile_path(@church), **flash
    end
  end
end
