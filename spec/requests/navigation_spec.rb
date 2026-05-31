require "rails_helper"

RSpec.describe "Navigation" do
  it "muestra link a Plataforma y Salir al super admin" do
    user = create(:user, :super_admin)

    sign_in user

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Plataforma")
    expect(response.body).to include("Salir")
  end

  it "no muestra el chip de iglesia cuando el usuario no está en una iglesia" do
    user = create(:user)

    sign_in user

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("data-sidebar-target=\"nav\"")
  end

  it "muestra el sidebar con las 4 secciones a un owner de iglesia" do
    church = create(:church)
    membership = create(:church_membership, :owner, church:)

    sign_in membership.user

    get church_admin_members_path(church)

    expect(response).to have_http_status(:ok)
    # sidebar present
    expect(response.body).to include("data-sidebar-target=\"nav\"")
    # section labels
    expect(response.body).to include("Congregación")
    expect(response.body).to include("Actividades")
    expect(response.body).to include("Herramientas")
    expect(response.body).to include("Administración")
    # items
    expect(response.body).to include("Resumen")
    expect(response.body).to include("Miembros")
    expect(response.body).to include("Ministerios")
    expect(response.body).to include("Eventos")
    expect(response.body).to include("Roles")
    expect(response.body).to include("Salir")
  end

  it "muestra el chip de iglesia en el topbar cuando hay iglesia activa" do
    church = create(:church)
    membership = create(:church_membership, :owner, church:)

    sign_in membership.user

    get church_admin_members_path(church)

    expect(response.body).to include(church.name)
    expect(response.body).to include("sidebar-chip-church")
  end

  it "no muestra Notas pastorales a un owner sin rol pastoral" do
    church = create(:church)
    membership = create(:church_membership, :owner, church:)

    sign_in membership.user

    get church_admin_members_path(church)

    expect(response.body).not_to include("Notas pastorales")
  end

  it "no muestra el sidebar fuera del contexto de iglesia" do
    user = create(:user)

    sign_in user

    get churches_path

    expect(response.body).not_to include("data-sidebar-target=\"nav\"")
  end

  it "no muestra Salir a visitantes" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Salir")
  end

  it "cierra sesión desde el topbar" do
    user = create(:user)

    sign_in user

    delete destroy_user_session_path

    expect(response).to redirect_to(root_path)
  end
end
