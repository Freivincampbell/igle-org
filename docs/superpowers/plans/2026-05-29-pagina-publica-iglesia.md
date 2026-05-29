# Página Pública de Iglesia — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Servir una página pública por iglesia en `/c/:slug` que muestra solo datos no sensibles (nombre, logo, descripción, colores, horarios de culto), visible únicamente cuando la iglesia la habilita y está activa.

**Architecture:** Namespace `Public::` (sin autenticación, exento de los guards Pundit de Etapa 15) con un layout propio. `Public::ChurchesController#show` resuelve la iglesia por `slug` a través del scope `Church.publicly_visible` y devuelve 404 si no aplica.

**Tech Stack:** Rails 8, Active Storage (logo), Tailwind, RSpec.

---

## Notas de entorno (leer primero)

- **Todo se corre dentro de Docker.** Prefijo de comandos:
  - Tests: `docker compose exec -T -e RAILS_ENV=test web bundle exec rspec <ruta>`
  - RuboCop: `docker compose exec -T web bin/rubocop <archivos>`
  - Brakeman: `docker compose exec -T web bin/brakeman -q --no-pager`
  - Si falta un gem: `docker compose exec -T web bundle install`.
- Estás en la rama `etapa-publica-pagina-iglesia`. NO cambies de rama.

## Contexto del código existente

- **`Church`** (`app/models/church.rb`): tiene `slug` (único, indexado, ya
  normalizado a minúsculas al guardar), `description`, `primary_color`,
  `secondary_color`, `public_page_enabled` (boolean, default false),
  enum `status` (active/inactive con `active?`), y `has_one_attached :logo`.
- **`ChurchServiceTime`** (`app/models/church_service_time.rb`): `name`,
  `day_of_week` (0–6), `starts_at`/`ends_at` (time), `location`, `notes`,
  enum `status`. Método `day_name` (devuelve `I18n.t("date.day_names")[day_of_week]`).
  Scope `ordered` (por día, hora, nombre) y enum scope `active`.
  Asociación `church.church_service_times`.
- **Logo en vistas** (patrón existente en settings):
  `image_tag church.logo.variant(resize_to_limit: [ 200, 200 ]).processed`.
- **Layout actual** (`app/views/layouts/application.html.erb`) renderiza
  `shared/app_navigation` (asume sesión). La página pública usa un layout aparte.
- **Guards de Etapa 15** en `ApplicationController`:
  `after_action :verify_authorized` (salvo index) y `verify_policy_scoped` (index).
  Los controladores públicos deben eximirse (igual que `HomeController`).
- **Rutas** (`config/routes.rb`): `root "home#index"` arriba; `devise_for :users`.

## Mapa de archivos

| Archivo | Acción |
|---|---|
| `app/models/church.rb` | Modificar — agregar scope `publicly_visible` |
| `config/routes.rb` | Modificar — ruta `get "/c/:slug"` |
| `app/controllers/public/base_controller.rb` | Crear — base pública sin auth, exenta de Pundit |
| `app/controllers/public/churches_controller.rb` | Crear — `#show` |
| `app/views/layouts/public.html.erb` | Crear — layout público minimalista |
| `app/views/public/churches/show.html.erb` | Crear — vista pública |
| `spec/models/church_spec.rb` | Modificar — spec del scope |
| `spec/requests/public/churches_spec.rb` | Crear — specs de request |

---

## Task 1: Scope `Church.publicly_visible`

**Files:**
- Modify: `app/models/church.rb`
- Test: `spec/models/church_spec.rb`

- [ ] **Step 1: Escribir el test**

Agregar a `spec/models/church_spec.rb` dentro del `RSpec.describe Church do ... end` (si el archivo no existe, créalo con `require "rails_helper"` y el bloque describe):

```ruby
  describe ".publicly_visible" do
    it "incluye solo iglesias con página habilitada y activas" do
      visible = create(:church, public_page_enabled: true, status: "active")
      create(:church, public_page_enabled: false, status: "active")
      create(:church, public_page_enabled: true, status: "inactive")

      expect(Church.publicly_visible).to contain_exactly(visible)
    end
  end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec spec/models/church_spec.rb -e "publicly_visible"
```
Expected: FAIL — `undefined method 'publicly_visible'`.

- [ ] **Step 3: Agregar el scope**

En `app/models/church.rb`, después de la línea `enum :status, ...`, agregar:

```ruby
  scope :publicly_visible, -> { where(public_page_enabled: true, status: "active") }
```

- [ ] **Step 4: Ejecutar y verificar que pasa**

```bash
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec spec/models/church_spec.rb -e "publicly_visible"
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/models/church.rb spec/models/church_spec.rb
git commit -m "feat: scope Church.publicly_visible"
```

---

## Task 2: Ruta, controlador base y `Public::ChurchesController#show`

**Files:**
- Create: `app/controllers/public/base_controller.rb`
- Create: `app/controllers/public/churches_controller.rb`
- Modify: `config/routes.rb`
- Test: `spec/requests/public/churches_spec.rb`

- [ ] **Step 1: Escribir los specs de visibilidad/acceso**

Crear `spec/requests/public/churches_spec.rb`:

```ruby
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
end
```

Nota: la factory `:church` puede generar slug nil por defecto; en estos tests se pasa `slug:` explícito, así que no hay colisión.

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec spec/requests/public/churches_spec.rb
```
Expected: FAIL — ruta no existe (404 en todos, o error de routing).

- [ ] **Step 3: Crear `Public::BaseController`**

Crear `app/controllers/public/base_controller.rb`:

```ruby
module Public
  class BaseController < ApplicationController
    layout "public"

    # Página pública: sin autenticación y sin Pundit.
    skip_before_action :authenticate_user!, raise: false
    skip_after_action :verify_authorized, raise: false
    skip_after_action :verify_policy_scoped, raise: false
  end
end
```

Nota: `ApplicationController` no declara `authenticate_user!` globalmente, por eso
`raise: false` evita error si el filtro no existe. Los `skip_after_action` con
`raise: false` son seguros aunque la condición lambda ya los limite.

- [ ] **Step 4: Crear `Public::ChurchesController`**

Crear `app/controllers/public/churches_controller.rb`:

```ruby
module Public
  class ChurchesController < BaseController
    def show
      @church = Church.publicly_visible.find_by(slug: params[:slug].to_s.downcase)
      raise ActiveRecord::RecordNotFound if @church.nil?

      @service_times = @church.church_service_times.active.ordered
    end
  end
end
```

- [ ] **Step 5: Agregar la ruta**

En `config/routes.rb`, justo después de `root "home#index"`, agregar:

```ruby
  get "/c/:slug", to: "public/churches#show", as: :public_church
```

- [ ] **Step 6: Crear un layout y vista mínimos para que responda**

Para que los specs de visibilidad pasen ya (la vista completa se hace en Task 3),
crear `app/views/layouts/public.html.erb`:

```erb
<!DOCTYPE html>
<html lang="es">
  <head>
    <title><%= content_for(:title) || "Igle Org" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
  </head>
  <body class="min-h-screen bg-slate-50 text-slate-950 antialiased">
    <main><%= yield %></main>
  </body>
</html>
```

Y `app/views/public/churches/show.html.erb` (versión mínima, se enriquece en Task 3):

```erb
<% content_for :title, @church.name %>
<section class="mx-auto w-full max-w-3xl px-6 py-12">
  <h1 class="text-3xl font-semibold"><%= @church.name %></h1>
</section>
```

- [ ] **Step 7: Ejecutar y verificar que pasa**

```bash
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec spec/requests/public/churches_spec.rb
```
Expected: PASS (6 examples).

- [ ] **Step 8: Commit**

```bash
git add app/controllers/public/ config/routes.rb app/views/layouts/public.html.erb app/views/public/ spec/requests/public/churches_spec.rb
git commit -m "feat: ruta y controlador público de iglesia en /c/:slug"
```

---

## Task 3: Vista pública completa (contenido + privacidad)

**Files:**
- Modify: `app/views/public/churches/show.html.erb`
- Test: `spec/requests/public/churches_spec.rb` (agregar casos de contenido y privacidad)

- [ ] **Step 1: Agregar specs de contenido y privacidad**

Agregar al final del `RSpec.describe` en `spec/requests/public/churches_spec.rb`:

```ruby
  describe "contenido" do
    it "muestra descripción y horarios de culto activos, pero no los inactivos" do
      church = create(:church, name: "Iglesia Central", slug: "central",
                      description: "Una iglesia para la familia",
                      public_page_enabled: true, status: "active")
      create(:church_service_time, church:, name: "Culto dominical",
             day_of_week: 0, starts_at: "10:00", ends_at: "12:00",
             location: "Templo", status: "active")
      create(:church_service_time, church:, name: "Reunión interna oculta",
             day_of_week: 3, starts_at: "19:00", ends_at: "20:00", status: "inactive")

      get "/c/central"

      expect(response.body).to include("Una iglesia para la familia")
      expect(response.body).to include("Culto dominical")
      expect(response.body).to include("Templo")
      expect(response.body).not_to include("Reunión interna oculta")
    end

    it "no expone datos sensibles ni notas de horarios" do
      church = create(:church, name: "Iglesia Central", slug: "central",
                      phone: "555-1234", email: "secreto@iglesia.test",
                      address_line_1: "Calle Privada 123",
                      public_page_enabled: true, status: "active")
      create(:church_service_time, church:, name: "Culto", day_of_week: 0,
             starts_at: "10:00", ends_at: "12:00", notes: "Nota interna confidencial",
             status: "active")
      member = create(:member, church:, first_name: "MiembroPrivado")

      get "/c/central"

      expect(response.body).not_to include("555-1234")
      expect(response.body).not_to include("secreto@iglesia.test")
      expect(response.body).not_to include("Calle Privada 123")
      expect(response.body).not_to include("Nota interna confidencial")
      expect(response.body).not_to include(member.full_name)
    end
  end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec spec/requests/public/churches_spec.rb -e "contenido"
```
Expected: FAIL — la vista mínima no incluye descripción ni horarios (el test de descripción falla; el de privacidad podría pasar trivialmente, está bien).

- [ ] **Step 3: Reemplazar la vista con la versión completa**

Reemplazar `app/views/public/churches/show.html.erb` con:

```erb
<% content_for :title, @church.name %>
<%
  primary = @church.primary_color.presence
  primary = "##{primary}" if primary && !primary.start_with?("#")
  accent = primary || "#0f172a"
%>

<section class="mx-auto w-full max-w-3xl px-6 py-12">
  <header class="flex flex-col items-center text-center">
    <% if @church.logo.attached? %>
      <%= image_tag @church.logo.variant(resize_to_limit: [ 200, 200 ]).processed,
            alt: @church.name, class: "mb-6 h-28 w-28 rounded-full object-cover shadow" %>
    <% end %>
    <h1 class="text-4xl font-semibold" style="color: <%= accent %>;"><%= @church.name %></h1>
    <% if @church.description.present? %>
      <p class="mt-4 max-w-2xl text-base leading-relaxed text-slate-600"><%= @church.description %></p>
    <% end %>
  </header>

  <% if @service_times.any? %>
    <section class="mt-12">
      <h2 class="text-lg font-semibold" style="color: <%= accent %>;">Horarios de culto</h2>
      <ul class="mt-4 divide-y divide-slate-200 rounded-lg border border-slate-200 bg-white">
        <% @service_times.each do |service_time| %>
          <li class="flex flex-wrap items-baseline justify-between gap-2 px-4 py-3">
            <span class="font-medium text-slate-900">
              <%= service_time.day_name %> — <%= service_time.name %>
            </span>
            <span class="text-sm text-slate-600">
              <%= service_time.starts_at.strftime("%H:%M") %><% if service_time.ends_at.present? %>–<%= service_time.ends_at.strftime("%H:%M") %><% end %>
              <% if service_time.location.present? %>· <%= service_time.location %><% end %>
            </span>
          </li>
        <% end %>
      </ul>
    </section>
  <% end %>
</section>
```

Nota de privacidad: la vista referencia únicamente `name`, `logo`, `description`,
`primary_color`, y de cada horario `day_name`/`name`/`starts_at`/`ends_at`/`location`.
NO referencia `notes`, teléfono, email, dirección, ni datos de miembros.

- [ ] **Step 4: Ejecutar y verificar que pasa**

```bash
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec spec/requests/public/churches_spec.rb
```
Expected: PASS (todos los examples).

- [ ] **Step 5: Commit**

```bash
git add app/views/public/churches/show.html.erb spec/requests/public/churches_spec.rb
git commit -m "feat: contenido de la página pública (logo, descripción, colores, horarios)"
```

---

## Task 4: Verificación final

- [ ] **Step 1: Suite completa en Docker**

```bash
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec --format progress 2>&1 | tail -6
```
Expected: 0 failures.

- [ ] **Step 2: RuboCop sobre archivos nuevos**

```bash
docker compose exec -T web bin/rubocop app/controllers/public/ app/models/church.rb
```
Expected: no offenses (corregir con `bin/rubocop -a` si hay de estilo y re-correr).

- [ ] **Step 3: Brakeman**

```bash
docker compose exec -T web bin/brakeman -q --no-pager 2>&1 | grep -E "Security Warnings|No warnings"
```
Expected: 0 security warnings.

- [ ] **Step 4: Commit de correcciones de estilo (si aplica)**

```bash
git add -A
git commit -m "style: rubocop fixes en página pública"
```
