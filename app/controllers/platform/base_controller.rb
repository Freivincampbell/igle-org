module Platform
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_super_admin!

    private

    def require_super_admin!
      return if current_user.super_admin?

      flash[:alert] = t("authorization.not_authorized")
      redirect_to root_path
    end
  end
end
