# Búsqueda de Miembros con Autocomplete — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar todos los checkboxes y `<select>` de asignación de miembros (familias, ministerios, junta directiva, responsable de evento, asistencia) por un patrón consistente de búsqueda tipo search-as-you-type con etiquetas (tags).

**Architecture:** Rails 8 + Hotwire. Un endpoint `members#search` devuelve resultados dentro de un `<turbo-frame>`. Un Stimulus controller `member-search` consume esos resultados, agrega/quita tags (clonando un `<template>` por vista) y mantiene los mismos parámetros de formulario que hoy, así los service objects no cambian. La asistencia usa un filtro client-side puro (`attendance-filter`). Un partial compartido `_member_tag` y helpers de avatar garantizan consistencia visual.

**Tech Stack:** Ruby 3.4, Rails 8.1, Stimulus (importmap, auto-registro vía `eagerLoadControllersFrom`), Turbo Frames, pg_search, Tailwind, RSpec/FactoryBot.

**Branch:** `feature/member-search-ui`

---

## File Structure

| Archivo | Responsabilidad |
|---|---|
| `app/models/member.rb` (mod) | Scope `search_by_name` vía pg_search |
| `app/controllers/church_admin/members_controller.rb` (mod) | Acción `search` |
| `config/routes.rb` (mod) | `get :search` en collection de members |
| `app/helpers/application_helper.rb` (mod) | `member_initials`, `member_avatar_color` |
| `app/views/shared/_member_tag.html.erb` (new) | Pill de miembro (avatar+nombre+meta+×), usado server-side y como `<template>` |
| `app/views/church_admin/members/search.html.erb` (new) | Resultados dentro de `<turbo-frame>` |
| `app/javascript/controllers/member_search_controller.js` (new) | Búsqueda + tags |
| `app/javascript/controllers/attendance_filter_controller.js` (new) | Filtro client-side de asistencia |
| `app/views/church_admin/families/show.html.erb` (mod) | Tag search (multi, meta=relación, primary radio) |
| `app/views/church_admin/ministries/show.html.erb` (mod) | Tag search (multi, meta=rol) |
| `app/views/church_admin/boards/show.html.erb` (mod) | Tag search por cargo (single) |
| `app/views/church_admin/events/_form.html.erb` (mod) | Tag search responsable (single) |
| `app/views/church_admin/events/attendance.html.erb` (mod) | Lista filtrable con secciones RSVP |

**Contrato de parámetros (NO cambia):** `family[member_public_ids][]` + `family[member_relationships][ID]` + `family[primary_contact_public_id]`; `ministry[member_public_ids][]` + `ministry[member_roles][ID]`; `board[positions][CARGO]`; `event[responsible_member_public_id]`; `attendance[member_ids][]`.

---

## Task 1: Scope `search_by_name` en Member (pg_search)

**Files:**
- Modify: `app/models/member.rb`
- Test: `spec/models/member_spec.rb`

- [ ] **Step 1: Escribir el test que falla**

En `spec/models/member_spec.rb`, agregar dentro del `RSpec.describe Member` (si el archivo no existe, crearlo con `require "rails_helper"` y el bloque describe):

```ruby
  describe ".search_by_name" do
    it "encuentra miembros por prefijo de nombre o apellido" do
      church = create(:church)
      ana = create(:member, church:, first_name: "Ana", last_name: "Rojas")
      _luis = create(:member, church:, first_name: "Luis", last_name: "Mora")

      results = church.members.search_by_name("ro")

      expect(results).to include(ana)
      expect(results).not_to include(_luis)
    end

    it "ignora mayúsculas" do
      church = create(:church)
      ana = create(:member, church:, first_name: "Ana", last_name: "Rojas")

      expect(church.members.search_by_name("ANA")).to include(ana)
    end
  end
```

- [ ] **Step 2: Correr el test para verificar que falla**

Run: `docker compose exec web bundle exec rspec spec/models/member_spec.rb -e "search_by_name"`
Expected: FAIL con `NoMethodError: undefined method 'search_by_name'`

- [ ] **Step 3: Agregar el scope al modelo**

En `app/models/member.rb`, después de `include PublicIdentifiable` (línea 3) agregar:

```ruby
  include PgSearch::Model
```

Y después del bloque de `scope :ordered` (línea ~43) agregar:

```ruby
  pg_search_scope :search_by_name,
    against: %i[first_name middle_name last_name second_last_name],
    using: { tsearch: { prefix: true } }
```

- [ ] **Step 4: Correr el test para verificar que pasa**

Run: `docker compose exec web bundle exec rspec spec/models/member_spec.rb -e "search_by_name"`
Expected: PASS (2 examples, 0 failures)

- [ ] **Step 5: Commit**

```bash
git add app/models/member.rb spec/models/member_spec.rb
git commit -m "feat: scope search_by_name en Member con pg_search"
```

---

## Task 2: Endpoint `members#search` + ruta + vista de resultados

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/church_admin/members_controller.rb`
- Create: `app/views/church_admin/members/search.html.erb`
- Modify: `app/helpers/application_helper.rb` (helpers de avatar — necesarios para la vista)
- Test: `spec/requests/church_admin/members_spec.rb`

- [ ] **Step 1: Agregar helpers de avatar**

En `app/helpers/application_helper.rb`, dentro del `module ApplicationHelper`, agregar:

```ruby
  AVATAR_COLORS = %w[
    bg-blue-500 bg-emerald-500 bg-amber-500 bg-violet-500
    bg-rose-500 bg-cyan-500 bg-indigo-500 bg-teal-500
  ].freeze

  def member_initials(member)
    [ member.first_name, member.last_name ]
      .compact_blank
      .map { |n| n.first&.upcase }
      .join
      .presence || "?"
  end

  def member_avatar_color(public_id)
    AVATAR_COLORS[public_id.to_s.bytes.sum % AVATAR_COLORS.size]
  end
```

- [ ] **Step 2: Agregar la ruta**

En `config/routes.rb`, cambiar el bloque de members (línea ~38) para agregar un `collection`. Queda:

```ruby
      resources :members, param: :public_id, only: %i[index show new create edit update] do
        collection do
          get :search
        end
        member do
          patch :activate
          patch :deactivate
        end
      end
```

- [ ] **Step 3: Escribir el request spec que falla**

En `spec/requests/church_admin/members_spec.rb`, agregar antes del último `end`:

```ruby
  describe "GET /churches/:church_public_id/admin/members/search" do
    it "devuelve solo miembros que coinciden con q" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ana = create(:member, church:, first_name: "Ana", last_name: "Rojas")
      _luis = create(:member, church:, first_name: "Luis", last_name: "Mora")

      sign_in membership.user

      get search_church_admin_members_path(church), params: { q: "ana" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ana.full_name)
      expect(response.body).not_to include("Luis")
    end

    it "excluye los public_ids enviados en exclude[]" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ana = create(:member, church:, first_name: "Ana", last_name: "Rojas")

      sign_in membership.user

      get search_church_admin_members_path(church), params: { q: "ana", exclude: [ ana.public_id ] }

      expect(response.body).not_to include(ana.full_name)
    end

    it "no busca con menos de 2 caracteres" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      create(:member, church:, first_name: "Ana", last_name: "Rojas")

      sign_in membership.user

      get search_church_admin_members_path(church), params: { q: "a" }

      expect(response.body).not_to include("Rojas")
    end

    it "no expone miembros de otra iglesia" do
      church_a = create(:church)
      church_b = create(:church)
      membership = create(:church_membership, :owner, church: church_a)
      _otro = create(:member, church: church_b, first_name: "Ana", last_name: "Externa")

      sign_in membership.user

      get search_church_admin_members_path(church_a), params: { q: "ana" }

      expect(response.body).not_to include("Externa")
    end
  end
```

- [ ] **Step 4: Correr el test para verificar que falla**

Run: `docker compose exec web bundle exec rspec spec/requests/church_admin/members_spec.rb -e "search"`
Expected: FAIL (la acción `search` no existe / ruta no definida)

- [ ] **Step 5: Implementar la acción search**

En `app/controllers/church_admin/members_controller.rb`, agregar la acción después de `index` (línea ~12):

```ruby
    def search
      authorize Member

      query = params[:q].to_s.strip
      @results = if query.length < 2
        Member.none
      else
        policy_scope(Member)
          .where(church: @church)
          .where.not(public_id: Array(params[:exclude]))
          .search_by_name(query)
          .reorder(:last_name, :first_name)
          .limit(10)
      end

      @frame_id = params[:frame_id].to_s.gsub(/[^a-zA-Z0-9_-]/, "").presence || "member-search-results"

      render layout: false
    end
```

- [ ] **Step 6: Crear la vista de resultados**

Crear `app/views/church_admin/members/search.html.erb`:

```erb
<%= turbo_frame_tag @frame_id do %>
  <% if @results.any? %>
    <ul class="max-h-64 overflow-auto divide-y divide-slate-100">
      <% @results.each do |member| %>
        <li>
          <button type="button"
                  class="flex w-full items-center gap-3 px-3 py-2 text-left hover:bg-violet-50"
                  data-action="click->member-search#addMember"
                  data-public-id="<%= member.public_id %>"
                  data-name="<%= member.full_name %>"
                  data-initials="<%= member_initials(member) %>"
                  data-color="<%= member_avatar_color(member.public_id) %>">
            <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[11px] font-bold text-white <%= member_avatar_color(member.public_id) %>">
              <%= member_initials(member) %>
            </span>
            <span class="min-w-0 flex-1">
              <span class="block truncate text-sm font-medium text-slate-900"><%= member.full_name %></span>
              <span class="block truncate text-xs text-slate-400"><%= member.email.presence || member.phone %></span>
            </span>
          </button>
        </li>
      <% end %>
    </ul>
  <% elsif params[:q].to_s.strip.length >= 2 %>
    <p class="px-3 py-4 text-center text-sm text-slate-400">Sin resultados para «<%= params[:q] %>»</p>
  <% end %>
<% end %>
```

- [ ] **Step 7: Correr el test para verificar que pasa**

Run: `docker compose exec web bundle exec rspec spec/requests/church_admin/members_spec.rb -e "search"`
Expected: PASS (4 examples, 0 failures)

- [ ] **Step 8: Commit**

```bash
git add config/routes.rb app/controllers/church_admin/members_controller.rb \
  app/views/church_admin/members/search.html.erb \
  app/helpers/application_helper.rb \
  spec/requests/church_admin/members_spec.rb
git commit -m "feat: endpoint members#search con resultados en turbo-frame"
```

---

## Task 3: Partial compartido `_member_tag`

**Files:**
- Create: `app/views/shared/_member_tag.html.erb`

El partial sirve tanto para tags renderizados en servidor (miembros ya asignados) como para el `<template>` que clona el JS. Cuando `public_id == "__ID__"` es el molde de template.

- [ ] **Step 1: Crear el partial**

Crear `app/views/shared/_member_tag.html.erb`:

```erb
<%#
  Locals:
    public_id       String  — real o "__ID__" (template)
    name            String
    initials        String
    avatar_color    String  — clase tailwind bg-*
    ids_field       String  — name del hidden que lleva el public_id (array o key simple)
    meta_field      String  — name del select de metadata (con "__ID__" si template), o nil
    meta_options    Array    — [[label, value], ...] o nil
    meta_selected   String  — valor seleccionado, o nil
    primary_field   String  — name del radio de contacto principal, o nil
    primary_checked Boolean
%>
<span data-member-tag
      class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-slate-50 py-1 pl-1 pr-2 text-sm">
  <span data-tag-avatar
        class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-[10px] font-bold text-white <%= avatar_color %>">
    <span data-tag-initials><%= initials %></span>
  </span>
  <span data-tag-name class="font-medium text-slate-800"><%= name %></span>

  <input type="hidden" data-tag-id-input name="<%= ids_field %>" value="<%= public_id == "__ID__" ? "" : public_id %>">

  <% if meta_field.present? %>
    <select data-tag-meta name="<%= meta_field %>"
            class="border-0 bg-transparent py-0 pl-1 pr-5 text-xs font-medium text-slate-500 focus:ring-0">
      <% Array(meta_options).each do |label, value| %>
        <option value="<%= value %>" <%= "selected" if value == meta_selected %>><%= label %></option>
      <% end %>
    </select>
  <% end %>

  <% if primary_field.present? %>
    <label class="flex items-center gap-1 text-xs text-slate-500">
      <input type="radio" data-tag-primary name="<%= primary_field %>"
             value="<%= public_id == "__ID__" ? "" : public_id %>" <%= "checked" if primary_checked %>>
      contacto
    </label>
  <% end %>

  <button type="button" data-action="member-search#removeTag"
          class="ml-1 text-slate-400 hover:text-rose-500" aria-label="Quitar">
    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M18 6 6 18M6 6l12 12"/></svg>
  </button>
</span>
```

- [ ] **Step 2: Verificar que el partial renderiza sin error**

Run:
```bash
docker compose exec web bin/rails runner '
  html = ApplicationController.render(
    partial: "shared/member_tag",
    locals: { public_id: "__ID__", name: "", initials: "", avatar_color: "bg-blue-500",
              ids_field: "family[member_public_ids][]", meta_field: "family[member_relationships][__ID__]",
              meta_options: [["Hijo/a","child"]], meta_selected: "child",
              primary_field: "family[primary_contact_public_id]", primary_checked: false }
  )
  puts html.include?("data-member-tag") ? "OK" : "FAIL"
'
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add app/views/shared/_member_tag.html.erb
git commit -m "feat: partial compartido _member_tag"
```

---

## Task 4: Stimulus controller `member-search`

**Files:**
- Create: `app/javascript/controllers/member_search_controller.js`

- [ ] **Step 1: Crear el controller**

Crear `app/javascript/controllers/member_search_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="member-search"
export default class extends Controller {
  static targets = ["input", "results", "tagsZone", "template", "searchArea"]
  static values = {
    url: String,
    maxSelections: { type: Number, default: 0 }
  }

  connect() {
    this.selected = new Set()
    this.tagsZoneTarget.querySelectorAll("[data-tag-id-input]").forEach((input) => {
      if (input.value) this.selected.add(input.value)
    })
    this.updateSearchAreaVisibility()
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  search() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.performSearch(), 300)
  }

  performSearch() {
    const q = this.inputTarget.value.trim()
    if (q.length < 2) {
      this.clearResults()
      return
    }
    const params = new URLSearchParams()
    params.set("q", q)
    params.set("frame_id", this.resultsTarget.id)
    this.selected.forEach((id) => params.append("exclude[]", id))
    this.resultsTarget.src = `${this.urlValue}?${params.toString()}`
  }

  addMember(event) {
    event.preventDefault()
    const { publicId, name, initials, color } = event.currentTarget.dataset
    if (!publicId || this.selected.has(publicId)) return

    const fragment = this.templateTarget.content.cloneNode(true)
    const root = fragment.querySelector("[data-member-tag]")

    root.querySelector("[data-tag-id-input]").value = publicId

    const nameEl = root.querySelector("[data-tag-name]")
    if (nameEl) nameEl.textContent = name

    const initialsEl = root.querySelector("[data-tag-initials]")
    if (initialsEl) initialsEl.textContent = initials

    const avatarEl = root.querySelector("[data-tag-avatar]")
    if (avatarEl && color) avatarEl.className = avatarEl.className.replace(/bg-\S+/, color)

    root.querySelectorAll("[data-tag-meta]").forEach((el) => {
      if (el.name) el.name = el.name.replace("__ID__", publicId)
    })

    const primaryEl = root.querySelector("[data-tag-primary]")
    if (primaryEl) primaryEl.value = publicId

    this.tagsZoneTarget.appendChild(fragment)
    this.selected.add(publicId)

    this.inputTarget.value = ""
    this.clearResults()
    this.updateSearchAreaVisibility()
    if (this.hasSearchAreaTarget && !this.searchAreaTarget.hidden) this.inputTarget.focus()
  }

  removeTag(event) {
    event.preventDefault()
    const root = event.currentTarget.closest("[data-member-tag]")
    const idInput = root.querySelector("[data-tag-id-input]")
    if (idInput && idInput.value) this.selected.delete(idInput.value)
    root.remove()
    this.updateSearchAreaVisibility()
  }

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      const first = this.resultsTarget.querySelector("[data-action~='click->member-search#addMember']")
      if (first) first.click()
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

  updateSearchAreaVisibility() {
    if (!this.hasSearchAreaTarget) return
    const atMax = this.maxSelectionsValue > 0 && this.selected.size >= this.maxSelectionsValue
    this.searchAreaTarget.hidden = atMax
  }
}
```

- [ ] **Step 2: Verificar sintaxis JS**

Run: `node --check app/javascript/controllers/member_search_controller.js`
Expected: sin salida (sintaxis válida)

- [ ] **Step 3: Commit**

```bash
git add app/javascript/controllers/member_search_controller.js
git commit -m "feat: Stimulus controller member-search"
```

---

## Task 5: Stimulus controller `attendance-filter`

**Files:**
- Create: `app/javascript/controllers/attendance_filter_controller.js`

- [ ] **Step 1: Crear el controller**

Crear `app/javascript/controllers/attendance_filter_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="attendance-filter"
export default class extends Controller {
  static targets = ["input", "row", "count", "section", "checkbox"]

  connect() {
    this.updateCount()
  }

  filter() {
    const q = this.inputTarget.value.trim().toLowerCase()
    this.rowTargets.forEach((row) => {
      const name = (row.dataset.memberName || "").toLowerCase()
      row.hidden = q.length > 0 && !name.includes(q)
    })
    this.sectionTargets.forEach((section) => {
      const rows = section.querySelectorAll("[data-attendance-filter-target~='row']")
      const anyVisible = Array.from(rows).some((r) => !r.hidden)
      section.hidden = !anyVisible
    })
  }

  updateCount() {
    if (!this.hasCountTarget) return
    this.countTarget.textContent = this.checkboxTargets.filter((c) => c.checked).length
  }
}
```

- [ ] **Step 2: Verificar sintaxis JS**

Run: `node --check app/javascript/controllers/attendance_filter_controller.js`
Expected: sin salida

- [ ] **Step 3: Commit**

```bash
git add app/javascript/controllers/attendance_filter_controller.js
git commit -m "feat: Stimulus controller attendance-filter"
```

---

## Task 6: Vista de Familias con tag search

**Files:**
- Modify: `app/views/church_admin/families/show.html.erb`

- [ ] **Step 1: Reemplazar el bloque del formulario**

En `app/views/church_admin/families/show.html.erb`, reemplazar el `<%= form_with ... %>` completo (líneas 32–56, desde `<%= form_with url: members_church_admin_family_path` hasta su `<% end %>`) por:

```erb
    <%= form_with url: members_church_admin_family_path(@church, @family), method: :patch, class: "p-6" do %>
      <% relationship_options = FamilyMember::RELATIONSHIPS.map { |r| [ family_relationship_label(r), r ] } %>
      <div data-controller="member-search"
           data-member-search-url-value="<%= search_church_admin_members_path(@church) %>">

        <div data-member-search-target="tagsZone" class="flex flex-wrap gap-2">
          <% @current_family_members.each do |public_id, fm| %>
            <%= render "shared/member_tag",
                  public_id: public_id,
                  name: fm.member.full_name,
                  initials: member_initials(fm.member),
                  avatar_color: member_avatar_color(public_id),
                  ids_field: "family[member_public_ids][]",
                  meta_field: "family[member_relationships][#{public_id}]",
                  meta_options: relationship_options,
                  meta_selected: fm.relationship,
                  primary_field: "family[primary_contact_public_id]",
                  primary_checked: fm.primary_contact %>
          <% end %>
        </div>

        <template data-member-search-target="template">
          <%= render "shared/member_tag",
                public_id: "__ID__", name: "", initials: "", avatar_color: "bg-slate-400",
                ids_field: "family[member_public_ids][]",
                meta_field: "family[member_relationships][__ID__]",
                meta_options: relationship_options, meta_selected: "other",
                primary_field: "family[primary_contact_public_id]", primary_checked: false %>
        </template>

        <div data-member-search-target="searchArea" class="relative mt-4">
          <input type="text" placeholder="Buscar miembro por nombre..."
                 autocomplete="off"
                 data-member-search-target="input"
                 data-action="input->member-search#search keydown->member-search#keydown"
                 class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:ring-violet-500">
          <turbo-frame id="member-results-family" data-member-search-target="results"
                       class="absolute z-10 mt-1 block w-full rounded-md border border-slate-200 bg-white shadow-lg empty:hidden"></turbo-frame>
        </div>
      </div>

      <% if policy(@family).update? %>
        <div class="mt-6 flex justify-end">
          <%= submit_tag "Guardar miembros", class: "rounded-md bg-slate-950 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800" %>
        </div>
      <% end %>
    <% end %>
```

- [ ] **Step 2: Verificar que la página de familia carga (200) con el buscador**

```bash
docker compose exec web bin/rails runner "
app = Rails.application
s = ActionDispatch::Integration::Session.new(app)
ActionController::Base.allow_forgery_protection = false
u = User.find_by(email: 'genesisadmin@gmail.com')
church = Church.first
family = church.families.first
s.post '/users/sign_in', params: { 'user[email]' => u.email, 'user[password]' => 'password123' }
s.get \"/churches/#{church.public_id}/admin/families/#{family.public_id}\"
puts 'Status: ' + s.response.status.to_s
puts 'Buscador: ' + s.response.body.include?('data-controller=\"member-search\"').to_s
ActionController::Base.allow_forgery_protection = true
" 2>/dev/null
```
Expected: `Status: 200`, `Buscador: true`
(Si no existe una familia con miembros, el buscador igual debe aparecer.)

- [ ] **Step 3: Commit**

```bash
git add app/views/church_admin/families/show.html.erb
git commit -m "feat: tag search en formulario de familias"
```

---

## Task 7: Vista de Ministerios con tag search

**Files:**
- Modify: `app/views/church_admin/ministries/show.html.erb`

- [ ] **Step 1: Reemplazar el formulario de asignación**

En `app/views/church_admin/ministries/show.html.erb`, reemplazar el `<%= form_with url: members_church_admin_ministry_path ... %>` completo (líneas 91–115) por:

```erb
        <%= form_with url: members_church_admin_ministry_path(@church, @ministry), method: :patch, class: "mt-5" do |form| %>
          <% role_options = MinistryMembership.ministry_roles.keys.map { |r| [ ministry_role_label(r), r ] } %>
          <div data-controller="member-search"
               data-member-search-url-value="<%= search_church_admin_members_path(@church) %>">

            <div data-member-search-target="tagsZone" class="flex flex-wrap gap-2">
              <% @active_ministry_memberships.each do |public_id, mm| %>
                <%= render "shared/member_tag",
                      public_id: public_id,
                      name: mm.member.full_name,
                      initials: member_initials(mm.member),
                      avatar_color: member_avatar_color(public_id),
                      ids_field: "ministry[member_public_ids][]",
                      meta_field: "ministry[member_roles][#{public_id}]",
                      meta_options: role_options,
                      meta_selected: mm.ministry_role,
                      primary_field: nil,
                      primary_checked: false %>
              <% end %>
            </div>

            <template data-member-search-target="template">
              <%= render "shared/member_tag",
                    public_id: "__ID__", name: "", initials: "", avatar_color: "bg-slate-400",
                    ids_field: "ministry[member_public_ids][]",
                    meta_field: "ministry[member_roles][__ID__]",
                    meta_options: role_options, meta_selected: "member",
                    primary_field: nil, primary_checked: false %>
            </template>

            <div data-member-search-target="searchArea" class="relative mt-4">
              <input type="text" placeholder="Buscar miembro por nombre..."
                     autocomplete="off"
                     data-member-search-target="input"
                     data-action="input->member-search#search keydown->member-search#keydown"
                     class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:ring-violet-500">
              <turbo-frame id="member-results-ministry" data-member-search-target="results"
                           class="absolute z-10 mt-1 block w-full rounded-md border border-slate-200 bg-white shadow-lg empty:hidden"></turbo-frame>
            </div>
          </div>

          <% if policy(@ministry).edit? %>
            <div class="mt-5 flex justify-end border-t border-slate-200 pt-4">
              <%= form.submit "Guardar asignacion", class: "rounded-md bg-slate-950 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800" %>
            </div>
          <% end %>
        <% end %>
```

- [ ] **Step 2: Verificar que la página de ministerio carga (200) con el buscador**

```bash
docker compose exec web bin/rails runner "
app = Rails.application
s = ActionDispatch::Integration::Session.new(app)
ActionController::Base.allow_forgery_protection = false
u = User.find_by(email: 'genesisadmin@gmail.com')
church = Church.first
ministry = church.ministries.first
s.post '/users/sign_in', params: { 'user[email]' => u.email, 'user[password]' => 'password123' }
s.get \"/churches/#{church.public_id}/admin/ministries/#{ministry.public_id}\"
puts 'Status: ' + s.response.status.to_s
puts 'Buscador: ' + s.response.body.include?('data-controller=\"member-search\"').to_s
ActionController::Base.allow_forgery_protection = true
" 2>/dev/null
```
Expected: `Status: 200`, `Buscador: true`

- [ ] **Step 3: Commit**

```bash
git add app/views/church_admin/ministries/show.html.erb
git commit -m "feat: tag search en formulario de ministerios"
```

---

## Task 8: Vista de Junta Directiva con tag search por cargo

**Files:**
- Modify: `app/views/church_admin/boards/show.html.erb`

Cada cargo es un `member-search` independiente con `maxSelections=1`. El hidden lleva `board[positions][<cargo>]`. Un hidden vacío de fallback (antes del tagsZone) preserva la limpieza cuando se quita el miembro. El service hace `destroy_all`+recreate, así que un valor vacío se ignora.

- [ ] **Step 1: Reemplazar el formulario de cargos**

En `app/views/church_admin/boards/show.html.erb`, reemplazar el `<%= form_with url: positions_church_admin_board_path ... %>` completo (líneas 32–49) por:

```erb
    <%= form_with url: positions_church_admin_board_path(@church, @board), method: :patch, class: "p-6 space-y-3" do %>
      <% BoardMember::POSITIONS.each do |position| %>
        <% current = @current_positions[position] %>
        <% field = "board[positions][#{position}]" %>
        <% frame = "member-results-board-#{position}" %>
        <div class="grid grid-cols-1 items-center gap-3 border-b border-slate-100 pb-3 md:grid-cols-3">
          <label class="text-sm font-medium text-slate-800"><%= board_position_label(position) %></label>
          <div class="md:col-span-2">
            <div data-controller="member-search"
                 data-member-search-url-value="<%= search_church_admin_members_path(@church) %>"
                 data-member-search-max-selections-value="1">

              <input type="hidden" name="<%= field %>" value="">

              <div data-member-search-target="tagsZone" class="flex flex-wrap gap-2">
                <% if current&.member %>
                  <%= render "shared/member_tag",
                        public_id: current.member.public_id,
                        name: current.member.full_name,
                        initials: member_initials(current.member),
                        avatar_color: member_avatar_color(current.member.public_id),
                        ids_field: field,
                        meta_field: nil, meta_options: nil, meta_selected: nil,
                        primary_field: nil, primary_checked: false %>
                <% end %>
              </div>

              <template data-member-search-target="template">
                <%= render "shared/member_tag",
                      public_id: "__ID__", name: "", initials: "", avatar_color: "bg-slate-400",
                      ids_field: field,
                      meta_field: nil, meta_options: nil, meta_selected: nil,
                      primary_field: nil, primary_checked: false %>
              </template>

              <div data-member-search-target="searchArea" class="relative mt-2"<%= " hidden" if current&.member %>>
                <input type="text" placeholder="Asignar miembro..."
                       autocomplete="off"
                       data-member-search-target="input"
                       data-action="input->member-search#search keydown->member-search#keydown"
                       class="w-full rounded-md border border-dashed border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:ring-violet-500">
                <turbo-frame id="<%= frame %>" data-member-search-target="results"
                             class="absolute z-10 mt-1 block w-full rounded-md border border-slate-200 bg-white shadow-lg empty:hidden"></turbo-frame>
              </div>
            </div>
          </div>
        </div>
      <% end %>
      <% if policy(@board).update? %>
        <div class="flex justify-end pt-2">
          <%= submit_tag "Guardar cargos", class: "rounded-md bg-slate-950 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800" %>
        </div>
      <% end %>
    <% end %>
```

Nota: el atributo `hidden` inicial en `searchArea` cuando el cargo ya tiene miembro coincide con la lógica `updateSearchAreaVisibility` del controller (maxSelections=1, ya hay 1 seleccionado).

- [ ] **Step 2: Verificar que la página de junta carga (200) y respeta el contrato de params**

```bash
docker compose exec web bin/rails runner "
app = Rails.application
s = ActionDispatch::Integration::Session.new(app)
ActionController::Base.allow_forgery_protection = false
u = User.find_by(email: 'genesisadmin@gmail.com')
church = Church.first
board = church.boards.first
s.post '/users/sign_in', params: { 'user[email]' => u.email, 'user[password]' => 'password123' }
s.get \"/churches/#{church.public_id}/admin/boards/#{board.public_id}\"
puts 'Status: ' + s.response.status.to_s
puts 'Cargos con buscador: ' + s.response.body.scan('data-controller=\"member-search\"').size.to_s
ActionController::Base.allow_forgery_protection = true
" 2>/dev/null
```
Expected: `Status: 200`, `Cargos con buscador: 8`

- [ ] **Step 3: Commit**

```bash
git add app/views/church_admin/boards/show.html.erb
git commit -m "feat: tag search por cargo en junta directiva"
```

---

## Task 9: Responsable de evento con tag search

**Files:**
- Modify: `app/views/church_admin/events/_form.html.erb`

`event[responsible_member_public_id]` es selección única. Un hidden vacío de fallback antes del tag garantiza que al quitar el responsable se envíe blank (→ nil en el modelo).

- [ ] **Step 1: Reemplazar el bloque del select de responsable**

En `app/views/church_admin/events/_form.html.erb`, reemplazar el `<div>` del responsable (líneas 45–48, el que contiene `form.label :responsible_member_public_id` y `form.select :responsible_member_public_id`) por:

```erb
    <div>
      <%= form.label :responsible_member_public_id, "Responsable (opcional)", class: "block text-sm font-medium text-slate-700" %>
      <% current_responsible = @church.members.active.find_by(public_id: event.responsible_member_public_id) %>
      <div class="mt-1" data-controller="member-search"
           data-member-search-url-value="<%= search_church_admin_members_path(@church) %>"
           data-member-search-max-selections-value="1">

        <input type="hidden" name="event[responsible_member_public_id]" value="">

        <div data-member-search-target="tagsZone" class="flex flex-wrap gap-2">
          <% if current_responsible %>
            <%= render "shared/member_tag",
                  public_id: current_responsible.public_id,
                  name: current_responsible.full_name,
                  initials: member_initials(current_responsible),
                  avatar_color: member_avatar_color(current_responsible.public_id),
                  ids_field: "event[responsible_member_public_id]",
                  meta_field: nil, meta_options: nil, meta_selected: nil,
                  primary_field: nil, primary_checked: false %>
          <% end %>
        </div>

        <template data-member-search-target="template">
          <%= render "shared/member_tag",
                public_id: "__ID__", name: "", initials: "", avatar_color: "bg-slate-400",
                ids_field: "event[responsible_member_public_id]",
                meta_field: nil, meta_options: nil, meta_selected: nil,
                primary_field: nil, primary_checked: false %>
        </template>

        <div data-member-search-target="searchArea" class="relative"<%= " hidden" if current_responsible %>>
          <input type="text" placeholder="Buscar responsable..."
                 autocomplete="off"
                 data-member-search-target="input"
                 data-action="input->member-search#search keydown->member-search#keydown"
                 class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:ring-violet-500">
          <turbo-frame id="member-results-responsible" data-member-search-target="results"
                       class="absolute z-10 mt-1 block w-full rounded-md border border-slate-200 bg-white shadow-lg empty:hidden"></turbo-frame>
        </div>
      </div>
    </div>
```

- [ ] **Step 2: Verificar que `responsible_member_public_id` es accesible en el form**

```bash
docker compose exec web bin/rails runner "
puts Event.new.respond_to?(:responsible_member_public_id)
" 2>/dev/null
```
Expected: `true`
(Si fuera `false`, el método ya se usaba en el select anterior, así que debe existir; confirmar antes de continuar.)

- [ ] **Step 3: Verificar que el form de nuevo evento carga (200)**

```bash
docker compose exec web bin/rails runner "
app = Rails.application
s = ActionDispatch::Integration::Session.new(app)
ActionController::Base.allow_forgery_protection = false
u = User.find_by(email: 'genesisadmin@gmail.com')
church = Church.first
s.post '/users/sign_in', params: { 'user[email]' => u.email, 'user[password]' => 'password123' }
s.get \"/churches/#{church.public_id}/admin/events/new\"
puts 'Status: ' + s.response.status.to_s
puts 'Buscador responsable: ' + s.response.body.include?('member-results-responsible').to_s
ActionController::Base.allow_forgery_protection = true
" 2>/dev/null
```
Expected: `Status: 200`, `Buscador responsable: true`

- [ ] **Step 4: Commit**

```bash
git add app/views/church_admin/events/_form.html.erb
git commit -m "feat: tag search para responsable de evento"
```

---

## Task 10: Asistencia con lista filtrable y secciones RSVP

**Files:**
- Modify: `app/controllers/church_admin/events_controller.rb`
- Modify: `app/views/church_admin/events/attendance.html.erb`

- [ ] **Step 1: Exponer los RSVP confirmados en la acción attendance**

En `app/controllers/church_admin/events_controller.rb`, reemplazar la acción `attendance` (líneas 72–76) por:

```ruby
    def attendance
      authorize @event, :update?
      @members = @church.members.active.ordered
      @attendances_by_member = @event.event_attendances.includes(:member).index_by(&:member_id)
      @confirmed_member_ids = @event.event_rsvps.where(status: "attending").pluck(:member_id).to_set
    end
```

- [ ] **Step 2: Reemplazar la vista de asistencia**

Reemplazar todo el contenido de `app/views/church_admin/events/attendance.html.erb` por:

```erb
<section class="mx-auto w-full max-w-5xl px-6 py-10">
  <div>
    <p class="text-sm font-medium text-slate-500"><%= @church.name %> / <%= @event.title %></p>
    <h1 class="mt-2 text-3xl font-semibold text-slate-950">Registrar asistencia</h1>
    <p class="mt-1 text-sm text-slate-500">Marca los miembros que asistieron al evento.</p>
  </div>

  <%= form_with url: attendance_church_admin_event_path(@church, @event), method: :patch, class: "mt-6",
        data: { controller: "attendance-filter" } do %>

    <div class="mb-4 flex items-center gap-3">
      <div class="relative flex-1">
        <input type="text" placeholder="Filtrar por nombre..."
               autocomplete="off"
               data-attendance-filter-target="input"
               data-action="input->attendance-filter#filter"
               class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:ring-violet-500">
      </div>
      <span class="shrink-0 rounded-full bg-emerald-100 px-3 py-1 text-sm font-semibold text-emerald-700">
        <span data-attendance-filter-target="count">0</span> ✓ / <%= @members.size %>
      </span>
    </div>

    <% confirmed, others = @members.partition { |m| @confirmed_member_ids.include?(m.id) } %>

    <div class="overflow-hidden rounded-lg border border-slate-200 bg-white">
      <% if @members.any? %>
        <% if confirmed.any? %>
          <div data-attendance-filter-target="section">
            <div class="bg-emerald-50 px-4 py-2 text-xs font-semibold uppercase tracking-wide text-emerald-700">
              Confirmaron asistencia (<%= confirmed.size %>)
            </div>
            <% confirmed.each do |member| %>
              <%= render "church_admin/events/attendance_row", member:, attendances_by_member: @attendances_by_member, default_checked: true %>
            <% end %>
          </div>
        <% end %>

        <div data-attendance-filter-target="section">
          <div class="bg-slate-50 px-4 py-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
            Otros miembros (<%= others.size %>)
          </div>
          <% others.each do |member| %>
            <%= render "church_admin/events/attendance_row", member:, attendances_by_member: @attendances_by_member, default_checked: false %>
          <% end %>
        </div>
      <% else %>
        <p class="px-4 py-8 text-center text-slate-500">No hay miembros activos.</p>
      <% end %>
    </div>

    <div class="mt-6 flex justify-end gap-3">
      <%= link_to "Cancelar", church_admin_event_path(@church, @event), class: "rounded-md border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50" %>
      <%= submit_tag "Guardar asistencia", class: "rounded-md bg-slate-950 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800" %>
    </div>
  <% end %>
</section>
```

- [ ] **Step 3: Crear el partial de fila de asistencia**

Crear `app/views/church_admin/events/_attendance_row.html.erb`:

```erb
<%#
  Locals: member, attendances_by_member (Hash member_id => EventAttendance), default_checked (Boolean)
%>
<% recorded = attendances_by_member[member.id] %>
<% checked = recorded ? recorded.attended : default_checked %>
<label data-attendance-filter-target="row" data-member-name="<%= member.full_name %>"
       class="flex items-center gap-3 border-t border-slate-100 px-4 py-3 hover:bg-slate-50">
  <%= check_box_tag "attendance[member_ids][]", member.public_id, checked,
        id: "attendance_member_#{member.public_id}",
        data: { attendance_filter_target: "checkbox", action: "change->attendance-filter#updateCount" },
        class: "h-4 w-4 rounded border-slate-300 text-emerald-600 focus:ring-emerald-500" %>
  <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-xs font-bold text-white <%= member_avatar_color(member.public_id) %>">
    <%= member_initials(member) %>
  </span>
  <span class="text-sm font-medium text-slate-900"><%= member.full_name %></span>
</label>
```

- [ ] **Step 4: Verificar que la página de asistencia carga (200) con el filtro**

```bash
docker compose exec web bin/rails runner "
app = Rails.application
s = ActionDispatch::Integration::Session.new(app)
ActionController::Base.allow_forgery_protection = false
u = User.find_by(email: 'genesisadmin@gmail.com')
church = Church.first
event = church.events.first
s.post '/users/sign_in', params: { 'user[email]' => u.email, 'user[password]' => 'password123' }
s.get \"/churches/#{church.public_id}/admin/events/#{event.public_id}/attendance\"
puts 'Status: ' + s.response.status.to_s
puts 'Filtro: ' + s.response.body.include?('attendance-filter').to_s
ActionController::Base.allow_forgery_protection = true
" 2>/dev/null
```
Expected: `Status: 200`, `Filtro: true`

- [ ] **Step 5: Verificar que el guardado de asistencia sigue funcionando (request spec existente)**

Run: `docker compose exec web bundle exec rspec spec/requests/church_admin/events_spec.rb`
Expected: PASS (sin regresiones; el contrato `attendance[member_ids][]` no cambió)

- [ ] **Step 6: Commit**

```bash
git add app/controllers/church_admin/events_controller.rb \
  app/views/church_admin/events/attendance.html.erb \
  app/views/church_admin/events/_attendance_row.html.erb
git commit -m "feat: asistencia con lista filtrable y secciones RSVP"
```

---

## Task 11: Verificación final e integración

**Files:** ninguno (solo verificación)

- [ ] **Step 1: Suite completa de tests**

Run: `docker compose exec web bundle exec rspec`
Expected: todo verde (0 failures). Atención especial a `spec/requests/church_admin/{families,ministries,boards,events,members}_spec.rb` — los contratos de params no cambiaron, así que deben seguir pasando.

- [ ] **Step 2: RuboCop**

Run: `docker compose exec web bundle exec rubocop app/controllers/church_admin/members_controller.rb app/controllers/church_admin/events_controller.rb app/models/member.rb app/helpers/application_helper.rb`
Expected: sin offenses (o autocorregir con `bundle exec rubocop -a` y revisar)

- [ ] **Step 3: Verificación manual en el navegador (smoke test del flujo completo)**

Levantar la app (`bin/dev` o `docker compose up`) y verificar manualmente en cada pantalla:
1. **Familias** (`/churches/:id/admin/families/:id`): escribir 2+ letras → aparecen resultados → clic agrega tag con select de relación y radio "contacto" → × quita el tag → Guardar persiste correctamente.
2. **Ministerios**: igual, con select de rol (Miembro/Líder/Co-líder).
3. **Junta directiva**: cada cargo permite asignar 1 miembro; al asignar se oculta el buscador de ese cargo; × lo libera; Guardar persiste los 8 cargos.
4. **Evento nuevo/editar**: buscar responsable (single); Guardar persiste.
5. **Asistencia**: filtrar por nombre oculta filas; los confirmados aparecen pre-marcados arriba; el contador "X ✓ / Y" sube/baja al marcar; Guardar persiste.

Confirmar que un miembro ya seleccionado NO reaparece en resultados (exclusión funciona).

- [ ] **Step 4: Verificar que no quedó código muerto**

Confirmar que ya no se usan en las vistas modificadas: `@assignable_members` (familias/ministerios), `@active_member_options` (junta). Estas variables se siguen seteando en los `before_action` pero ya no se consumen en las vistas. **Dejarlas por ahora** (las usa el render de error en `update_members`/`update_positions` que re-renderiza `:show`). Verificar que un guardado con error (ej. miembro duplicado en junta) re-renderiza `show` sin romper:

```bash
docker compose exec web bin/rails runner "
puts 'Vars de fallback intactas — revisar manualmente render :show en error de junta'
" 2>/dev/null
```
Confirmar manualmente: forzar un error de asignación y ver que `show` re-renderiza con el buscador presente (las vars `@current_positions` etc. se repueblan vía `before_action :set_member_options`).

- [ ] **Step 5: Merge del branch**

Una vez todo verde y verificado manualmente, seguir el flujo de `superpowers:finishing-a-development-branch` para decidir merge/PR.

---

## Notas de implementación

- **Auto-registro Stimulus:** `app/javascript/controllers/index.js` usa `eagerLoadControllersFrom("controllers", application)`, así que los nuevos `*_controller.js` se registran solos por nombre de archivo. No tocar `index.js`.
- **Turbo Frame matching:** cada buscador envía `frame_id` con el id de SU `<turbo-frame>` de resultados; `search.html.erb` renderiza la respuesta dentro de un frame con ese mismo id (sanitizado). Por eso los 8 cargos de junta pueden coexistir sin colisión de ids.
- **`empty:hidden`** en el turbo-frame de resultados lo oculta cuando no hay contenido (Tailwind), evitando un borde vacío.
- **Contrato de params inmutable:** ningún service object ni acción de guardado cambia. Si algún test de `families/ministries/boards/events_spec.rb` falla, es señal de que un `name=` de input quedó mal — revisar el partial `_member_tag` y los `ids_field`/`meta_field` pasados.
- **Fallback hidden en single-select:** boards y responsable de evento incluyen `<input type="hidden" name="..." value="">` antes del tagsZone para que quitar el miembro envíe blank (limpieza). En arrays (familias/ministerios) no hace falta: ausencia = `[]` por el default del controller.
```
