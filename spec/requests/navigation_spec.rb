require "rails_helper"

RSpec.describe "Navigation" do
  it "shows the platform menu and logout to super admins" do
    user = create(:user, :super_admin)

    sign_in user

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Plataforma")
    expect(response.body).to include("Mis iglesias")
    expect(response.body).to include("Salir")
  end

  it "shows church admin navigation to church owners" do
    church = create(:church)
    membership = create(:church_membership, :owner, church:)

    sign_in membership.user

    get church_admin_ministries_path(church)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Resumen")
    expect(response.body).to include("Roles")
    expect(response.body).to include("Usuarios")
    expect(response.body).to include("Miembros")
    expect(response.body).to include("Ministerios")
    expect(response.body).to include("Salir")
  end

  it "does not show logout to guests" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Salir")
  end

  it "logs users out from the navigation action" do
    user = create(:user)

    sign_in user

    delete destroy_user_session_path

    expect(response).to redirect_to(root_path)
  end
end
