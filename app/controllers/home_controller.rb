class HomeController < ApplicationController
  # Landing pública: no opera sobre recursos de dominio, no usa Pundit.
  skip_after_action :verify_policy_scoped, only: :index

  def index
  end
end
