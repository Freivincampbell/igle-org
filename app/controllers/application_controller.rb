class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_context
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_church, :current_church_membership

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_context
    Current.user = current_user
    Current.church = resolve_current_church
    Current.church_membership = current_user&.active_membership_for(Current.church)
  end

  def resolve_current_church
    public_id = params[:public_id].presence || params[:church_public_id].presence || session[:current_church_public_id].presence
    return if public_id.blank?

    return unless public_id.to_s.match?(PublicIdentifiable::UUID_FORMAT)

    Church.find_by(public_id:)
  end

  def current_church
    Current.church
  end

  def current_church_membership
    Current.church_membership
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name])
  end

  def user_not_authorized
    flash[:alert] = t("authorization.not_authorized")
    redirect_back_or_to root_path
  end
end
