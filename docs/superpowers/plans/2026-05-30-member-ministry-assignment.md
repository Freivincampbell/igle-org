# Member Ministry Assignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir un panel inline con auto-guardado en el show del miembro para asignar/desasignar ministerios con selección de rol, usando el mismo patrón UX que skills/ocupaciones.

**Architecture:** Nuevo controlador Stimulus `ministry-picker` que selecciona entidades existentes por `public_id` (como `member-search`) y auto-guarda con debounce (como `catalog-search`). Nuevo `ChurchAdmin::MemberMinistriesController#assign` para el PATCH. Nueva acción `MinistriesController#search` para resultados turbo-frame. La variable `@ministry_memberships` ya existe en `MembersController#show`, no requiere cambios.

**Tech Stack:** Ruby on Rails 8, Stimulus JS (Hotwire), Turbo Frames, Tailwind CSS, Pundit, RSpec (request specs).

---

## File Map

| Archivo | Acción |
|---------|--------|
| `config/routes.rb` | Agregar `collection { get :search }` a ministries; agregar `patch :assign_ministries` al segundo bloque de members |
| `config/locales/es.yml` | Agregar claves `church_admin.member_ministries.*` |
| `app/controllers/church_admin/ministries_controller.rb` | Agregar acción `search` |
| `app/controllers/church_admin/member_ministries_controller.rb` | Crear con acción `assign` |
| `app/javascript/controllers/ministry_picker_controller.js` | Crear |
| `app/views/church_admin/ministries/search.html.erb` | Crear resultados turbo-frame |
| `app/views/church_admin/members/_ministry_tag.html.erb` | Crear tag row partial |
| `app/views/church_admin/members/show.html.erb` | Reemplazar sección ministerios con picker condicional |
| `spec/requests/church_admin/ministries_search_spec.rb` | Crear |
| `spec/requests/church_admin/member_ministries_spec.rb` | Crear |

---

### Task 1: Routes + i18n

**Files:**
- Modify: `config/routes.rb`
- Modify: `config/locales/es.yml`

- [ ] **Step 1: Agregar la ruta de búsqueda de ministerios**

En `config/routes.rb`, actualizar el bloque `resources :ministries` (línea ~48) para agregar la colección `search`:

```ruby
resources :ministries, param: :public_id, only: %i[index show new create edit update] do
  collection { get :search }   # ← agregar esta línea
  member do
    patch :activate
    patch :deactivate
    patch :members, action: :update_members
  end
end
```

- [ ] **Step 2: Agregar la ruta assign_ministries**

En `config/routes.rb`, en el segundo bloque `resources :members` (el que tiene `only: []`, línea ~106), agregar la ruta:

```ruby
resources :members, param: :public_id, only: [] do
  member do
    patch :assign_occupations, controller: "member_occupations", action: :assign
    patch :assign_skills,      controller: "member_skills",      action: :assign
    patch :assign_ministries,  controller: "member_ministries",  action: :assign  # ← agregar
  end
  resources :occupations, param: :public_id, only: %i[new create edit update destroy], controller: "member_occupations"
  resources :skills, param: :public_id, only: %i[new create edit update destroy], controller: "member_skills"
end
```

- [ ] **Step 3: Verificar que las rutas existen**

```bash
bin/rails routes | grep -E "assign_ministries|ministries.*search"
```

Salida esperada (aproximada):
```
assign_ministries_church_admin_member  PATCH  /churches/:church_public_id/members/:public_id/assign_ministries(.:format)
search_church_admin_ministries         GET    /churches/:church_public_id/ministries/search(.:format)
```

- [ ] **Step 4: Agregar claves i18n**

En `config/locales/es.yml`, buscar la clave `church_admin:` y agregar dentro:

```yaml
      member_ministries:
        updated: "Ministerios actualizados correctamente."
        invalid_ministry: "Uno o más ministerios no son válidos para esta iglesia."
```

Verificar que el indentado sea consistente con las claves vecinas (ej. `member_skills:`, `member_occupations:`).

- [ ] **Step 5: Commit**

```bash
git add config/routes.rb config/locales/es.yml
git commit -m "feat: add routes and i18n for member ministry assignment"
```

---

### Task 2: MinistriesController#search (TDD)

**Files:**
- Create: `spec/requests/church_admin/ministries_search_spec.rb`
- Modify: `app/controllers/church_admin/ministries_controller.rb`
- Create: `app/views/church_admin/ministries/search.html.erb`

- [ ] **Step 1: Escribir el spec fallido**

Crear `spec/requests/church_admin/ministries_search_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "ChurchAdmin::Ministries#search", type: :request do
  let(:church)      { create(:church) }
  let(:membership)  { create(:church_membership, :owner, church:) }

  before { sign_in membership.user }

  let!(:alabanza)  { create(:ministry, church:, name: "Alabanza",         status: "active") }
  let!(:jovenes)   { create(:ministry, church:, name: "Jóvenes",          status: "active") }
  let!(:inactivo)  { create(:ministry, church:, name: "Alabanza Inactiva", status: "inactive") }
  let!(:otra_igles){ create(:ministry,           name: "Otro",             status: "active") }

  def search(q: "ala", frame_id: "test-frame", exclude: [])
    params = { q:, frame_id: }
    params["exclude[]"] = exclude if exclude.any?
    get search_church_admin_ministries_path(church), params:
  end

  it "retorna ministerios activos de la iglesia que coinciden con la búsqueda" do
    search(q: "ala")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Alabanza")
    expect(response.body).not_to include("Jóvenes")
    expect(response.body).not_to include("Alabanza Inactiva")
    expect(response.body).not_to include("Otro")
  end

  it "excluye los ministerios cuyos public_ids están en exclude[]" do
    search(q: "ala", exclude: [alabanza.public_id])
    expect(response.body).not_to include(alabanza.name)
  end

  it "devuelve cuerpo sin resultados para búsquedas de menos de 2 caracteres" do
    search(q: "a")
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Alabanza")
  end

  it "envuelve el resultado en el turbo-frame solicitado" do
    search(q: "ala", frame_id: "ministry-results-abc123")
    expect(response.body).to include('id="ministry-results-abc123"')
  end
end
```

- [ ] **Step 2: Ejecutar el spec para confirmar que falla**

```bash
bundle exec rspec spec/requests/church_admin/ministries_search_spec.rb --format documentation
```

Salida esperada: 4 fallos (acción no definida).

- [ ] **Step 3: Agregar la acción search a MinistriesController**

En `app/controllers/church_admin/ministries_controller.rb`, agregar antes de `private`:

```ruby
def search
  authorize Ministry, :index?
  skip_policy_scope
  q = params[:q].to_s.strip
  excluded = Array(params[:exclude]).compact_blank
  @results = if q.length >= 2
    @church.ministries.active
      .search_by_name(q)
      .where.not(public_id: excluded)
      .ordered
      .limit(8)
  else
    []
  end
  @frame_id = params[:frame_id].to_s.gsub(/[^a-z0-9-]/, "")
  render layout: false
end
```

- [ ] **Step 4: Crear la vista de resultados**

Crear `app/views/church_admin/ministries/search.html.erb`:

```erb
<%= turbo_frame_tag @frame_id do %>
  <% if @results.any? %>
    <ul class="divide-y divide-slate-50 py-1">
      <% @results.each do |ministry| %>
        <li>
          <button type="button"
                  class="group/r flex w-full items-center gap-3 px-4 py-2.5 text-left hover:bg-violet-50 transition-colors"
                  data-action="click->ministry-picker#addMinistry"
                  data-public-id="<%= ministry.public_id %>"
                  data-name="<%= ministry.name %>">
            <div class="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-violet-100 text-violet-600">
              <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Z" />
              </svg>
            </div>
            <span class="flex-1 text-sm font-medium text-slate-900"><%= ministry.name %></span>
            <span class="shrink-0 rounded-full bg-violet-100 px-2 py-0.5 text-[11px] font-semibold text-violet-700 opacity-0 transition-opacity group-hover/r:opacity-100">
              Agregar
            </span>
          </button>
        </li>
      <% end %>
    </ul>
  <% end %>
<% end %>
```

- [ ] **Step 5: Ejecutar el spec para confirmar que pasa**

```bash
bundle exec rspec spec/requests/church_admin/ministries_search_spec.rb --format documentation
```

Salida esperada: 4 ejemplos, 0 fallos.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/church_admin/ministries_controller.rb \
        app/views/church_admin/ministries/search.html.erb \
        spec/requests/church_admin/ministries_search_spec.rb
git commit -m "feat: add ministry search endpoint for ministry-picker"
```

---

### Task 3: MemberMinistriesController#assign (TDD)

**Files:**
- Create: `spec/requests/church_admin/member_ministries_spec.rb`
- Create: `app/controllers/church_admin/member_ministries_controller.rb`

- [ ] **Step 1: Escribir el spec fallido**

Crear `spec/requests/church_admin/member_ministries_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "ChurchAdmin::MemberMinistries", type: :request do
  let(:church)     { create(:church) }
  let(:membership) { create(:church_membership, :owner, church:) }
  let(:member)     { create(:member, church:) }
  let(:ministry1)  { create(:ministry, church:, status: "active") }
  let(:ministry2)  { create(:ministry, church:, status: "active") }

  before { sign_in membership.user }

  def assign_path
    assign_ministries_church_admin_member_path(church, member)
  end

  describe "PATCH /assign_ministries" do
    context "cuando se asignan ministerios nuevos" do
      it "crea las membresías y redirige con aviso" do
        patch assign_path, params: {
          ministry_memberships: {
            ministry1.public_id => { role: "member" },
            ministry2.public_id => { role: "leader" }
          }
        }
        expect(response).to redirect_to(church_admin_member_path(church, member))
        follow_redirect!
        expect(response.body).to include(I18n.t("church_admin.member_ministries.updated"))
        expect(member.ministry_memberships.active.count).to eq(2)
        expect(member.ministry_memberships.find_by(ministry: ministry1).ministry_role).to eq("member")
        expect(member.ministry_memberships.find_by(ministry: ministry2).ministry_role).to eq("leader")
      end
    end

    context "cuando se actualiza el rol de una membresía existente" do
      let!(:existing_mm) do
        create(:ministry_membership, member:, ministry: ministry1,
               status: "active", ministry_role: "member")
      end

      it "actualiza el rol sin duplicar la membresía" do
        patch assign_path, params: {
          ministry_memberships: { ministry1.public_id => { role: "leader" } }
        }
        expect(member.ministry_memberships.active.count).to eq(1)
        expect(existing_mm.reload.ministry_role).to eq("leader")
      end
    end

    context "cuando se desasigna un ministerio (no está en la lista enviada)" do
      let!(:existing_mm) do
        create(:ministry_membership, member:, ministry: ministry1,
               status: "active", ministry_role: "member")
      end

      it "desactiva la membresía sin borrarla físicamente" do
        patch assign_path, params: { ministry_memberships: {} }
        expect(existing_mm.reload.status).to eq("inactive")
      end

      it "no destruye el registro" do
        expect {
          patch assign_path, params: { ministry_memberships: {} }
        }.not_to change(MinistryMembership, :count)
      end
    end

    context "cuando el ministerio pertenece a otra iglesia" do
      let(:foreign_ministry) { create(:ministry, status: "active") }

      it "redirige con alerta sin crear membresías" do
        patch assign_path, params: {
          ministry_memberships: { foreign_ministry.public_id => { role: "member" } }
        }
        expect(response).to redirect_to(church_admin_member_path(church, member))
        follow_redirect!
        expect(response.body).to include(I18n.t("church_admin.member_ministries.invalid_ministry"))
        expect(member.ministry_memberships.active).to be_empty
      end
    end

    context "aislamiento multi-tenant" do
      let(:church2)         { create(:church) }
      let(:ministry_other)  { create(:ministry, church: church2, status: "active") }

      it "no puede asignar un ministerio de otra iglesia" do
        patch assign_path, params: {
          ministry_memberships: { ministry_other.public_id => { role: "member" } }
        }
        follow_redirect!
        expect(response.body).to include(I18n.t("church_admin.member_ministries.invalid_ministry"))
        expect(member.ministry_memberships.active).to be_empty
      end
    end

    context "cuando el usuario no tiene permiso de editar miembros" do
      let(:other_membership) { create(:church_membership, church:) }

      before { sign_in other_membership.user }

      it "lanza Pundit::NotAuthorizedError" do
        expect {
          patch assign_path, params: { ministry_memberships: {} }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
```

- [ ] **Step 2: Ejecutar el spec para confirmar que falla**

```bash
bundle exec rspec spec/requests/church_admin/member_ministries_spec.rb --format documentation
```

Salida esperada: fallos por controlador inexistente.

- [ ] **Step 3: Crear el controlador**

Crear `app/controllers/church_admin/member_ministries_controller.rb`:

```ruby
module ChurchAdmin
  class MemberMinistriesController < BaseController
    before_action :set_member

    def assign
      authorize @member, :update?

      raw = params.key?(:ministry_memberships) ? params[:ministry_memberships].to_unsafe_h : {}
      entries = raw.map do |public_id, attrs|
        { public_id: public_id.to_s, role: (attrs["role"].presence || "member").to_s }
      end.reject { |e| e[:public_id].blank? }.uniq { |e| e[:public_id] }

      ActiveRecord::Base.transaction do
        ministries = entries.map do |e|
          @church.ministries.active.find_by!(public_id: e[:public_id])
        end

        @member.ministry_memberships.active
          .where.not(ministry_id: ministries.map(&:id))
          .find_each(&:inactive!)

        entries.each do |e|
          ministry = ministries.find { |m| m.public_id == e[:public_id] }
          mm = @member.ministry_memberships.find_or_initialize_by(ministry:)
          mm.ministry_role = e[:role]
          mm.status = "active"
          mm.save!
        end
      end

      redirect_to church_admin_member_path(@church, @member),
        notice: t("church_admin.member_ministries.updated")
    rescue ActiveRecord::RecordNotFound
      redirect_to church_admin_member_path(@church, @member),
        alert: t("church_admin.member_ministries.invalid_ministry")
    end

    private

    def set_member
      @member = @church.members.find_by_public_id!(params[:public_id])
    end
  end
end
```

- [ ] **Step 4: Ejecutar el spec para confirmar que pasa**

```bash
bundle exec rspec spec/requests/church_admin/member_ministries_spec.rb --format documentation
```

Salida esperada: todos los ejemplos en verde, 0 fallos.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/church_admin/member_ministries_controller.rb \
        spec/requests/church_admin/member_ministries_spec.rb
git commit -m "feat: add MemberMinistriesController with assign action"
```

---

### Task 4: Ministry tag partial

**Files:**
- Create: `app/views/church_admin/members/_ministry_tag.html.erb`

- [ ] **Step 1: Crear el partial**

Crear `app/views/church_admin/members/_ministry_tag.html.erb`:

```erb
<%# locals: (name:, role: "member", ministry_public_id: nil) %>
<% field_id = ministry_public_id.presence || "__ID__" %>
<div data-ministry-tag class="group/row py-2.5 first:pt-0 last:pb-0 animate-fade-in-up">

  <%# Fila 1: ícono + nombre + botón quitar %>
  <div class="flex items-center gap-2">
    <div class="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-violet-100 text-violet-600">
      <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Z" />
      </svg>
    </div>

    <span data-tag-name class="min-w-0 flex-1 truncate text-sm font-semibold text-slate-900"><%= name %></span>

    <input type="hidden"
           data-tag-id-input
           name="ministry_memberships[<%= field_id %>][public_id]"
           value="<%= ministry_public_id.to_s %>">

    <button type="button"
            data-action="ministry-picker#removeTag"
            class="shrink-0 rounded-md p-1 text-slate-300 opacity-0 transition-all group-hover/row:opacity-100 hover:bg-rose-50 hover:text-rose-500">
      <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
      </svg>
    </button>
  </div>

  <%# Fila 2: selector de rol %>
  <div class="mt-1.5 flex items-center gap-2 pl-9">
    <select data-tag-meta
            data-action="change->ministry-picker#roleChanged"
            name="ministry_memberships[<%= field_id %>][role]"
            class="rounded-lg border border-slate-200 bg-slate-50 py-0.5 pl-2 pr-6 text-xs font-medium text-slate-600 focus:border-violet-400 focus:outline-none focus:ring-2 focus:ring-violet-200 transition-colors">
      <% MinistryMembership.ministry_roles.keys.each do |r| %>
        <option value="<%= r %>" <%= "selected" if r == role %>><%= ministry_role_label(r) %></option>
      <% end %>
    </select>
  </div>
</div>
```

> **Nota:** `data-tag-id-input` y `data-tag-meta` son los selectores que usa `ministry_picker_controller.js` para reemplazar `__ID__` al clonar el `<template>`. El partial se usa tanto para membresías existentes (con `ministry_public_id` real) como para el `<template>` vacío (con `nil`, que queda como `__ID__`).

- [ ] **Step 2: Verificar que el partial no tiene errores de sintaxis**

```bash
bin/rails runner "puts 'ok'"
```

Salida esperada: `ok` sin errores.

- [ ] **Step 3: Commit**

```bash
git add app/views/church_admin/members/_ministry_tag.html.erb
git commit -m "feat: add ministry tag partial for ministry-picker"
```

---

### Task 5: Actualizar members/show.html.erb

**Files:**
- Modify: `app/views/church_admin/members/show.html.erb`

La sección `<%# ── Ministerios ── %>` (líneas ~130–182 aprox.) es actualmente read-only. Se reemplaza completa con un bloque condicional: picker interactivo para usuarios con permiso de editar, lista read-only para el resto.

- [ ] **Step 1: Localizar la sección a reemplazar**

```bash
grep -n "Ministerios\|ministry_memberships" app/views/church_admin/members/show.html.erb
```

Identificar la línea de inicio del comentario `<%# ── Ministerios ── %>` y el cierre de su `</section>`.

- [ ] **Step 2: Reemplazar la sección completa de Ministerios**

Sustituir todo el bloque `<%# ── Ministerios ── %>` y su `<section>` correspondiente por:

```erb
<%# ── Ministerios ── %>
<% if policy(@member).edit? %>
  <turbo-frame id="member-ministries-<%= @member.public_id.first(8) %>" class="block">
    <section class="rounded-xl border border-slate-200 bg-white shadow-card overflow-hidden">
      <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
        <h2 class="text-sm font-semibold text-slate-900">Ministerios</h2>
        <span class="text-xs font-medium text-slate-400"><%= @ministry_memberships.size %></span>
      </div>

      <%= form_with url: assign_ministries_church_admin_member_path(@church, @member), method: :patch do %>
        <div data-controller="ministry-picker"
             data-ministry-picker-url-value="<%= search_church_admin_ministries_path(@church) %>">

          <div class="border-b border-slate-100 px-5 py-3">
            <div class="flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 focus-within:border-violet-400 focus-within:bg-white focus-within:ring-2 focus-within:ring-violet-200 transition-colors">
              <svg class="h-3.5 w-3.5 shrink-0 text-slate-400" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
              </svg>
              <input type="text"
                     placeholder="Buscar ministerio..."
                     autocomplete="off"
                     data-ministry-picker-target="input"
                     data-action="input->ministry-picker#search keydown->ministry-picker#keydown"
                     class="w-full bg-transparent py-1.5 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none">
            </div>
            <div class="relative">
              <turbo-frame id="ministry-results-<%= @member.public_id.first(8) %>"
                           data-ministry-picker-target="results"
                           class="absolute left-0 right-0 z-20 mt-1 block max-h-52 overflow-auto rounded-xl border border-slate-200 bg-white shadow-card empty:hidden">
              </turbo-frame>
            </div>
          </div>

          <div class="px-5 py-2">
            <div data-ministry-picker-target="emptyState"
                 class="<%= @ministry_memberships.any? ? 'hidden' : '' %> py-4 text-center">
              <p class="text-xs text-slate-400">Sin ministerios. Busca arriba para agregar.</p>
            </div>
            <div data-ministry-picker-target="tagsZone" class="divide-y divide-slate-50">
              <% @ministry_memberships.each do |mm| %>
                <%= render "church_admin/members/ministry_tag",
                      name: mm.ministry.name,
                      role: mm.ministry_role,
                      ministry_public_id: mm.ministry.public_id %>
              <% end %>
            </div>
          </div>

          <template data-ministry-picker-target="template">
            <%= render "church_admin/members/ministry_tag",
                  name: "",
                  role: "member",
                  ministry_public_id: nil %>
          </template>
        </div>
      <% end %>
    </section>
  </turbo-frame>

<% else %>
  <section class="rounded-xl border border-slate-200 bg-white shadow-card overflow-hidden">
    <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
      <h2 class="text-base font-semibold text-slate-900">Ministerios</h2>
      <% if @ministry_memberships.any? %>
        <span class="rounded-full bg-violet-50 px-2.5 py-0.5 text-xs font-semibold text-violet-700 ring-1 ring-violet-200">
          <%= @ministry_memberships.size %>
        </span>
      <% end %>
    </div>

    <% if @ministry_memberships.any? %>
      <ul class="divide-y divide-slate-50">
        <% @ministry_memberships.each do |mm| %>
          <li class="flex items-center gap-3 px-6 py-3">
            <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-violet-50 text-violet-600">
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Z" />
              </svg>
            </div>
            <div class="min-w-0 flex-1">
              <%= link_to mm.ministry.name,
                    church_admin_ministry_path(@church, mm.ministry),
                    class: "block truncate text-sm font-semibold text-slate-900 hover:text-violet-700 transition-colors" %>
            </div>
            <%
              role_badge = case mm.ministry_role
                when "leader"    then "bg-violet-50 text-violet-700 ring-violet-200"
                when "co_leader" then "bg-sky-50 text-sky-700 ring-sky-200"
                else                  "bg-slate-100 text-slate-600 ring-slate-200"
              end
            %>
            <span class="shrink-0 inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 <%= role_badge %>">
              <%= ministry_role_label(mm.ministry_role) %>
            </span>
          </li>
        <% end %>
      </ul>
    <% else %>
      <div class="flex flex-col items-center py-8 text-center">
        <div class="flex h-10 w-10 items-center justify-center rounded-full bg-slate-100">
          <svg class="h-5 w-5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Z" />
          </svg>
        </div>
        <p class="mt-2 text-sm text-slate-500">Sin ministerios asignados</p>
      </div>
    <% end %>
  </section>
<% end %>
```

- [ ] **Step 3: Verificar que la vista carga sin errores**

```bash
bin/dev
```

Abrir un show de miembro como admin (owner). Verificar que:
- La sección Ministerios muestra el buscador y los tags de membresías activas.
- Los ministerios ya asignados aparecen como tags con su rol seleccionado.
- Un miembro sin ministerios muestra el estado vacío.

- [ ] **Step 4: Commit**

```bash
git add app/views/church_admin/members/show.html.erb
git commit -m "feat: replace read-only ministry section with interactive picker on member show"
```

---

### Task 6: Stimulus controller ministry-picker

**Files:**
- Create: `app/javascript/controllers/ministry_picker_controller.js`

- [ ] **Step 1: Crear el controlador**

Crear `app/javascript/controllers/ministry_picker_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "tagsZone", "template", "emptyState"]
  static values  = { url: String }

  connect() {
    this.selected = new Set()
    this.tagsZoneTarget.querySelectorAll("[data-tag-id-input]").forEach(el => {
      if (el.value) this.selected.add(el.value)
    })
    this.updateEmptyState()
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    clearTimeout(this._debounce)
    clearTimeout(this._submitTimer)
  }

  search() {
    clearTimeout(this._debounce)
    this._debounce = setTimeout(() => this._doSearch(), 300)
  }

  _doSearch() {
    const q = this.inputTarget.value.trim()
    if (q.length < 2) { this.clearResults(); return }
    const params = new URLSearchParams({ q, frame_id: this.resultsTarget.id })
    this.selected.forEach(id => params.append("exclude[]", id))
    this.resultsTarget.src = `${this.urlValue}?${params}`
  }

  addMinistry(event) {
    event.preventDefault()
    const { publicId, name } = event.currentTarget.dataset
    if (!publicId || this.selected.has(publicId)) return

    const fragment = this.templateTarget.content.cloneNode(true)
    const root = fragment.querySelector("[data-ministry-tag]")

    root.querySelectorAll("[data-tag-name]").forEach(el => { el.textContent = name })

    const idInput = root.querySelector("[data-tag-id-input]")
    if (idInput) {
      idInput.value = publicId
      if (idInput.name) idInput.name = idInput.name.replace(/__ID__/g, publicId)
    }

    root.querySelectorAll("[data-tag-meta]").forEach(el => {
      if (el.name) el.name = el.name.replace(/__ID__/g, publicId)
    })

    this.tagsZoneTarget.appendChild(fragment)
    this.selected.add(publicId)
    this.inputTarget.value = ""
    this.clearResults()
    this.updateEmptyState()
    this._autoSubmit()
  }

  removeTag(event) {
    event.preventDefault()
    const root = event.currentTarget.closest("[data-ministry-tag]")
    const idInput = root.querySelector("[data-tag-id-input]")
    if (idInput?.value) this.selected.delete(idInput.value)
    root.remove()
    this.updateEmptyState()
    this._autoSubmit()
  }

  roleChanged() {
    this._autoSubmit()
  }

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.resultsTarget.querySelector("[data-action~='click->ministry-picker#addMinistry']")?.click()
    } else if (event.key === "Escape") {
      this.inputTarget.value = ""
      this.clearResults()
    }
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.removeAttribute("src")
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.clearResults()
  }

  updateEmptyState() {
    if (!this.hasEmptyStateTarget) return
    this.emptyStateTarget.classList.toggle("hidden", this.selected.size > 0)
  }

  _autoSubmit() {
    clearTimeout(this._submitTimer)
    this._submitTimer = setTimeout(() => {
      this.element.closest("form")?.requestSubmit()
    }, 1500)
  }
}
```

> **Nota sobre auto-discovery:** Stimulus en Rails con importmap-rails descubre automáticamente controladores en `app/javascript/controllers/` que siguen la convención `*_controller.js`. El nombre del controlador se deriva del archivo: `ministry_picker_controller.js` → `ministry-picker`. No se requiere registro manual.

- [ ] **Step 2: Verificar que el controlador se registra**

Con `bin/dev` corriendo, abrir el show de un miembro. Abrir DevTools → Console. No debe aparecer ningún error como `ministry-picker controller not registered`. Abrir DevTools → Elements y verificar que el `<div data-controller="ministry-picker">` existe.

- [ ] **Step 3: Smoke test completo**

Con la app corriendo como admin (owner):

1. Ir al show de un miembro.
2. Escribir 2+ caracteres en el buscador de Ministerios → el dropdown aparece con resultados.
3. Hacer click en un ministerio → aparece como tag con selector de rol.
4. Esperar 1.5s → el formulario se auto-envía, la página recarga con aviso de éxito.
5. Hacer refresh → el ministerio sigue asignado (persistencia confirmada).
6. Cambiar el rol en el select → esperar 1.5s → el nuevo rol persiste tras refresh.
7. Hacer click en X de un tag → desaparece y se auto-guarda → el ministerio queda desasignado.
8. Verificar que los ministerios ya asignados no aparecen en el dropdown.

- [ ] **Step 4: Ejecutar suite de tests completa**

```bash
bundle exec rspec spec/requests/church_admin/member_ministries_spec.rb \
                  spec/requests/church_admin/ministries_search_spec.rb \
                  --format documentation
```

Salida esperada: todos los ejemplos en verde, 0 fallos.

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/ministry_picker_controller.js
git commit -m "feat: add ministry-picker Stimulus controller with auto-submit"
```
