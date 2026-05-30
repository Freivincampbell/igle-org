# Diseño: Ministerios en el form del miembro + fix botón X

**Fecha:** 2026-05-30  
**Estado:** Aprobado

## Contexto

El show del miembro ya tiene un picker inline de ministerios con auto-guardado. El form de creación/edición (`_form.html.erb`) tiene ocupaciones y habilidades pero no ministerios. Además, el botón X para eliminar ítems en el form es invisible hasta hacer hover (UX confusa), y si se eliminan TODOS los ítems de una sección y se guarda, el controller no actualiza la DB.

## Cambios requeridos

### 1. `ministry_picker_controller.js` — agregar `autoSave` value

```javascript
static values = { url: String, autoSave: { type: Boolean, default: true } }

_autoSubmit() {
  if (!this.autoSaveValue) return
  clearTimeout(this._submitTimer)
  this._submitTimer = setTimeout(() => {
    this.element.closest("form")?.requestSubmit()
  }, 1500)
}
```

El show sigue funcionando sin cambios (default `true`). El form pasa `data-ministry-picker-auto-save-value="false"`.

### 2. Fix botón X en partials

Agregar local `always_show_remove: false` a los tres partials:
- `app/views/church_admin/members/_skill_tag.html.erb`
- `app/views/church_admin/members/_occupation_tag.html.erb`
- `app/views/church_admin/members/_ministry_tag.html.erb`

El botón X aplica clases de visibilidad condicionalmente:
```erb
<%# locals: (..., always_show_remove: false) %>
<button type="button" data-action="...*#removeTag"
        class="shrink-0 rounded-md p-1 text-slate-300 transition-all hover:bg-rose-50 hover:text-rose-500
               <%= always_show_remove ? '' : 'opacity-0 group-hover/row:opacity-100' %>">
```

**En el show** (renders existentes): no pasar `always_show_remove` → default `false` → hover reveal (comportamiento actual).
**En el form** (renders nuevos): pasar `always_show_remove: true` → siempre visible.

### 3. Sentinels en `_form.html.erb`

Agregar un hidden field por sección dentro de los bloques correspondientes:
```html
<input type="hidden" name="occupation_section_submitted" value="1">
<input type="hidden" name="skill_section_submitted" value="1">
<input type="hidden" name="ministry_memberships_submitted" value="1">
```

Esto permite al controller distinguir "sección enviada vacía (eliminar todos)" de "sección no presente en el form".

### 4. `MembersController` — tres cambios

#### 4a. `set_form_catalog` — cargar `@form_ministries`

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

`set_form_catalog` debe ser llamado en `before_action` para `new`, `create`, `edit`, `update`.

#### 4b. `assign_catalog_items` — fix sentinels para ocupaciones y habilidades

Reemplazar los guards `unless occ_names.empty?` y `unless skill_data.empty?` por verificación del sentinel:

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
  if params[:ministry_memberships_submitted] == "1"
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
end
```

Nota: el bloque de ministerios usa `inactive!` (soft-delete) mientras que ocupaciones/habilidades usan `destroy_all` — comportamiento preexistente, no se cambia.

#### 4c. Rescue `RecordNotFound` en `create` y `update`

El bloque de ministerios en `assign_catalog_items` puede lanzar `ActiveRecord::RecordNotFound` si se envía un `public_id` de un ministerio de otra iglesia. En las acciones `create` y `update` del controller, envolver la llamada a `assign_catalog_items` en un `rescue`:

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
```

Misma estructura en `update`. El miembro ya fue guardado antes de la excepción — es un edge case que solo ocurre con manipulación del form, no en uso normal.

### 5. `_form.html.erb` — nueva sección Ministerios

Agregar antes del botón Guardar, después de "Ocupaciones y habilidades":

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

    <div class="flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3
                focus-within:border-violet-400 focus-within:bg-white focus-within:ring-2
                focus-within:ring-violet-200 transition-colors">
      <svg class="h-3.5 w-3.5 shrink-0 text-slate-400" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
      </svg>
      <input type="text" placeholder="Buscar ministerio..."
             autocomplete="off"
             data-ministry-picker-target="input"
             data-action="input->ministry-picker#search keydown->ministry-picker#keydown"
             class="w-full bg-transparent py-1.5 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none">
    </div>
    <div class="relative">
      <turbo-frame id="ministry-results-form"
                   data-ministry-picker-target="results"
                   class="absolute left-0 right-0 z-20 mt-1 block max-h-48 overflow-auto
                          rounded-xl border border-slate-200 bg-white shadow-card empty:hidden">
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
            name: "", role: "member", ministry_public_id: nil, always_show_remove: true %>
    </template>
  </div>
</section>
```

También agregar sentinels de ocupaciones y habilidades en sus secciones del form, y pasar `always_show_remove: true` a todos los renders de tags existentes en el form.

## Archivos a crear/modificar

| Archivo | Acción |
|---------|--------|
| `app/javascript/controllers/ministry_picker_controller.js` | Modificar — agregar `autoSave` value |
| `app/views/church_admin/members/_skill_tag.html.erb` | Modificar — local `always_show_remove` |
| `app/views/church_admin/members/_occupation_tag.html.erb` | Modificar — local `always_show_remove` |
| `app/views/church_admin/members/_ministry_tag.html.erb` | Modificar — local `always_show_remove` |
| `app/controllers/church_admin/members_controller.rb` | Modificar — `set_form_catalog` + `assign_catalog_items` |
| `app/views/church_admin/members/_form.html.erb` | Modificar — sección ministerios + sentinels + `always_show_remove: true` |

## Testing

- Spec request: `create` con ministerios → membresías creadas
- Spec request: `update` con ministerios → membresías actualizadas
- Spec request: `update` eliminando todos los ministerios (sentinel presente, params vacíos) → membresías desactivadas
- Spec request: `update` eliminando todos las ocupaciones → `member_occupations` eliminadas
- Spec request: ministerio de otra iglesia en el form → manejo graceful (sin crash)
- No se requieren specs de JS (la lógica JS no cambia en esencia)
