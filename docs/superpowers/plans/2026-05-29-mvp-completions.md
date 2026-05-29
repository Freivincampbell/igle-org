# MVP Completions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completar las 6 funcionalidades MVP faltantes en igle-org: auditoría con paper_trail, foto de miembro, portal de miembro con eventos/RSVP, namespace MinistryLeader, vista de miembros para pastores, y dashboard de iglesia.

**Architecture:** Rails 8 multi-tenant. Cada feature respeta el aislamiento por `church_id`, usa `public_id` en rutas, y delega autorización en `Permissions::PermissionChecker` vía Pundit. Nuevos namespaces siguen el patrón `ChurchAdmin::BaseController` para resolver iglesia y membresía actual.

**Tech Stack:** Ruby 3.4, Rails 8.1, Pundit, paper_trail, Active Storage, Tailwind CSS, Turbo, RSpec/FactoryBot.

**Branch:** `mvp-completions`

---

## Archivos por feature

### Feature 1 — paper_trail en modelos
- Modify: `app/models/member.rb` — agregar `has_paper_trail`
- Modify: `app/models/role.rb`
- Modify: `app/models/role_permission.rb`
- Modify: `app/models/membership_role.rb`
- Modify: `app/models/church_membership.rb`
- Modify: `app/models/board_member.rb`
- Modify: `app/models/pastoral_note.rb`
- Modify: `app/models/profile_change_request.rb`

### Feature 2 — Foto de miembro
- Modify: `app/models/member.rb` — `has_one_attached :photo`
- Modify: `app/controllers/church_admin/members_controller.rb` — permitir `:photo`
- Modify: `app/views/church_admin/members/_form.html.erb` — campo upload
- Modify: `app/views/church_admin/members/show.html.erb` — mostrar foto
- Modify: `app/views/member_portal/profiles/show.html.erb` — mostrar foto

### Feature 3 — Portal de miembro: Eventos + RSVP
- Create: `app/controllers/member_portal/events_controller.rb`
- Create: `app/views/member_portal/events/index.html.erb`
- Create: `app/views/member_portal/events/show.html.erb`
- Modify: `config/routes.rb` — rutas de portal eventos

### Feature 4 — MinistryLeader namespace
- Create: `app/controllers/ministry_leader/base_controller.rb`
- Create: `app/controllers/ministry_leader/ministries_controller.rb`
- Create: `app/controllers/ministry_leader/events_controller.rb`
- Create: `app/views/ministry_leader/ministries/index.html.erb`
- Create: `app/views/ministry_leader/ministries/show.html.erb`
- Create: `app/views/ministry_leader/events/index.html.erb`
- Create: `app/views/ministry_leader/events/show.html.erb`
- Modify: `config/routes.rb` — rutas de ministry_leader

### Feature 5 — Pastor::MembersController
- Create: `app/controllers/pastor/members_controller.rb`
- Create: `app/views/pastor/members/index.html.erb`
- Create: `app/views/pastor/members/show.html.erb`
- Modify: `config/routes.rb` — rutas de pastor members

### Feature 6 — Dashboard de iglesia
- Create: `app/controllers/church_admin/dashboard_controller.rb`
- Create: `app/views/church_admin/dashboard/index.html.erb`
- Modify: `config/routes.rb` — cambiar root a dashboard

---

## Task 1: paper_trail en modelos auditables

**Files:**
- Modify: `app/models/member.rb`
- Modify: `app/models/role.rb`
- Modify: `app/models/role_permission.rb`
- Modify: `app/models/membership_role.rb`
- Modify: `app/models/church_membership.rb`
- Modify: `app/models/board_member.rb`
- Modify: `app/models/pastoral_note.rb`
- Modify: `app/models/profile_change_request.rb`

- [ ] **Step 1: Agregar has_paper_trail a Member**

En `app/models/member.rb`, después de `include PublicIdentifiable` agregar:
```ruby
has_paper_trail skip: %i[updated_at]
```

- [ ] **Step 2: Agregar has_paper_trail a Role**

En `app/models/role.rb`, después de `include PublicIdentifiable`:
```ruby
has_paper_trail skip: %i[updated_at]
```

- [ ] **Step 3: Agregar has_paper_trail a RolePermission**

En `app/models/role_permission.rb`, después de `include PublicIdentifiable`:
```ruby
has_paper_trail skip: %i[updated_at]
```

- [ ] **Step 4: Agregar has_paper_trail a MembershipRole**

En `app/models/membership_role.rb`, después de `include PublicIdentifiable`:
```ruby
has_paper_trail skip: %i[updated_at]
```

- [ ] **Step 5: Agregar has_paper_trail a ChurchMembership**

En `app/models/church_membership.rb`, después de `include PublicIdentifiable`:
```ruby
has_paper_trail skip: %i[updated_at]
```

- [ ] **Step 6: Agregar has_paper_trail a BoardMember**

En `app/models/board_member.rb`, después de `include PublicIdentifiable`:
```ruby
has_paper_trail skip: %i[updated_at]
```

- [ ] **Step 7: Agregar has_paper_trail a PastoralNote**

En `app/models/pastoral_note.rb`, después de `include PublicIdentifiable`:
```ruby
has_paper_trail skip: %i[updated_at]
```

- [ ] **Step 8: Agregar has_paper_trail a ProfileChangeRequest**

En `app/models/profile_change_request.rb`, después de `include PublicIdentifiable`:
```ruby
has_paper_trail skip: %i[updated_at]
```

- [ ] **Step 9: Verificar que la tabla versions existe**

```bash
docker compose exec web bin/rails runner "puts PaperTrail::Version.count"
```
Expected: número (0 o más)

- [ ] **Step 10: Commit**

```bash
git add app/models/member.rb app/models/role.rb app/models/role_permission.rb \
  app/models/membership_role.rb app/models/church_membership.rb \
  app/models/board_member.rb app/models/pastoral_note.rb app/models/profile_change_request.rb
git commit -m "feat: agregar auditoría paper_trail a modelos auditables"
```

---

## Task 2: Foto de miembro

**Files:**
- Modify: `app/models/member.rb`
- Modify: `app/controllers/church_admin/members_controller.rb`
- Modify: `app/views/church_admin/members/_form.html.erb`
- Modify: `app/views/church_admin/members/show.html.erb`
- Modify: `app/views/member_portal/profiles/show.html.erb`

- [ ] **Step 1: Agregar has_one_attached :photo a Member**

En `app/models/member.rb`, después de `include PublicIdentifiable` (antes de belongs_to):
```ruby
has_one_attached :photo
```

- [ ] **Step 2: Permitir :photo en member_params**

En `app/controllers/church_admin/members_controller.rb`, agregar `:photo` al final de la lista de `member_params`:
```ruby
def member_params
  params.require(:member).permit(
    :user_id,
    :first_name,
    :middle_name,
    :last_name,
    :second_last_name,
    :email,
    :phone,
    :secondary_phone,
    :birth_date,
    :gender,
    :marital_status,
    :children_count,
    :baptized_on,
    :official_membership_on,
    :member_status,
    :address_line_1,
    :address_line_2,
    :city,
    :state,
    :postal_code,
    :country,
    :emergency_contact_name,
    :emergency_contact_phone,
    :notes,
    :photo
  )
end
```

- [ ] **Step 3: Agregar campo de foto al formulario**

En `app/views/church_admin/members/_form.html.erb`, al inicio del form, después del bloque de errores y antes de la primera `<section>`:
```erb
  <section class="mb-6">
    <h2 class="text-lg font-semibold text-slate-950">Foto</h2>
    <div class="mt-4 flex items-center gap-6">
      <% if member.photo.attached? %>
        <%= image_tag member.photo.variant(resize_to_fill: [96, 96]).processed,
              class: "h-24 w-24 rounded-full object-cover border border-slate-200" %>
      <% else %>
        <div class="flex h-24 w-24 items-center justify-center rounded-full bg-slate-100 text-slate-400 text-3xl font-semibold">
          <%= member.first_name&.first&.upcase %>
        </div>
      <% end %>
      <div>
        <%= form.label :photo, "Foto de perfil", class: "block text-sm font-medium text-slate-700" %>
        <%= form.file_field :photo, accept: "image/*", class: "mt-2 block text-sm text-slate-600 file:mr-4 file:rounded-md file:border-0 file:bg-slate-950 file:px-3 file:py-2 file:text-sm file:font-medium file:text-white hover:file:bg-slate-800" %>
      </div>
    </div>
  </section>
```

- [ ] **Step 4: Mostrar foto en member show**

En `app/views/church_admin/members/show.html.erb`, dentro del bloque del encabezado (antes o después del `<h1>`), agregar la foto:
```erb
    <div class="flex items-center gap-6">
      <% if @member.photo.attached? %>
        <%= image_tag @member.photo.variant(resize_to_fill: [80, 80]).processed,
              class: "h-20 w-20 rounded-full object-cover border border-slate-200" %>
      <% else %>
        <div class="flex h-20 w-20 items-center justify-center rounded-full bg-slate-100 text-slate-400 text-2xl font-semibold">
          <%= @member.first_name&.first&.upcase %>
        </div>
      <% end %>
      <div>
        <h1 class="text-3xl font-semibold text-slate-950"><%= @member.full_name %></h1>
        <p class="mt-1 text-sm text-slate-500"><%= @member.public_id %></p>
      </div>
    </div>
```

(Reemplaza el `<h1>` y `<p>` existentes.)

- [ ] **Step 5: Mostrar foto en portal de miembro**

En `app/views/member_portal/profiles/show.html.erb`, después del `<h1>Mi perfil</h1>`, agregar:
```erb
  <% if @member.photo.attached? %>
    <div class="mt-4">
      <%= image_tag @member.photo.variant(resize_to_fill: [80, 80]).processed,
            class: "h-20 w-20 rounded-full object-cover border border-slate-200" %>
    </div>
  <% end %>
```

- [ ] **Step 6: Verificar que Active Storage funciona**

```bash
docker compose exec web bin/rails runner "puts ActiveStorage::Blob.table_exists?"
```
Expected: `true`

- [ ] **Step 7: Commit**

```bash
git add app/models/member.rb \
  app/controllers/church_admin/members_controller.rb \
  app/views/church_admin/members/_form.html.erb \
  app/views/church_admin/members/show.html.erb \
  app/views/member_portal/profiles/show.html.erb
git commit -m "feat: agregar foto de perfil a miembros con Active Storage"
```

---

## Task 3: Portal de miembro — Eventos y RSVP

**Files:**
- Create: `app/controllers/member_portal/events_controller.rb`
- Create: `app/views/member_portal/events/index.html.erb`
- Create: `app/views/member_portal/events/show.html.erb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Crear MemberPortal::EventsController**

Crear `app/controllers/member_portal/events_controller.rb`:
```ruby
module MemberPortal
  class EventsController < BaseController
    before_action :set_event, only: %i[show rsvp]

    def index
      @events = @church.events
        .where(status: %w[scheduled completed])
        .where(visibility: %w[public members_only])
        .upcoming
        .includes(:ministry)

      @my_rsvps = current_member ? EventRsvp.where(member: current_member, event: @events).index_by(&:event_id) : {}
    end

    def show
      @rsvp = current_member ? EventRsvp.find_or_initialize_by(member: current_member, event: @event, church: @church) : nil
    end

    def rsvp
      return redirect_to church_member_portal_event_path(@church, @event), alert: "Debes tener perfil de miembro para confirmar asistencia." unless current_member

      @rsvp = EventRsvp.find_or_initialize_by(member: current_member, event: @event, church: @church)
      @rsvp.assign_attributes(rsvp_params)

      if @rsvp.save
        redirect_to church_member_portal_event_path(@church, @event), notice: "Confirmación actualizada."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_event
      @event = @church.events
        .where(visibility: %w[public members_only])
        .find_by_public_id!(params[:public_id])
    end

    def rsvp_params
      params.require(:event_rsvp).permit(:status, :guests_count)
    end
  end
end
```

- [ ] **Step 2: Crear vista index de eventos del portal**

Crear `app/views/member_portal/events/index.html.erb`:
```erb
<section class="mx-auto w-full max-w-3xl px-6 py-10">
  <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
    <div>
      <p class="text-sm font-medium text-slate-500"><%= @church.name %></p>
      <h1 class="mt-2 text-3xl font-semibold text-slate-950">Eventos</h1>
    </div>
    <%= link_to "Mi perfil", church_member_portal_profile_path(@church), class: "text-sm font-medium text-slate-600 hover:text-slate-950" %>
  </div>

  <div class="mt-8 space-y-4">
    <% if @events.any? %>
      <% @events.each do |event| %>
        <% my_rsvp = @my_rsvps[event.id] %>
        <article class="rounded-lg border border-slate-200 bg-white p-5">
          <div class="flex items-start justify-between gap-4">
            <div>
              <h2 class="font-semibold text-slate-950">
                <%= link_to event.title, church_member_portal_event_path(@church, event), class: "hover:underline" %>
              </h2>
              <p class="mt-1 text-sm text-slate-500">
                <%= l(event.starts_at, format: :default) %>
                <% if event.location.present? %> · <%= event.location %><% end %>
              </p>
              <% if event.ministry %><p class="mt-1 text-xs text-slate-400"><%= event.ministry.name %></p><% end %>
            </div>
            <% if my_rsvp&.persisted? %>
              <span class="shrink-0 rounded-full px-2 py-1 text-xs font-medium <%= my_rsvp.attending? ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-600' %>">
                <%= my_rsvp.attending? ? "Confirmaré asistencia" : "No asistiré" %>
              </span>
            <% end %>
          </div>
        </article>
      <% end %>
    <% else %>
      <div class="rounded-lg border border-slate-200 bg-white px-6 py-12 text-center text-slate-500">
        No hay eventos próximos.
      </div>
    <% end %>
  </div>
</section>
```

- [ ] **Step 3: Crear vista show de evento del portal**

Crear `app/views/member_portal/events/show.html.erb`:
```erb
<section class="mx-auto w-full max-w-3xl px-6 py-10">
  <div class="mb-6">
    <%= link_to "← Volver a eventos", church_member_portal_events_path(@church), class: "text-sm text-slate-600 hover:text-slate-950" %>
  </div>

  <h1 class="text-3xl font-semibold text-slate-950"><%= @event.title %></h1>
  <p class="mt-2 text-sm text-slate-500">
    <%= l(@event.starts_at, format: :default) %>
    <% if @event.ends_at %> – <%= l(@event.ends_at, format: :default) %><% end %>
    <% if @event.location.present? %> · <%= @event.location %><% end %>
  </p>

  <% if @event.description.present? %>
    <p class="mt-6 text-sm text-slate-700 whitespace-pre-line"><%= @event.description %></p>
  <% end %>

  <% if current_member && @event.scheduled? %>
    <div class="mt-8 rounded-lg border border-slate-200 bg-white p-6">
      <h2 class="text-base font-semibold text-slate-950">¿Asistirás a este evento?</h2>

      <%= form_with url: rsvp_church_member_portal_event_path(@church, @event), method: :post, local: true, class: "mt-4 space-y-4" do |form| %>
        <div>
          <%= form.label :status, "Tu respuesta", class: "block text-sm font-medium text-slate-700" %>
          <%= form.select :status,
                [["Sí, asistiré", "attending"], ["No asistiré", "not_attending"], ["Tal vez", "maybe"]],
                { selected: @rsvp.status },
                class: "mt-1 block w-full rounded-md border border-slate-300 px-3 py-2 text-sm" %>
        </div>
        <div>
          <%= form.label :guests_count, "Acompañantes adicionales", class: "block text-sm font-medium text-slate-700" %>
          <%= form.number_field :guests_count, value: @rsvp.guests_count || 0, min: 0,
                class: "mt-1 block w-32 rounded-md border border-slate-300 px-3 py-2 text-sm" %>
        </div>
        <%= form.submit "Confirmar", class: "rounded-md bg-slate-950 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800 cursor-pointer" %>
      <% end %>
    </div>
  <% end %>
</section>
```

- [ ] **Step 4: Agregar rutas de portal eventos en config/routes.rb**

Dentro del bloque `namespace :portal, module: :member_portal, as: :member_portal do`, agregar:
```ruby
resources :events, param: :public_id, only: %i[index show] do
  member do
    post :rsvp
  end
end
```

El bloque completo debe quedar:
```ruby
namespace :portal, module: :member_portal, as: :member_portal do
  resource :profile, only: %i[show]
  resources :profile_change_requests, only: %i[new create]
  resources :events, param: :public_id, only: %i[index show] do
    member do
      post :rsvp
    end
  end
end
```

- [ ] **Step 5: Verificar rutas**

```bash
docker compose exec web bin/rails routes | grep "member_portal.*event"
```
Expected: líneas con `church_member_portal_events`, `church_member_portal_event`, `rsvp_church_member_portal_event`

- [ ] **Step 6: Verificar que el portal carga**

```bash
docker compose exec web bin/rails runner "
app = Rails.application
session = ActionDispatch::Integration::Session.new(app)
ActionController::Base.allow_forgery_protection = false
u = User.find_by(email: 'genesisadmin@gmail.com')
church = Church.first
session.get '/users/sign_in'
session.post '/users/sign_in', params: { 'user[email]' => u.email, 'user[password]' => 'password123' }
session.get \"/churches/#{church.public_id}/portal/events\"
puts 'Status: ' + session.response.status.to_s
puts 'H1: ' + (session.response.body.match(/<h1[^>]*>([^<]+)/) ? \$1 : 'N/A')
ActionController::Base.allow_forgery_protection = true
"
```
Expected: `Status: 200`, `H1: Eventos`

- [ ] **Step 7: Commit**

```bash
git add app/controllers/member_portal/events_controller.rb \
  app/views/member_portal/events/ \
  config/routes.rb
git commit -m "feat: portal de miembro — eventos y confirmación RSVP"
```

---

## Task 4: MinistryLeader namespace

**Files:**
- Create: `app/controllers/ministry_leader/base_controller.rb`
- Create: `app/controllers/ministry_leader/ministries_controller.rb`
- Create: `app/controllers/ministry_leader/events_controller.rb`
- Create: `app/views/ministry_leader/ministries/index.html.erb`
- Create: `app/views/ministry_leader/ministries/show.html.erb`
- Create: `app/views/ministry_leader/events/index.html.erb`
- Create: `app/views/ministry_leader/events/show.html.erb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Crear MinistryLeader::BaseController**

Crear `app/controllers/ministry_leader/base_controller.rb`:
```ruby
module MinistryLeader
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :set_church_context
    before_action :authorize_leader_access

    private

    def set_church_context
      @church = Church.find_by_public_id!(params[:church_public_id])
      Current.church = @church
      Current.church_membership = current_user.active_membership_for(@church)
      session[:current_church_public_id] = @church.public_id
    end

    def authorize_leader_access
      membership = Current.church_membership
      unless membership&.active? && led_ministries.any?
        raise Pundit::NotAuthorizedError
      end
    end

    def led_ministries
      @led_ministries ||= begin
        member = @church.members.find_by(user: current_user)
        return Ministry.none unless member

        Ministry.joins(:ministry_memberships)
          .where(ministry_memberships: {
            member: member,
            ministry_role: %w[leader co_leader],
            status: "active"
          })
          .where(church: @church)
      end
    end
    helper_method :led_ministries
  end
end
```

- [ ] **Step 2: Crear MinistryLeader::MinistriesController**

Crear `app/controllers/ministry_leader/ministries_controller.rb`:
```ruby
module MinistryLeader
  class MinistriesController < BaseController
    before_action :set_ministry, only: %i[show]

    def index
      @ministries = led_ministries.order(:name)
    end

    def show
      unless led_ministries.include?(@ministry)
        raise Pundit::NotAuthorizedError
      end

      @members = @ministry.ministry_memberships
        .where(status: "active")
        .includes(:member)
        .order("members.last_name, members.first_name")
    end

    private

    def set_ministry
      @ministry = @church.ministries.find_by_public_id!(params[:public_id])
    end
  end
end
```

- [ ] **Step 3: Crear MinistryLeader::EventsController**

Crear `app/controllers/ministry_leader/events_controller.rb`:
```ruby
module MinistryLeader
  class EventsController < BaseController
    before_action :set_event, only: %i[show]

    def index
      @events = @church.events
        .where(ministry: led_ministries)
        .order(:starts_at)
        .includes(:ministry)

      @filter = params[:filter].presence || "upcoming"
      @events = case @filter
      when "past" then @events.past
      when "all" then @events.ordered
      else @events.upcoming
      end
    end

    def show
      unless led_ministries.include?(@event.ministry)
        raise Pundit::NotAuthorizedError
      end

      @rsvps = @event.event_rsvps.includes(:member)
      @attendances = @event.event_attendances.includes(:member)
    end

    private

    def set_event
      @event = @church.events.find_by_public_id!(params[:public_id])
    end
  end
end
```

- [ ] **Step 4: Crear vista index de ministerios para líder**

Crear `app/views/ministry_leader/ministries/index.html.erb`:
```erb
<section class="mx-auto w-full max-w-5xl px-6 py-10">
  <div>
    <p class="text-sm font-medium text-slate-500"><%= @church.name %></p>
    <h1 class="mt-2 text-3xl font-semibold text-slate-950">Mis ministerios</h1>
  </div>

  <div class="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
    <% @ministries.each do |ministry| %>
      <article class="rounded-lg border border-slate-200 bg-white p-5">
        <h2 class="font-semibold text-slate-950">
          <%= link_to ministry.name, church_ministry_leader_ministry_path(@church, ministry), class: "hover:underline" %>
        </h2>
        <% if ministry.description.present? %>
          <p class="mt-2 text-sm text-slate-500 line-clamp-2"><%= ministry.description %></p>
        <% end %>
        <div class="mt-4 flex gap-3 text-sm">
          <%= link_to "Ministerio", church_ministry_leader_ministry_path(@church, ministry), class: "font-medium text-slate-600 hover:text-slate-950" %>
          <%= link_to "Eventos", church_ministry_leader_events_path(@church, ministry_id: ministry.id), class: "font-medium text-slate-600 hover:text-slate-950" %>
        </div>
      </article>
    <% end %>
  </div>
</section>
```

- [ ] **Step 5: Crear vista show de ministerio para líder**

Crear `app/views/ministry_leader/ministries/show.html.erb`:
```erb
<section class="mx-auto w-full max-w-5xl px-6 py-10">
  <div class="mb-6">
    <%= link_to "← Mis ministerios", church_ministry_leader_ministries_path(@church), class: "text-sm text-slate-600 hover:text-slate-950" %>
  </div>

  <div>
    <p class="text-sm font-medium text-slate-500"><%= @church.name %></p>
    <h1 class="mt-2 text-3xl font-semibold text-slate-950"><%= @ministry.name %></h1>
    <% if @ministry.description.present? %>
      <p class="mt-2 text-sm text-slate-500"><%= @ministry.description %></p>
    <% end %>
  </div>

  <div class="mt-8">
    <h2 class="text-lg font-semibold text-slate-950">Miembros activos (<%= @members.count %>)</h2>
    <div class="mt-4 overflow-hidden rounded-lg border border-slate-200 bg-white">
      <table class="min-w-full divide-y divide-slate-200 text-sm">
        <thead class="bg-slate-50 text-left text-xs font-semibold uppercase text-slate-500">
          <tr>
            <th class="px-4 py-3">Nombre</th>
            <th class="px-4 py-3">Rol</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-200">
          <% @members.each do |mm| %>
            <tr>
              <td class="px-4 py-3 font-medium text-slate-950"><%= mm.member.full_name %></td>
              <td class="px-4 py-3 text-slate-600 capitalize"><%= mm.ministry_role %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>
</section>
```

- [ ] **Step 6: Crear vista index de eventos para líder**

Crear `app/views/ministry_leader/events/index.html.erb`:
```erb
<section class="mx-auto w-full max-w-5xl px-6 py-10">
  <div>
    <p class="text-sm font-medium text-slate-500"><%= @church.name %></p>
    <h1 class="mt-2 text-3xl font-semibold text-slate-950">Eventos de mis ministerios</h1>
  </div>

  <div class="mt-6 flex gap-2 text-sm">
    <% %w[upcoming past all].each do |filter| %>
      <% label = { "upcoming" => "Próximos", "past" => "Pasados", "all" => "Todos" }[filter] %>
      <%= link_to label, church_ministry_leader_events_path(@church, filter:),
            class: "rounded-md border px-3 py-2 font-medium #{@filter == filter ? 'border-slate-950 bg-slate-950 text-white' : 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50'}" %>
    <% end %>
  </div>

  <div class="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
    <table class="min-w-full divide-y divide-slate-200 text-sm">
      <thead class="bg-slate-50 text-left text-xs font-semibold uppercase text-slate-500">
        <tr>
          <th class="px-4 py-3">Título</th>
          <th class="px-4 py-3">Ministerio</th>
          <th class="px-4 py-3">Inicio</th>
          <th class="px-4 py-3">Estado</th>
          <th class="px-4 py-3 text-right">Acciones</th>
        </tr>
      </thead>
      <tbody class="divide-y divide-slate-200">
        <% if @events.any? %>
          <% @events.each do |event| %>
            <tr>
              <td class="px-4 py-4 font-medium text-slate-950"><%= event.title %></td>
              <td class="px-4 py-4 text-slate-600"><%= event.ministry&.name %></td>
              <td class="px-4 py-4 text-slate-600"><%= l(event.starts_at, format: :default) %></td>
              <td class="px-4 py-4 text-slate-600"><%= event_status_label(event.status) %></td>
              <td class="px-4 py-4 text-right">
                <%= link_to "Ver", church_ministry_leader_event_path(@church, event), class: "font-medium text-slate-600 hover:text-slate-950" %>
              </td>
            </tr>
          <% end %>
        <% else %>
          <tr><td colspan="5" class="px-4 py-8 text-center text-slate-500">No hay eventos.</td></tr>
        <% end %>
      </tbody>
    </table>
  </div>
</section>
```

- [ ] **Step 7: Crear vista show de evento para líder**

Crear `app/views/ministry_leader/events/show.html.erb`:
```erb
<section class="mx-auto w-full max-w-5xl px-6 py-10">
  <div class="mb-6">
    <%= link_to "← Eventos", church_ministry_leader_events_path(@church), class: "text-sm text-slate-600 hover:text-slate-950" %>
  </div>

  <div>
    <p class="text-sm font-medium text-slate-500"><%= @church.name %> / <%= @event.ministry&.name %></p>
    <h1 class="mt-2 text-3xl font-semibold text-slate-950"><%= @event.title %></h1>
    <p class="mt-1 text-sm text-slate-500">Estado: <%= event_status_label(@event.status) %></p>
  </div>

  <div class="mt-8 grid grid-cols-1 gap-6 md:grid-cols-3">
    <div class="rounded-lg border border-slate-200 bg-white p-6">
      <h2 class="text-sm font-semibold uppercase text-slate-500">Detalles</h2>
      <dl class="mt-3 space-y-2 text-sm">
        <div><dt class="font-medium text-slate-500">Inicio</dt><dd><%= l(@event.starts_at, format: :default) %></dd></div>
        <% if @event.ends_at %><div><dt class="font-medium text-slate-500">Fin</dt><dd><%= l(@event.ends_at, format: :default) %></dd></div><% end %>
        <% if @event.location.present? %><div><dt class="font-medium text-slate-500">Lugar</dt><dd><%= @event.location %></dd></div><% end %>
        <% if @event.capacity %><div><dt class="font-medium text-slate-500">Capacidad</dt><dd><%= @event.capacity %></dd></div><% end %>
      </dl>
    </div>

    <div class="rounded-lg border border-slate-200 bg-white p-6">
      <h2 class="text-sm font-semibold uppercase text-slate-500">Confirmaciones</h2>
      <p class="mt-2 text-3xl font-semibold text-slate-950"><%= @event.confirmed_attendees_count %></p>
      <ul class="mt-4 space-y-1 text-sm text-slate-600">
        <% @rsvps.each do |rsvp| %>
          <li><%= rsvp.member.full_name %> — <%= rsvp.status %></li>
        <% end %>
      </ul>
    </div>

    <div class="rounded-lg border border-slate-200 bg-white p-6">
      <h2 class="text-sm font-semibold uppercase text-slate-500">Asistencia real</h2>
      <p class="mt-2 text-3xl font-semibold text-slate-950"><%= @event.attended_count %></p>
    </div>
  </div>
</section>
```

- [ ] **Step 8: Agregar rutas de MinistryLeader en config/routes.rb**

Dentro del bloque `resources :churches, param: :public_id, only: %i[index show] do`, DESPUÉS del bloque `namespace :pastor`, agregar:

```ruby
namespace :ministry_leader, module: :ministry_leader, as: :ministry_leader do
  resources :ministries, param: :public_id, only: %i[index show]
  resources :events, param: :public_id, only: %i[index show]
end
```

- [ ] **Step 9: Verificar rutas**

```bash
docker compose exec web bin/rails routes | grep "ministry_leader"
```
Expected: líneas con `church_ministry_leader_ministries`, `church_ministry_leader_events`, etc.

- [ ] **Step 10: Commit**

```bash
git add app/controllers/ministry_leader/ \
  app/views/ministry_leader/ \
  config/routes.rb
git commit -m "feat: namespace MinistryLeader para líderes de ministerio"
```

---

## Task 5: Pastor::MembersController

**Files:**
- Create: `app/controllers/pastor/members_controller.rb`
- Create: `app/views/pastor/members/index.html.erb`
- Create: `app/views/pastor/members/show.html.erb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Crear Pastor::MembersController**

Crear `app/controllers/pastor/members_controller.rb`:
```ruby
module Pastor
  class MembersController < BaseController
    before_action :set_member, only: %i[show]

    def index
      authorize Member, :index?, policy_class: MemberPolicy
      @members = @church.members.active.ordered.includes(:ministries)
      @pagy, @members = pagy(@members, items: 30)
    end

    def show
      authorize @member, :show?, policy_class: MemberPolicy
      @pastoral_notes = @church.pastoral_notes
        .where(member: @member)
        .where(pastor: current_user)
        .ordered
    end

    private

    def set_member
      @member = @church.members.find_by_public_id!(params[:public_id])
    end
  end
end
```

- [ ] **Step 2: Crear vista index de miembros para pastor**

Crear `app/views/pastor/members/index.html.erb`:
```erb
<section class="mx-auto w-full max-w-5xl px-6 py-10">
  <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
    <div>
      <p class="text-sm font-medium text-slate-500"><%= @church.name %></p>
      <h1 class="mt-2 text-3xl font-semibold text-slate-950">Directorio de miembros</h1>
    </div>
    <%= link_to "Notas pastorales", church_pastor_pastoral_notes_path(@church), class: "text-sm font-medium text-slate-600 hover:text-slate-950" %>
  </div>

  <div class="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
    <table class="min-w-full divide-y divide-slate-200 text-sm">
      <thead class="bg-slate-50 text-left text-xs font-semibold uppercase text-slate-500">
        <tr>
          <th class="px-4 py-3">Nombre</th>
          <th class="px-4 py-3">Ministerios</th>
          <th class="px-4 py-3 text-right">Acciones</th>
        </tr>
      </thead>
      <tbody class="divide-y divide-slate-200">
        <% @members.each do |member| %>
          <tr>
            <td class="px-4 py-4">
              <div class="flex items-center gap-3">
                <% if member.photo.attached? %>
                  <%= image_tag member.photo.variant(resize_to_fill: [36, 36]).processed, class: "h-9 w-9 rounded-full object-cover" %>
                <% else %>
                  <div class="flex h-9 w-9 items-center justify-center rounded-full bg-slate-100 text-sm font-semibold text-slate-400">
                    <%= member.first_name&.first&.upcase %>
                  </div>
                <% end %>
                <div>
                  <div class="font-medium text-slate-950"><%= member.full_name %></div>
                  <div class="text-xs text-slate-500"><%= member.email.presence || member.phone %></div>
                </div>
              </div>
            </td>
            <td class="px-4 py-4 text-slate-600">
              <%= member.ministries.map(&:name).join(", ").presence || "Sin ministerio" %>
            </td>
            <td class="px-4 py-4 text-right">
              <%= link_to "Ver", church_pastor_member_path(@church, member), class: "font-medium text-slate-600 hover:text-slate-950" %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
  <%== pagy_nav(@pagy) if @pagy.pages > 1 %>
</section>
```

- [ ] **Step 3: Crear vista show de miembro para pastor**

Crear `app/views/pastor/members/show.html.erb`:
```erb
<section class="mx-auto w-full max-w-4xl px-6 py-10">
  <div class="mb-6">
    <%= link_to "← Directorio", church_pastor_members_path(@church), class: "text-sm text-slate-600 hover:text-slate-950" %>
  </div>

  <div class="flex items-start gap-6">
    <% if @member.photo.attached? %>
      <%= image_tag @member.photo.variant(resize_to_fill: [80, 80]).processed, class: "h-20 w-20 rounded-full object-cover border border-slate-200" %>
    <% else %>
      <div class="flex h-20 w-20 items-center justify-center rounded-full bg-slate-100 text-slate-400 text-2xl font-semibold">
        <%= @member.first_name&.first&.upcase %>
      </div>
    <% end %>
    <div>
      <h1 class="text-3xl font-semibold text-slate-950"><%= @member.full_name %></h1>
      <p class="mt-1 text-sm text-slate-500"><%= @member.email.presence || @member.phone %></p>
      <% if @member.ministries.any? %>
        <p class="mt-1 text-xs text-slate-400"><%= @member.ministries.map(&:name).join(", ") %></p>
      <% end %>
    </div>
  </div>

  <div class="mt-8 flex items-center justify-between">
    <h2 class="text-lg font-semibold text-slate-950">Mis notas sobre este miembro</h2>
    <%= link_to "Nueva nota", new_church_pastor_pastoral_note_path(@church, member_public_id: @member.public_id),
          class: "rounded-md bg-slate-950 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800" %>
  </div>

  <div class="mt-4 space-y-4">
    <% if @pastoral_notes.any? %>
      <% @pastoral_notes.each do |note| %>
        <article class="rounded-lg border border-slate-200 bg-white p-5">
          <div class="flex items-start justify-between">
            <div>
              <h3 class="font-medium text-slate-950"><%= note.title %></h3>
              <p class="mt-1 text-xs text-slate-500"><%= l(note.created_at, format: :default) %></p>
            </div>
            <%= link_to "Ver", church_pastor_pastoral_note_path(@church, note), class: "text-sm font-medium text-slate-600 hover:text-slate-950" %>
          </div>
          <p class="mt-3 text-sm text-slate-700 line-clamp-3"><%= note.body %></p>
        </article>
      <% end %>
    <% else %>
      <div class="rounded-lg border border-slate-200 bg-white px-6 py-8 text-center text-sm text-slate-500">
        No tienes notas para este miembro aún.
      </div>
    <% end %>
  </div>
</section>
```

- [ ] **Step 4: Agregar rutas de pastor members en config/routes.rb**

Dentro del bloque `namespace :pastor, module: :pastor, as: :pastor do`, agregar:
```ruby
resources :members, param: :public_id, only: %i[index show]
```

El bloque completo debe quedar:
```ruby
namespace :pastor, module: :pastor, as: :pastor do
  resources :pastoral_notes, param: :public_id
  resources :members, param: :public_id, only: %i[index show]
end
```

- [ ] **Step 5: Verificar rutas**

```bash
docker compose exec web bin/rails routes | grep "pastor.*member"
```
Expected: líneas con `church_pastor_members`, `church_pastor_member`

- [ ] **Step 6: Commit**

```bash
git add app/controllers/pastor/members_controller.rb \
  app/views/pastor/members/ \
  config/routes.rb
git commit -m "feat: vista de miembros (solo lectura) para pastores"
```

---

## Task 6: Dashboard de iglesia

**Files:**
- Create: `app/controllers/church_admin/dashboard_controller.rb`
- Create: `app/views/church_admin/dashboard/index.html.erb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Crear DashboardController**

Crear `app/controllers/church_admin/dashboard_controller.rb`:
```ruby
module ChurchAdmin
  class DashboardController < BaseController
    def index
      skip_authorization # Dashboard no opera sobre un modelo específico

      @stats = {
        members_active: @church.members.active.count,
        members_inactive: Member.where(church: @church, member_status: "inactive").count,
        ministries_active: @church.ministries.where(status: "active").count,
        events_upcoming: @church.events.upcoming.count,
        pending_change_requests: @church.profile_change_requests.pending.count,
        pastoral_notes: @church.pastoral_notes.count
      }

      @upcoming_events = @church.events.upcoming.includes(:ministry).first(5)
      @recent_members = @church.members.active.order(created_at: :desc).first(5)
      @pending_requests = @church.profile_change_requests.pending.includes(:member).order(created_at: :desc).first(5)
    end
  end
end
```

- [ ] **Step 2: Crear vista del dashboard**

Crear `app/views/church_admin/dashboard/index.html.erb`:
```erb
<section class="mx-auto w-full max-w-6xl px-6 py-10">
  <div>
    <p class="text-sm font-medium text-slate-500">Panel de administración</p>
    <h1 class="mt-2 text-3xl font-semibold text-slate-950"><%= @church.name %></h1>
  </div>

  <%# Tarjetas de estadísticas %>
  <div class="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
    <% [
      { label: "Miembros activos", value: @stats[:members_active], path: church_admin_members_path(@church) },
      { label: "Ministerios", value: @stats[:ministries_active], path: church_admin_ministries_path(@church) },
      { label: "Eventos próximos", value: @stats[:events_upcoming], path: church_admin_events_path(@church) },
      { label: "Solicitudes pendientes", value: @stats[:pending_change_requests], path: church_admin_profile_change_requests_path(@church) },
    ].each do |stat| %>
      <div class="rounded-lg border border-slate-200 bg-white p-5">
        <%= stat[:path] ? link_to(stat[:path], class: "block") { } : nil %>
        <p class="text-2xl font-bold text-slate-950"><%= stat[:value] %></p>
        <p class="mt-1 text-xs font-medium text-slate-500"><%= stat[:label] %></p>
        <%= link_to "Ver →", stat[:path], class: "mt-2 block text-xs font-medium text-slate-400 hover:text-slate-700" %>
      </div>
    <% end %>
  </div>

  <div class="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-2">
    <%# Próximos eventos %>
    <div>
      <div class="flex items-center justify-between">
        <h2 class="text-base font-semibold text-slate-950">Próximos eventos</h2>
        <%= link_to "Ver todos →", church_admin_events_path(@church), class: "text-sm text-slate-500 hover:text-slate-950" %>
      </div>
      <div class="mt-3 overflow-hidden rounded-lg border border-slate-200 bg-white divide-y divide-slate-100">
        <% if @upcoming_events.any? %>
          <% @upcoming_events.each do |event| %>
            <div class="px-4 py-3 flex items-center justify-between gap-4">
              <div>
                <p class="text-sm font-medium text-slate-950"><%= event.title %></p>
                <p class="text-xs text-slate-500"><%= l(event.starts_at, format: :default) %><% if event.ministry %> · <%= event.ministry.name %><% end %></p>
              </div>
              <%= link_to "Ver", church_admin_event_path(@church, event), class: "text-xs font-medium text-slate-500 hover:text-slate-950 shrink-0" %>
            </div>
          <% end %>
        <% else %>
          <p class="px-4 py-8 text-center text-sm text-slate-400">No hay eventos próximos.</p>
        <% end %>
      </div>
    </div>

    <%# Miembros recientes %>
    <div>
      <div class="flex items-center justify-between">
        <h2 class="text-base font-semibold text-slate-950">Miembros recientes</h2>
        <%= link_to "Ver todos →", church_admin_members_path(@church), class: "text-sm text-slate-500 hover:text-slate-950" %>
      </div>
      <div class="mt-3 overflow-hidden rounded-lg border border-slate-200 bg-white divide-y divide-slate-100">
        <% if @recent_members.any? %>
          <% @recent_members.each do |member| %>
            <div class="px-4 py-3 flex items-center gap-3">
              <% if member.photo.attached? %>
                <%= image_tag member.photo.variant(resize_to_fill: [32, 32]).processed, class: "h-8 w-8 rounded-full object-cover" %>
              <% else %>
                <div class="flex h-8 w-8 items-center justify-center rounded-full bg-slate-100 text-xs font-semibold text-slate-400">
                  <%= member.first_name&.first&.upcase %>
                </div>
              <% end %>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-slate-950 truncate"><%= member.full_name %></p>
              </div>
              <%= link_to "Ver", church_admin_member_path(@church, member), class: "text-xs font-medium text-slate-500 hover:text-slate-950 shrink-0" %>
            </div>
          <% end %>
        <% else %>
          <p class="px-4 py-8 text-center text-sm text-slate-400">No hay miembros registrados.</p>
        <% end %>
      </div>
    </div>

    <%# Solicitudes pendientes %>
    <% if @pending_requests.any? %>
      <div class="lg:col-span-2">
        <div class="flex items-center justify-between">
          <h2 class="text-base font-semibold text-slate-950">Solicitudes de cambio pendientes</h2>
          <%= link_to "Ver todas →", church_admin_profile_change_requests_path(@church), class: "text-sm text-slate-500 hover:text-slate-950" %>
        </div>
        <div class="mt-3 overflow-hidden rounded-lg border border-amber-200 bg-amber-50 divide-y divide-amber-100">
          <% @pending_requests.each do |req| %>
            <div class="px-4 py-3 flex items-center justify-between gap-4">
              <div>
                <p class="text-sm font-medium text-slate-950"><%= req.member.full_name %></p>
                <p class="text-xs text-slate-500">Solicitado <%= time_ago_in_words(req.created_at) %></p>
              </div>
              <%= link_to "Revisar", church_admin_profile_change_request_path(@church, req), class: "text-xs font-medium text-amber-700 hover:text-amber-900 shrink-0" %>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
  </div>
</section>
```

- [ ] **Step 3: Cambiar root del admin a dashboard en config/routes.rb**

En `config/routes.rb`, dentro del bloque `namespace :admin, module: :church_admin, as: :admin do`, cambiar:
```ruby
root "roles#index"
```
por:
```ruby
root "dashboard#index"
```

- [ ] **Step 4: Verificar que dashboard carga**

```bash
docker compose exec web bin/rails runner "
app = Rails.application
session = ActionDispatch::Integration::Session.new(app)
ActionController::Base.allow_forgery_protection = false
u = User.find_by(email: 'genesisadmin@gmail.com')
church = Church.first
session.get '/users/sign_in'
session.post '/users/sign_in', params: { 'user[email]' => u.email, 'user[password]' => 'password123' }
session.get \"/churches/#{church.public_id}/admin\"
puts 'Status: ' + session.response.status.to_s
puts 'Has stats: ' + session.response.body.include?('Miembros activos').to_s
ActionController::Base.allow_forgery_protection = true
"
```
Expected: `Status: 200`, `Has stats: true`

- [ ] **Step 5: Commit**

```bash
git add app/controllers/church_admin/dashboard_controller.rb \
  app/views/church_admin/dashboard/ \
  config/routes.rb
git commit -m "feat: dashboard de iglesia con estadísticas y accesos rápidos"
```
