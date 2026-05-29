module Public
  class BaseController < ApplicationController
    layout "public"

    # Página pública: sin autenticación y sin Pundit.
    skip_before_action :authenticate_user!, raise: false
    skip_after_action :verify_authorized, raise: false
    skip_after_action :verify_policy_scoped, raise: false
  end
end
