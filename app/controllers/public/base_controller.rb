module Public
  class BaseController < ApplicationController
    layout "public"

    # Página pública: sin autenticación y sin Pundit.
    skip_before_action :authenticate_user!, raise: false
    skip_after_action :verify_authorized, raise: false
    skip_after_action :verify_policy_scoped, raise: false

    private

    def resolve_public_church!
      @church = Church.publicly_visible.find_by(slug: params[:slug].to_s.downcase)
      raise ActiveRecord::RecordNotFound if @church.nil?
    end
  end
end
