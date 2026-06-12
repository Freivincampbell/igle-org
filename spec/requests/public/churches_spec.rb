require "rails_helper"

RSpec.describe "Public church page" do
  it "muestra la página cuando está habilitada y la iglesia activa" do
    church = create(:church, name: "Iglesia Central", slug: "central",
                    public_page_enabled: true, status: "active")

    get "/c/#{church.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Iglesia Central")
  end

  it "es accesible sin autenticación (no redirige a login)" do
    create(:church, slug: "central", public_page_enabled: true, status: "active")

    get "/c/central"

    expect(response).to have_http_status(:ok)
    expect(response).not_to redirect_to(new_user_session_path)
  end

  it "404 cuando el slug no existe" do
    get "/c/no-existe"
    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando la página pública está deshabilitada" do
    create(:church, slug: "central", public_page_enabled: false, status: "active")
    get "/c/central"
    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando la iglesia está inactiva" do
    create(:church, slug: "central", public_page_enabled: true, status: "inactive")
    get "/c/central"
    expect(response).to have_http_status(:not_found)
  end

  it "no muestra datos de otra iglesia (aislamiento)" do
    create(:church, name: "Iglesia A", slug: "iglesia-a", public_page_enabled: true, status: "active")
    create(:church, name: "Iglesia B", slug: "iglesia-b", public_page_enabled: true, status: "active")

    get "/c/iglesia-a"

    expect(response.body).to include("Iglesia A")
    expect(response.body).not_to include("Iglesia B")
  end

  it "lista solo eventos públicos, programados y futuros de la propia iglesia" do
    church = create(:church, slug: "central", public_page_enabled: true, status: "active")
    other_church = create(:church, slug: "otra", public_page_enabled: true, status: "active")

    visible   = create(:event, church:, visibility: "public", title: "Campaña evangelística")
    _members  = create(:event, church:, visibility: "members_only", title: "Retiro interno")
    _past     = create(:event, church:, visibility: "public", title: "Evento pasado",
                       starts_at: 2.days.ago, ends_at: 2.days.ago + 1.hour)
    _cancelled = create(:event, church:, visibility: "public", title: "Evento cancelado",
                        status: "cancelled")
    _foreign  = create(:event, church: other_church, visibility: "public", title: "Evento ajeno")

    get "/c/central"

    expect(response.body).to include("Campaña evangelística")
    expect(response.body).to include("/c/central/eventos/#{visible.public_id}")
    expect(response.body).not_to include("Retiro interno")
    expect(response.body).not_to include("Evento pasado")
    expect(response.body).not_to include("Evento cancelado")
    expect(response.body).not_to include("Evento ajeno")
  end

  describe "contenido" do
    it "muestra descripción y horarios de culto activos, pero no los inactivos" do
      church = create(:church, name: "Iglesia Central", slug: "central",
                      description: "Una iglesia para la familia",
                      public_page_enabled: true, status: "active")
      create(:church_service_time, church:, name: "Culto dominical",
             day_of_week: 0, starts_at: "10:00", ends_at: "12:00",
             location: "Templo", status: "active")
      create(:church_service_time, church:, name: "Reunion interna oculta",
             day_of_week: 3, starts_at: "19:00", ends_at: "20:00", status: "inactive")

      get "/c/central"

      expect(response.body).to include("Una iglesia para la familia")
      expect(response.body).to include("Culto dominical")
      expect(response.body).to include("Templo")
      expect(response.body).not_to include("Reunion interna oculta")
    end

    it "no expone datos de personas ni notas internas de horarios" do
      church = create(:church, name: "Iglesia Central", slug: "central",
                      public_page_enabled: true, status: "active")
      create(:church_service_time, church:, name: "Culto", day_of_week: 0,
             starts_at: "10:00", ends_at: "12:00", notes: "Nota interna confidencial",
             status: "active")
      member = create(:member, church:, first_name: "MiembroPrivado")

      get "/c/central"

      expect(response.body).not_to include("Nota interna confidencial")
      expect(response.body).not_to include(member.full_name)
    end
  end

  describe "rediseño: secciones e información de contacto de la iglesia" do
    def enabled_church(**attrs)
      create(:church, { slug: "central", public_page_enabled: true, status: "active" }.merge(attrs))
    end

    it "muestra el contacto y la ubicación propios de la iglesia" do
      enabled_church(name: "Iglesia Central", email: "hola@central.test", phone: "2222-3333",
                     address_line_1: "Av. Central 120", city: "San José", country: "Costa Rica")

      get "/c/central"

      expect(response.body).to include("hola@central.test")
      expect(response.body).to include("Av. Central 120")
      expect(response.body).to include("google.com/maps")
    end

    it "muestra el botón flotante de WhatsApp solo con dígitos cuando hay número" do
      enabled_church(whatsapp: "+506 2222 3333")

      get "/c/central"

      expect(response.body).to include("https://wa.me/50622223333")
    end

    it "no muestra WhatsApp flotante sin número" do
      enabled_church(whatsapp: nil)

      get "/c/central"

      expect(response.body).not_to include("wa.me/")
    end

    it "solo renderiza los íconos de redes cuyas URLs existen" do
      enabled_church(instagram_url: "https://instagram.com/central", facebook_url: nil, youtube_url: nil)

      get "/c/central"

      expect(response.body).to include("instagram.com/central")
      expect(response.body).not_to include("youtube.com")
    end

    it "no muestra la sección de cultos cuando no hay horarios" do
      enabled_church

      get "/c/central"

      expect(response.body).not_to include("Horarios de culto")
    end

    it "muestra el teaser de directorio solo si está habilitado" do
      enabled_church(service_directory_enabled: true)
      get "/c/central"
      expect(response.body).to include("Directorio de servicios")
    end

    it "no muestra el teaser de directorio si está deshabilitado" do
      enabled_church(service_directory_enabled: false)
      get "/c/central"
      expect(response.body).not_to include("Directorio de servicios")
    end
  end
end
