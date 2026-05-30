# Member Form Ministry Assignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir ministerios al form de creación/edición del miembro y corregir el botón X invisible en los tres pickers del form (ocupaciones, habilidades, ministerios).

**Architecture:** Tres cambios coordinados: (1) local `always_show_remove` en los partials para controlar visibilidad del X, (2) value `autoSave` en el Stimulus controller para desactivar auto-submit en el form, (3) sentinels hidden + refactor de `assign_catalog_items` en `MembersController` para procesar ministerios y corregir el bug de "eliminar todos". `set_form_catalog` sigue siendo `only: %i[edit update]` — para `new`/`create` el form usa `Array(@form_ministries)` con nil que equivale a array vacío.

**Tech Stack:** Ruby on Rails 8, Stimulus JS (Hotwire), Tailwind CSS, RSpec (request specs).

---

## File Map

| Archivo | Acción |
|---------|--------|
| `app/views/church_admin/members/_occupation_tag.html.erb` | Modificar — local `always_show_remove` |
| `app/views/church_admin/members/_skill_tag.html.erb` | Modificar — local `always_show_remove` |
| `app/views/church_admin/members/_ministry_tag.html.erb` | Modificar — local `always_show_remove` |
| `app/javascript/controllers/ministry_picker_controller.js` | Modificar — agregar value `autoSave` |
| `app/controllers/church_admin/members_controller.rb` | Modificar — `set_form_catalog` + `assign_catalog_items` + rescues |
| `app/views/church_admin/members/_form.html.erb` | Modificar — sentinels, `always_show_remove: true`, sección ministerios |
| `spec/requests/church_admin/members_catalog_spec.rb` | Crear — specs del comportamiento del form |

---

### Task 1: Local `always_show_remove` en los tres partials

**Files:**
- Modify: `app/views/church_admin/members/_occupation_tag.html.erb`
- Modify: `app/views/church_admin/members/_skill_tag.html.erb`
- Modify: `app/views/church_admin/members/_ministry_tag.html.erb`

El botón X tiene `opacity-0 group-hover/row:opacity-100` — invisible hasta hover. En el form necesita ser siempre visible. El local `always_show_remove: false` controla esto sin cambiar el comportamiento del show.

- [ ] **Step 1: Modificar `_occupation_tag.html.erb`**

Reemplazar la primera línea:

```erb
<%# locals: (name:, offers_services: false, looking_for_work: false, always_show_remove: false) %>
```

Reemplazar el botón X (buscar `data-action="catalog-search#removeTag"`):

```erb
    <button type="button" data-action="catalog-search#removeTag"
            class="shrink-0 rounded-md p-1 text-slate-300 transition-all hover:bg-rose-50 hover:text-rose-500 <%= always_show_remove ? '' : 'opacity-0 group-hover/row:opacity-100' %>">
      <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
      </svg>
    </button>
```

- [ ] **Step 2: Modificar `_skill_tag.html.erb`**

Reemplazar la primera línea:

```erb
<%# locals: (name:, level: "basic", offers_service: false, idx: nil, always_show_remove: false) %>
```

Reemplazar el botón X (buscar `data-action="catalog-search#removeTag"`):

```erb
    <button type="button" data-action="catalog-search#removeTag"
            class="shrink-0 rounded-md p-1 text-slate-300 transition-all hover:bg-rose-50 hover:text-rose-500 <%= always_show_remove ? '' : 'opacity-0 group-hover/row:opacity-100' %>">
      <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
      </svg>
    </button>
```

- [ ] **Step 3: Modificar `_ministry_tag.html.erb`**

Reemplazar la primera línea:

```erb
<%# locals: (name:, role: "member", ministry_public_id: nil, always_show_remove: false) %>
```

Reemplazar el botón X (buscar `data-action="ministry-picker#removeTag"`):

```erb
    <button type="button"
            data-action="ministry-picker#removeTag"
            class="shrink-0 rounded-md p-1 text-slate-300 transition-all hover:bg-rose-50 hover:text-rose-500 <%= always_show_remove ? '' : 'opacity-0 group-hover/row:opacity-100' %>">
      <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
      </svg>
    </button>
```

- [ ] **Step 4: Verificar que el partial no tiene errores de sintaxis**

```bash
bin/rails runner "puts 'ok'"
```

Salida esperada: `ok`

- [ ] **Step 5: Commit**

```bash
git add app/views/church_admin/members/_occupation_tag.html.erb \
        app/views/church_admin/members/_skill_tag.html.erb \
        app/views/church_admin/members/_ministry_tag.html.erb
git commit -m "fix: add always_show_remove local to tag partials for form context"
```

---

### Task 2: Value `autoSave` en `ministry_picker_controller.js`

**Files:**
- Modify: `app/javascript/controllers/ministry_picker_controller.js`

- [ ] **Step 1: Agregar `autoSave` a static values**

En `app/javascript/controllers/ministry_picker_controller.js`, reemplazar:

```javascript
  static values  = { url: String }
```

Por:

```javascript
  static values  = { url: String, autoSave: { type: Boolean, default: true } }
```

- [ ] **Step 2: Actualizar `_autoSubmit()`**

Reemplazar el método `_autoSubmit()` completo:

```javascript
  _autoSubmit() {
    if (!this.autoSaveValue) return
    clearTimeout(this._submitTimer)
    this._submitTimer = setTimeout(() => {
      this.element.closest("form")?.requestSubmit()
    }, 1500)
  }
```

- [ ] **Step 3: Verificar que el show sigue funcionando**

Con `bin/dev` corriendo, abrir el show de un miembro. Agregar un ministerio → debe auto-guardarse en 1.5s. El show no tiene `data-ministry-picker-auto-save-value` → usa el default `true` → auto-submit activo.

- [ ] **Step 4: Commit**

```bash
git add app/javascript/controllers/ministry_picker_controller.js
git commit -m "feat: add autoSave value to ministry-picker controller"
```

---

### Task 3: `MembersController` — sentinels + ministerios + rescues (TDD)

**Files:**
- Create: `spec/requests/church_admin/members_catalog_spec.rb`
- Modify: `app/controllers/church_admin/members_controller.rb`

- [ ] **Step 1: Escribir el spec**

Crear `spec/requests/church_admin/members_catalog_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "ChurchAdmin::Members catalog assignment", type: :request do
  let(:church)     { create(:church) }
  let(:membership) { create(:church_membership, :owner, church:) }
  let(:ministry1)  { create(:ministry, church:, status: "active") }
  let(:ministry2)  { create(:ministry, church:, status: "active") }

  before { sign_in membership.user }

  def base_member_params
    {
      first_name: "Ana",
      last_name: "López",
      second_last_name: "Pérez",
      phone: "88887777",
      birth_date: "1990-01-01",
      gender: "female",
      marital_status: "single",
      children_count: 0,
      member_status: "active",
      official_membership_on: Date.current.to_s
    }
  end

  describe "POST /members (create) con ministerios" do
    it "crea las membresías de ministerio al crear el miembro" do
      post church_admin_members_path(church), params: {
        member: base_member_params,
        ministry_memberships_submitted: "1",
        ministry_memberships: {
          ministry1.public_id => { role: "member" },
          ministry2.public_id => { role: "leader" }
        }
      }
      member = church.members.last
      expect(response).to redirect_to(church_admin_member_path(church, member))
      expect(member.ministry_memberships.active.count).to eq(2)
      expect(member.ministry_memberships.find_by(ministry: ministry1).ministry_role).to eq("member")
      expect(member.ministry_memberships.find_by(ministry: ministry2).ministry_role).to eq("leader")
    end
  end

  describe "PATCH /members/:id (update) con ministerios" do
    let(:member) { create(:member, church:) }
    let!(:existing_mm) do
      create(:ministry_membership, member:, ministry: ministry1, status: "active", ministry_role: "member")
    end

    it "actualiza membresías al enviar la sección con datos" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params,
        ministry_memberships_submitted: "1",
        ministry_memberships: { ministry2.public_id => { role: "leader" } }
      }
      expect(existing_mm.reload.status).to eq("inactive")
      expect(member.ministry_memberships.active.count).to eq(1)
      expect(member.ministry_memberships.find_by(ministry: ministry2).ministry_role).to eq("leader")
    end

    it "desactiva todas las membresías cuando la sección se envía vacía" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params,
        ministry_memberships_submitted: "1"
      }
      expect(existing_mm.reload.status).to eq("inactive")
      expect(member.ministry_memberships.active).to be_empty
    end

    it "no toca las membresías si el sentinel está ausente" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params
      }
      expect(existing_mm.reload.status).to eq("active")
    end
  end

  describe "PATCH /members/:id — fix eliminar todas las ocupaciones" do
    let(:member)     { create(:member, church:) }
    let(:occupation) { create(:occupation, church:, status: "active") }
    let!(:member_occupation) do
      create(:member_occupation, member:, occupation:, church:)
    end

    it "elimina todas las ocupaciones cuando se envía la sección vacía" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params,
        occupation_section_submitted: "1"
      }
      expect(member.member_occupations.reload).to be_empty
    end
  end

  describe "PATCH /members/:id — fix eliminar todas las habilidades" do
    let(:member) { create(:member, church:) }
    let(:skill)  { create(:skill, church:, status: "active") }
    let!(:member_skill) { create(:member_skill, member:, skill:, church:) }

    it "elimina todas las habilidades cuando se envía la sección vacía" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params,
        skill_section_submitted: "1"
      }
      expect(member.member_skills.reload).to be_empty
    end
  end
end
```

- [ ] **Step 2: Ejecutar el spec para confirmar que falla**

```bash
bundle exec rspec spec/requests/church_admin/members_catalog_spec.rb --format documentation
```

Salida esperada: varios fallos (comportamiento aún no implementado).

Si falla por factory faltante (`member_occupation`, `member_skill`): verifica que existen `spec/factories/member_occupations.rb` y `spec/factories/member_skills.rb`. Si no existen, créalos minimales:

```ruby
# spec/factories/member_occupations.rb
FactoryBot.define do
  factory :member_occupation do
    member
    occupation
    church { member.church }
    employment_status { "employed" }
    offers_services { false }
    looking_for_work { false }
  end
end
```

```ruby
# spec/factories/member_skills.rb
FactoryBot.define do
  factory :member_skill do
    member
    skill
    church { member.church }
    level { "basic" }
    offers_service { false }
  end
end
```

- [ ] **Step 3: Modificar `MembersController`**

Abrir `app/controllers/church_admin/members_controller.rb`.

**Cambio 1:** Actualizar `set_form_catalog` para incluir `@form_ministries` (sigue siendo `only: %i[edit update]`, sin cambios al before_action):

```ruby
def set_form_catalog
  @form_occupations = @member.member_occupations
    .includes(:occupation).joins(:occupation)
    .where(occupations: { church_id: @church.id }).order("occupations.name")
  @form_skills = @member.member_skills
    .includes(:skill).joins(:skill)
    .where(skills: { church_id: @church.id }).order("skills.name")
  @form_ministries = @member.ministry_memberships
    .active.includes(:ministry).joins(:ministry)
    .where(ministries: { church_id: @church.id }).order("ministries.name")
end
```

**Cambio 2:** Reemplazar `assign_catalog_items` completo:

```ruby
def assign_catalog_items(member)
  # Ocupaciones
  if params[:occupation_section_submitted] == "1"
    occ_names     = Array(params[:occupation_names]).map(&:strip).reject(&:blank?).uniq
    offers_names  = Array(params[:offers_services])
    looking_names = Array(params[:looking_for_work])
    kept_ids = occ_names.map { |n| @church.occupations.find_or_create_by!(name: n) { |o| o.status = "active" }.id }
    member.member_occupations.where.not(occupation_id: kept_ids).destroy_all
    occ_names.each do |name|
      occ = @church.occupations.find_or_create_by!(name: name) { |o| o.status = "active" }
      mo  = member.member_occupations.find_or_initialize_by(occupation: occ, church: @church)
      mo.employment_status = "employed" if mo.new_record?
      mo.offers_services   = offers_names.include?(name)
      mo.looking_for_work  = looking_names.include?(name)
      mo.save!
    end
  end

  # Habilidades
  if params[:skill_section_submitted] == "1"
    skill_data = Array(params[:skills])
      .map { |s| { name: s[:name].to_s.strip, level: s[:level].to_s.presence || "basic", offers_service: s[:offers_service] == "1" } }
      .reject { |s| s[:name].blank? }.uniq { |s| s[:name] }
    kept_ids = skill_data.map { |s| @church.skills.find_or_create_by!(name: s[:name]) { |sk| sk.status = "active" }.id }
    member.member_skills.where.not(skill_id: kept_ids).destroy_all
    skill_data.each do |s|
      sk = @church.skills.find_or_create_by!(name: s[:name]) { |sk| sk.status = "active" }
      ms = member.member_skills.find_or_initialize_by(skill: sk, church: @church)
      ms.level = s[:level]
      ms.offers_service = s[:offers_service]
      ms.save!
    end
  end

  # Ministerios
  return unless params[:ministry_memberships_submitted] == "1"

  raw = params.key?(:ministry_memberships) ? params[:ministry_memberships].to_unsafe_h : {}
  entries = raw.map { |pub_id, attrs|
    { public_id: pub_id.to_s, role: (attrs["role"].presence || "member").to_s }
  }.reject { |e| e[:public_id].blank? }.uniq { |e| e[:public_id] }
  ministries = entries.map { |e| @church.ministries.active.find_by!(public_id: e[:public_id]) }
  member.ministry_memberships.active
    .where.not(ministry_id: ministries.map(&:id))
    .find_each(&:inactive!)
  entries.each do |e|
    ministry = ministries.find { |m| m.public_id == e[:public_id] }
    mm = member.ministry_memberships.find_or_initialize_by(ministry:)
    mm.ministry_role = e[:role]
    mm.status = "active"
    mm.save!
  end
end
```

**Cambio 3:** Agregar `rescue ActiveRecord::RecordNotFound` a `create` y `update`. Estas acciones llaman a `assign_catalog_items` después de guardar el miembro. Si se envía un `public_id` de ministerio de otra iglesia, `find_by!` lanza `RecordNotFound`. El miembro ya fue guardado en ese punto — es un edge case de manipulación del form.

```ruby
def create
  @member = @church.members.new(member_params)
  authorize @member

  if @member.save
    assign_catalog_items(@member)
    redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.created")
  else
    render :new, status: :unprocessable_content
  end
rescue ActiveRecord::RecordNotFound
  redirect_to church_admin_member_path(@church, @member),
    alert: t("church_admin.member_ministries.invalid_ministry")
end

def update
  authorize @member

  if @member.update(member_params)
    assign_catalog_items(@member)
    redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.updated")
  else
    render :edit, status: :unprocessable_content
  end
rescue ActiveRecord::RecordNotFound
  redirect_to church_admin_member_path(@church, @member),
    alert: t("church_admin.member_ministries.invalid_ministry")
end
```

- [ ] **Step 4: Ejecutar el spec para confirmar que pasa**

```bash
bundle exec rspec spec/requests/church_admin/members_catalog_spec.rb --format documentation
```

Salida esperada: todos los ejemplos en verde, 0 fallos.

- [ ] **Step 5: Correr suite existente de church_admin para verificar no hay regresiones**

```bash
bundle exec rspec spec/requests/church_admin/ --format progress 2>&1 | tail -5
```

Salida esperada: 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/church_admin/members_controller.rb \
        spec/requests/church_admin/members_catalog_spec.rb
git commit -m "feat: add ministry assignment to member form + fix empty-section sentinel bug"
```

---

### Task 4: Actualizar `_form.html.erb`

**Files:**
- Modify: `app/views/church_admin/members/_form.html.erb`

- [ ] **Step 1: Agregar sentinel + `always_show_remove: true` a la sección de Ocupaciones**

Localizar la sección `<%# Ocupaciones %>` (~línea 183). Dentro del `div data-controller="catalog-search"`, agregar el sentinel inmediatamente después del opening del div:

```erb
<input type="hidden" name="occupation_section_submitted" value="1">
```

Modificar el render de ocupaciones existentes (~línea 217):

```erb
<% Array(@form_occupations).each do |mo| %>
  <%= render "church_admin/members/occupation_tag",
        name: mo.occupation.name,
        offers_services: mo.offers_services,
        looking_for_work: mo.looking_for_work,
        always_show_remove: true %>
<% end %>
```

Modificar el render del template (~línea 226):

```erb
<template data-catalog-search-target="template">
  <%= render "church_admin/members/occupation_tag",
        name: "", offers_services: false, looking_for_work: false,
        always_show_remove: true %>
</template>
```

- [ ] **Step 2: Agregar sentinel + `always_show_remove: true` a la sección de Habilidades**

Localizar la sección `<%# Habilidades %>` (~línea 232). Dentro del `div data-controller="catalog-search"`, agregar:

```erb
<input type="hidden" name="skill_section_submitted" value="1">
```

Modificar el render de habilidades existentes (~línea 266):

```erb
<% Array(@form_skills).each_with_index do |ms, i| %>
  <%= render "church_admin/members/skill_tag",
        name: ms.skill.name,
        level: ms.level,
        offers_service: ms.offers_service,
        idx: i,
        always_show_remove: true %>
<% end %>
```

Modificar el render del template (~línea 276):

```erb
<template data-catalog-search-target="template">
  <%= render "church_admin/members/skill_tag",
        name: "", level: "basic", idx: nil,
        always_show_remove: true %>
</template>
```

- [ ] **Step 3: Agregar la sección de Ministerios antes del bloque Cancelar/Guardar**

Localizar el bloque de botones (~línea 285: `<div class="mt-8 flex justify-end gap-3 border-t...`). Insertar antes de él:

```erb
<%# ── Ministerios ── %>
<section class="rounded-xl border border-slate-200 bg-white p-6 shadow-card">
  <h2 class="text-base font-semibold text-slate-900">Ministerios</h2>
  <p class="mt-1 text-sm text-slate-500">Asigna el miembro a ministerios de la iglesia.</p>

  <input type="hidden" name="ministry_memberships_submitted" value="1">

  <div class="mt-4"
       data-controller="ministry-picker"
       data-ministry-picker-url-value="<%= search_church_admin_ministries_path(@church) %>"
       data-ministry-picker-auto-save-value="false">

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
      <turbo-frame id="ministry-results-form"
                   data-ministry-picker-target="results"
                   class="absolute left-0 right-0 z-20 mt-1 block max-h-48 overflow-auto rounded-xl border border-slate-200 bg-white shadow-card empty:hidden">
      </turbo-frame>
    </div>

    <div class="mt-3">
      <div data-ministry-picker-target="emptyState"
           class="<%= defined?(@form_ministries) && @form_ministries&.any? ? 'hidden' : '' %> py-3 text-center">
        <p class="text-xs text-slate-400">Sin ministerios asignados.</p>
      </div>
      <div data-ministry-picker-target="tagsZone" class="divide-y divide-slate-50">
        <% Array(@form_ministries).each do |mm| %>
          <%= render "church_admin/members/ministry_tag",
                name: mm.ministry.name,
                role: mm.ministry_role,
                ministry_public_id: mm.ministry.public_id,
                always_show_remove: true %>
        <% end %>
      </div>
    </div>

    <template data-ministry-picker-target="template">
      <%= render "church_admin/members/ministry_tag",
            name: "",
            role: "member",
            ministry_public_id: nil,
            always_show_remove: true %>
    </template>
  </div>
</section>
```

- [ ] **Step 4: Verificar que el form carga sin errores**

```bash
bin/dev
```

Abrir el form de creación (`/churches/.../members/new`). Verificar:
- Sección "Ministerios" visible con buscador y estado vacío.
- Escribir 2+ chars en el buscador → dropdown con resultados.
- Hacer click en un ministerio → aparece como tag con X siempre visible.
- Hacer click en X → el tag desaparece (sin auto-submit).
- Verificar que ocupaciones y habilidades existentes muestran X siempre visible.

Abrir form de edición de un miembro con ministerios:
- Los ministerios asignados aparecen como tags con X visible.
- Hacer click en X → desaparece.
- Guardar → los ministerios persisten correctamente.

- [ ] **Step 5: Commit**

```bash
git add app/views/church_admin/members/_form.html.erb
git commit -m "feat: add ministry section to member form with always-visible remove button"
```

- [ ] **Step 6: Correr suite completa de specs**

```bash
bundle exec rspec spec/requests/church_admin/members_catalog_spec.rb \
                  spec/requests/church_admin/member_ministries_spec.rb \
                  spec/requests/church_admin/ministries_search_spec.rb \
                  --format documentation
```

Salida esperada: todos en verde, 0 fallos.
