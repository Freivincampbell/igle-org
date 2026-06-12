# Eventos en la página pública (PR 1 de 3) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar los eventos con `visibility: public` en la página pública de la iglesia (`/c/:slug`) con página de detalle por evento, contador de confirmados y cupos.

**Architecture:** Fase A del spec [2026-06-11-events-public-flow-design.md](../specs/2026-06-11-events-public-flow-design.md). Solo lectura: un controller público nuevo (`Public::EventsController`) que reutiliza la resolución de iglesia por slug de `Public::ChurchesController` (se extrae a `Public::BaseController`), una sección nueva en la vista pública de iglesia y una vista de detalle. Sin migraciones, sin permisos nuevos (lo público no usa Pundit — el `BaseController` ya hace skip).

**Tech Stack:** Rails 8.1, ERB + Tailwind (layout `public` existente), RSpec request specs.

**Comandos:** en esta máquina `bundle` debe correr con el Ruby de mise:
`~/.local/share/mise/installs/ruby/3.4.9/bin/bundle exec rspec ...`
(abajo se abrevia como `bundle exec`).

**Reglas del proyecto que aplican aquí:**
- URLs públicas SIEMPRE con `public_id`, nunca `id` interno.
- Nada de datos de miembros en vistas públicas (ni nombres de confirmados, ni responsable).
- Todo spec nuevo de la parte pública debe incluir un caso de aislamiento con dos iglesias.

---

### Task 1: Ruta + controller `Public::EventsController#show` (TDD)

**Files:**
- Create: `spec/requests/public/events_spec.rb`
- Create: `app/controllers/public/events_controller.rb`
- Create: `app/views/public/events/show.html.erb` (mínima en esta task; se completa en Task 3)
- Modify: `config/routes.rb:5` (agregar scope público)

- [ ] **Step 1: Escribir los request specs que fallan**

Crear `spec/requests/public/events_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Public event page" do
  def public_church(slug: "central")
    create(:church, slug:, public_page_enabled: true, status: "active")
  end

  it "muestra un evento público de una iglesia habilitada, sin autenticación" do
    church = public_church
    event = create(:event, church:, visibility: "public", title: "Concierto de adoración")

    get "/c/#{church.slug}/eventos/#{event.public_id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Concierto de adoración")
  end

  it "404 cuando el evento es members_only" do
    church = public_church
    event = create(:event, church:, visibility: "members_only")

    get "/c/#{church.slug}/eventos/#{event.public_id}"

    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando el evento es private" do
    church = public_church
    event = create(:event, church:, visibility: "private")

    get "/c/#{church.slug}/eventos/#{event.public_id}"

    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando la página pública está deshabilitada" do
    church = create(:church, slug: "central", public_page_enabled: false, status: "active")
    event = create(:event, church:, visibility: "public")

    get "/c/central/eventos/#{event.public_id}"

    expect(response).to have_http_status(:not_found)
  end

  it "404 cuando el evento pertenece a otra iglesia (aislamiento)" do
    church_a = public_church(slug: "iglesia-a")
    church_b = public_church(slug: "iglesia-b")
    event_b = create(:event, church: church_b, visibility: "public")

    get "/c/#{church_a.slug}/eventos/#{event_b.public_id}"

    expect(response).to have_http_status(:not_found)
  end

  it "no resuelve ids internos de la base" do
    church = public_church
    event = create(:event, church:, visibility: "public")

    get "/c/#{church.slug}/eventos/#{event.id}"

    expect(response).to have_http_status(:not_found)
  end
end
```

- [ ] **Step 2: Correr los specs y verificar que fallan**

Run: `bundle exec rspec spec/requests/public/events_spec.rb`
Expected: FAIL — `ActionController::RoutingError` o similar (la ruta no existe).

- [ ] **Step 3: Agregar la ruta**

En `config/routes.rb`, debajo de la línea `get "/c/:slug", to: "public/churches#show", as: :public_church`:

```ruby
scope "/c/:slug", module: :public, as: :public_church do
  resources :events, path: "eventos", param: :public_id, only: :show
end
```

Genera el helper `public_church_event_path(slug, event)` → `/c/:slug/eventos/:public_id`.

- [ ] **Step 4: Crear el controller**

Crear `app/controllers/public/events_controller.rb`:

```ruby
module Public
  class EventsController < BaseController
    def show
      @church = Church.publicly_visible.find_by(slug: params[:slug].to_s.downcase)
      raise ActiveRecord::RecordNotFound if @church.nil?

      @event = @church.events.visibility_public.find_by_public_id!(params[:public_id])
    end
  end
end
```

Notas: `visibility_public` es el scope del enum con prefijo (`enum :visibility, ..., prefix: :visibility`). `find_by_public_id!` viene de `PublicIdentifiable` y lanza `RecordNotFound` con ids internos. El detalle muestra cualquier estado (`scheduled`/`cancelled`/`completed`) — un link compartido nunca debe dar 404 porque el evento se canceló; el badge de estado se agrega en Task 3.

- [ ] **Step 5: Crear la vista mínima**

Crear `app/views/public/events/show.html.erb`:

```erb
<% content_for :title, "#{@event.title} — #{@church.name}" %>
<section class="mx-auto w-full max-w-3xl px-6 py-12">
  <h1 class="text-3xl font-bold text-slate-900"><%= @event.title %></h1>
</section>
```

- [ ] **Step 6: Correr los specs y verificar que pasan**

Run: `bundle exec rspec spec/requests/public/events_spec.rb`
Expected: 6 examples, 0 failures

- [ ] **Step 7: Commit**

```bash
git add config/routes.rb app/controllers/public/events_controller.rb app/views/public/events/show.html.erb spec/requests/public/events_spec.rb
git commit -m "feat: página pública de detalle de evento por public_id"
```

---

### Task 2: Extraer la resolución de iglesia por slug a `Public::BaseController`

`Public::ChurchesController#show` y el controller nuevo duplican la resolución por slug. Se extrae sin cambiar comportamiento (los specs existentes de ambos cubren la regresión).

**Files:**
- Modify: `app/controllers/public/base_controller.rb`
- Modify: `app/controllers/public/churches_controller.rb`
- Modify: `app/controllers/public/events_controller.rb`

- [ ] **Step 1: Agregar el método al base controller**

`app/controllers/public/base_controller.rb` queda:

```ruby
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
```

- [ ] **Step 2: Usarlo en ambos controllers**

`app/controllers/public/churches_controller.rb`:

```ruby
module Public
  class ChurchesController < BaseController
    def show
      resolve_public_church!

      @service_times = @church.church_service_times.active.ordered
    end
  end
end
```

`app/controllers/public/events_controller.rb`:

```ruby
module Public
  class EventsController < BaseController
    def show
      resolve_public_church!

      @event = @church.events.visibility_public.find_by_public_id!(params[:public_id])
    end
  end
end
```

- [ ] **Step 3: Correr los specs públicos**

Run: `bundle exec rspec spec/requests/public/`
Expected: todos verdes (los de churches existentes + los de events de Task 1).

- [ ] **Step 4: Commit**

```bash
git add app/controllers/public/
git commit -m "refactor: resolución de iglesia pública por slug en Public::BaseController"
```

---

### Task 3: Vista de detalle completa (fecha, lugar, estado, confirmados, cupos)

**Files:**
- Modify: `spec/requests/public/events_spec.rb` (agregar specs de contenido)
- Modify: `app/views/public/events/show.html.erb`

- [ ] **Step 1: Agregar specs de contenido que fallan**

Agregar al final del `RSpec.describe` en `spec/requests/public/events_spec.rb`:

```ruby
  it "muestra confirmados, cupos restantes y datos del evento sin datos de miembros" do
    church = public_church
    event = create(:event, church:, visibility: "public", capacity: 50, location: "Salón principal")
    member = create(:member, church:, first_name: "Wilson", last_name: "Segura")
    create(:event_rsvp, church:, event:, member:, status: "attending", guests_count: 2)

    get "/c/#{church.slug}/eventos/#{event.public_id}"

    expect(response.body).to include("3")                  # 1 miembro + 2 acompañantes
    expect(response.body).to include("47")                 # 50 - 3 cupos restantes
    expect(response.body).to include("Salón principal")
    expect(response.body).not_to include("Wilson")         # nunca nombres de miembros
  end

  it "muestra el badge de cancelado en un evento cancelado" do
    church = public_church
    event = create(:event, church:, visibility: "public", status: "cancelled")

    get "/c/#{church.slug}/eventos/#{event.public_id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cancelado")
  end
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `bundle exec rspec spec/requests/public/events_spec.rb`
Expected: FAIL los 2 nuevos (la vista mínima no muestra esos datos).

- [ ] **Step 3: Completar la vista**

`app/views/public/events/show.html.erb` queda:

```erb
<% content_for :title, "#{@event.title} — #{@church.name}" %>
<%
  primary = @church.primary_color.presence
  primary = "##{primary}" if primary && !primary.start_with?("#")
  accent = primary || "#7c3aed"
%>

<section class="mx-auto w-full max-w-3xl px-6 py-12">
  <p class="text-xs font-semibold uppercase tracking-widest" style="color: <%= accent %>;">
    <%= link_to @church.name, public_church_path(@church.slug), class: "hover:underline" %>
  </p>
  <h1 class="mt-2 text-3xl font-bold text-slate-900"><%= @event.title %></h1>

  <div class="mt-3 flex flex-wrap items-center gap-2">
    <span class="inline-flex rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-semibold text-slate-600 ring-1 ring-slate-200"><%= event_type_label(@event.event_type) %></span>
    <% if @event.cancelled? %>
      <span class="inline-flex rounded-full bg-red-50 px-2.5 py-0.5 text-xs font-semibold text-red-700 ring-1 ring-red-200">Cancelado</span>
    <% elsif @event.completed? %>
      <span class="inline-flex rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-semibold text-slate-600 ring-1 ring-slate-200">Finalizado</span>
    <% end %>
  </div>

  <div class="mt-8 rounded-xl border border-slate-200 bg-white p-6 shadow-card">
    <dl class="grid gap-4 sm:grid-cols-2">
      <div>
        <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Fecha y hora</dt>
        <dd class="mt-1 text-sm font-semibold text-slate-900">
          <%= l(@event.starts_at, format: :default) %><% if @event.ends_at.present? %> — <%= l(@event.ends_at, format: :default) %><% end %>
        </dd>
      </div>
      <% if @event.location.present? %>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Lugar</dt>
          <dd class="mt-1 text-sm font-semibold text-slate-900"><%= @event.location %></dd>
        </div>
      <% end %>
      <div>
        <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Confirmados</dt>
        <dd class="mt-1 text-sm font-semibold text-slate-900"><%= @event.confirmed_attendees_count %></dd>
      </div>
      <% if @event.capacity.present? %>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Cupos disponibles</dt>
          <dd class="mt-1 text-sm font-semibold text-slate-900"><%= [ @event.capacity - @event.confirmed_attendees_count, 0 ].max %></dd>
        </div>
      <% end %>
    </dl>

    <% if @event.description.present? %>
      <div class="mt-6 border-t border-slate-100 pt-6 text-sm leading-relaxed text-slate-600">
        <%= simple_format(@event.description) %>
      </div>
    <% end %>
  </div>
</section>
```

Nota: la vista NO muestra `responsible_member`, RSVPs por nombre ni ningún dato de personas — regla de datos sensibles.

- [ ] **Step 4: Correr y verificar que pasan**

Run: `bundle exec rspec spec/requests/public/events_spec.rb`
Expected: 8 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add app/views/public/events/show.html.erb spec/requests/public/events_spec.rb
git commit -m "feat: detalle público de evento con confirmados, cupos y badge de estado"
```

---

### Task 4: Sección "Próximos eventos" en la página pública de la iglesia

**Files:**
- Modify: `spec/requests/public/churches_spec.rb` (agregar specs)
- Modify: `app/controllers/public/churches_controller.rb`
- Modify: `app/views/public/churches/show.html.erb`

- [ ] **Step 1: Agregar specs que fallan**

Agregar al final del `RSpec.describe "Public church page"` en `spec/requests/public/churches_spec.rb`:

```ruby
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
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `bundle exec rspec spec/requests/public/churches_spec.rb`
Expected: FAIL el spec nuevo.

- [ ] **Step 3: Cargar los eventos en el controller**

`app/controllers/public/churches_controller.rb`:

```ruby
module Public
  class ChurchesController < BaseController
    UPCOMING_EVENTS_LIMIT = 6

    def show
      resolve_public_church!

      @service_times = @church.church_service_times.active.ordered
      @upcoming_events = @church.events
        .visibility_public
        .where(status: "scheduled")
        .upcoming
        .limit(UPCOMING_EVENTS_LIMIT)
    end
  end
end
```

- [ ] **Step 4: Agregar la sección a la vista**

En `app/views/public/churches/show.html.erb`, después del `<% end %>` que cierra la sección de horarios (línea 39) y antes del `</section>` final:

```erb
  <% if @upcoming_events.any? %>
    <section class="mt-12">
      <h2 class="mb-4 text-xs font-semibold uppercase tracking-widest" style="color: <%= accent %>;">Próximos eventos</h2>
      <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-card">
        <ul class="divide-y divide-slate-200">
          <% @upcoming_events.each do |event| %>
            <li>
              <%= link_to public_church_event_path(@church.slug, event),
                    class: "flex flex-wrap items-baseline justify-between gap-2 px-5 py-4 hover:bg-slate-50 transition-colors" do %>
                <span class="font-medium text-slate-900"><%= event.title %></span>
                <span class="text-sm text-slate-500">
                  <%= l(event.starts_at, format: :default) %>
                  <% if event.location.present? %>· <%= event.location %><% end %>
                </span>
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>
    </section>
  <% end %>
```

- [ ] **Step 5: Correr y verificar que pasan**

Run: `bundle exec rspec spec/requests/public/`
Expected: todos verdes.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/public/churches_controller.rb app/views/public/churches/show.html.erb spec/requests/public/churches_spec.rb
git commit -m "feat: próximos eventos públicos en la página pública de la iglesia"
```

---

### Task 5: Tildes en etiquetas i18n de eventos

Mismo criterio que el fix de "Líder"/"Co-líder": copy correcto en español.

**Files:**
- Modify: `config/locales/es.yml` (bloque `events:` ~línea 328)

- [ ] **Step 1: Corregir las etiquetas**

En `config/locales/es.yml`, dentro de `events:`:

```yaml
    event_types:
      ministry_meeting: "Reunión de ministerio"   # antes "Reunion de ministerio"
    visibilities:
      public: "Público"                           # antes "Publico"
```

(el resto de claves del bloque no cambia)

- [ ] **Step 2: Verificar que nada dependía del texto sin tilde**

Run: `grep -rn "Publico\|Reunion de ministerio" app/ spec/ config/`
Expected: sin resultados fuera de `es.yml` (y tras el edit, ninguno).

- [ ] **Step 3: Commit**

```bash
git add config/locales/es.yml
git commit -m "fix: tildes en etiquetas i18n de eventos"
```

---

### Task 6: Verificación final del PR

- [ ] **Step 1: Suite completa**

Run: `bundle exec rspec`
Expected: 0 failures (328 ejemplos previos + ~8 nuevos).

- [ ] **Step 2: Estilo y seguridad**

Run: `bundle exec rubocop`
Expected: no offenses.

Run: `bundle exec brakeman --no-pager`
Expected: 0 security warnings (igual que el baseline).

- [ ] **Step 3: Verificación visual (manual)**

Con `bin/dev` y una iglesia con `public_page_enabled: true` y eventos seed:
- `/c/<slug>` muestra la sección "Próximos eventos" solo con públicos futuros.
- El detalle del evento muestra confirmados/cupos y no muestra nombres de personas.

---

## Fuera de este PR

- **PR 2 (Fases B+C):** tabla `event_guest_rsvps`, servicio `Events::GuestRsvp`, formulario público de RSVP con honeypot+throttle, edición por `access_token`, `confirmed_attendees_count` sumando invitados y panel de conteo en el admin. Su plan se escribe cuando este PR aterrice.
- **PR 3 (Fase D):** `occurrence_date` + walk-ins en `event_attendances`, modo check-in Turbo y reporte de cruce RSVP vs asistencia.
