# Diseño: Asignación de ministerios desde el show del miembro

**Fecha:** 2026-05-30  
**Estado:** Aprobado

## Contexto

La vista `show` de un miembro ya permite asignar ocupaciones y habilidades mediante paneles inline con auto-guardado (`catalog-search` Stimulus). El objetivo es añadir un panel equivalente para que un administrador pueda asignar al miembro a uno o más ministerios ya creados, eligiendo su rol (miembro, co-líder, líder), sin salir de la vista del miembro.

La dirección inversa (asignar miembros desde el show del ministerio) ya existe vía `Ministries::MemberAssignment` y el controlador Stimulus `member-search`.

## Arquitectura

### Patrón elegido

Nuevo controlador Stimulus `ministry-picker` que combina:
- Selección por `public_id` (como `member-search`): referencia entidades pre-existentes, no crea nuevas
- Auto-guardado con debounce 1500 ms (como `catalog-search`): consistencia UX con skills/ocupaciones

### Flujo de datos

```
[Input búsqueda] → ministry-picker#search (debounce 300ms)
               → GET /churches/:id/ministries/search?q=...&exclude[]=uuid
               → turbo-frame con resultados
[Click resultado] → ministry-picker#addMinistry
               → clona template, rellena public_id + nombre
               → _ministry_tag con select de rol
[Cambio rol / quitar tag] → ministry-picker#roleChanged / removeTag
               → _autoSubmit (1500ms)
               → PATCH assign_ministries_church_admin_member_path
               → MemberMinistriesController#assign
               → upsert MinistryMembership + desactivar las no incluidas
               → redirect con notice
```

## Componentes

### 1. Rutas (`config/routes.rb`)

```ruby
# Búsqueda de ministerios (colección)
resources :ministries, param: :public_id, only: %i[index show new create edit update] do
  collection { get :search }   # ← nuevo
  member do
    patch :activate
    patch :deactivate
    patch :members, action: :update_members
  end
end

# Asignación desde el miembro (segundo bloque resources :members)
resources :members, param: :public_id, only: [] do
  member do
    patch :assign_occupations, controller: "member_occupations", action: :assign
    patch :assign_skills,      controller: "member_skills",      action: :assign
    patch :assign_ministries,  controller: "member_ministries",  action: :assign  # ← nuevo
  end
  ...
end
```

### 2. `MinistriesController#search` (acción nueva)

```ruby
def search
  authorize Ministry, :index?
  skip_policy_scope
  q = params[:q].to_s.strip
  excluded_ids = Array(params[:exclude]).compact_blank
  @results = if q.length >= 2
    @church.ministries.active.search_by_name(q)
      .where.not(public_id: excluded_ids).ordered.limit(8)
  else
    []
  end
  @frame_id = params[:frame_id].to_s.gsub(/[^a-z0-9-]/, "")
  render layout: false
end
```

### 3. `ChurchAdmin::MemberMinistriesController` (nuevo)

```ruby
def assign
  authorize @member, :update?

  entries = params[:ministry_memberships].to_h
    .map { |public_id, attrs| { public_id: public_id.to_s, role: attrs[:role].to_s.presence || "member" } }
    .reject { |e| e[:public_id].blank? }
    .uniq { |e| e[:public_id] }

  ActiveRecord::Base.transaction do
    ministries = entries.map do |e|
      @church.ministries.active.find_by!(public_id: e[:public_id])
    end

    @member.ministry_memberships.active
      .where.not(ministry_id: ministries.map(&:id))
      .find_each(&:inactive!)

    entries.each do |e|
      ministry = ministries.find { |m| m.public_id == e[:public_id] }
      mm = @member.ministry_memberships.find_or_initialize_by(ministry: ministry)
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
```

- Autorización: `authorize @member, :update?` — reutiliza `MemberPolicy`, consistente con skills/ocupaciones.
- Sin borrado físico: membresías excluidas se marcan `inactive!` (regla crítica del proyecto).

### 4. Stimulus: `ministry_picker_controller.js` (nuevo)

**Targets:** `input`, `results`, `tagsZone`, `template`, `emptyState`  
**Values:** `url: String`

Métodos principales:
- `search()` — debounce 300ms → `performSearch()` si >= 2 chars
- `performSearch()` — construye URLSearchParams con `q` y `exclude[]` (Set de public_ids seleccionados), asigna a `resultsTarget.src`
- `addMinistry(event)` — lee `dataset.publicId` y `dataset.name`; clona template; rellena `[data-tag-id-input]` value **y** name (reemplaza `__ID__` → publicId en ambos); reemplaza `__ID__` en `name` attrs de `[data-tag-meta]`; rellena `[data-tag-name]`; appends al tagsZone; `_autoSubmit()`
- `removeTag(event)` — elimina nodo, borra del Set; `_autoSubmit()`
- `roleChanged()` — llama `_autoSubmit()`
- `_autoSubmit()` — `clearTimeout` + `setTimeout(1500)` → `form.requestSubmit()`

### 5. Vistas

**`app/views/church_admin/ministries/search.html.erb`**

Turbo-frame con lista de ministerios encontrados. Cada resultado: botón con `data-action="click->ministry-picker#addMinistry"`, `data-public-id`, `data-name`. Sin opción "Crear" (ministerios son pre-existentes).

**`app/views/church_admin/members/_ministry_tag.html.erb`**

Locals: `name:`, `role: "member"`, `ministry_public_id:`

Contenido por tag:
- Ícono + nombre (display)
- `<input type="hidden" data-tag-id-input name="ministry_memberships[__ID__][public_id]" value="<%= ministry_public_id %>">`
- `<select data-tag-meta data-action="change->ministry-picker#roleChanged" name="ministry_memberships[__ID__][role]">` con opciones member/co_leader/leader
- Botón X: `data-action="click->ministry-picker#removeTag"`

El div raíz lleva `data-catalog-tag` para consistencia visual y `data-ministry-tag` para selección JS.

**`app/views/church_admin/members/show.html.erb`** — sección Ministerios

La sección actual (read-only) se reemplaza con:

```erb
<% if policy(@member).edit? %>
  <turbo-frame id="member-ministries-<%= @member.public_id.first(8) %>" class="block">
    <!-- formulario con ministry-picker -->
    <!-- turbo-frame de resultados -->
    <!-- tagsZone con _ministry_tag por cada membership activa -->
    <!-- template con _ministry_tag vacío -->
  </turbo-frame>
<% else %>
  <!-- lista read-only actual -->
<% end %>
```

### 6. Política

No se requiere policy nueva. `MemberMinistriesController` usa `authorize @member, :update?` — cualquier usuario con permiso de editar miembros puede gestionar sus ministerios desde esta vista.

### 7. i18n (`config/locales/es.yml`)

```yaml
church_admin:
  member_ministries:
    updated: "Ministerios actualizados correctamente."
    invalid_ministry: "Uno o más ministerios no son válidos para esta iglesia."
```

## Consideraciones multi-tenant

- `MinistriesController#search` filtra por `@church` (scoped en BaseController).
- `MemberMinistriesController#assign` busca ministries con `@church.ministries.active.find_by!` — nunca accede a ministerios de otra iglesia.
- `@member` se resuelve con `@church.members.find_by_public_id!` en el `before_action` del BaseController.

## Testing

- Spec de request/controller para `assign`: casos de éxito, rol inválido, ministerio de otra iglesia.
- Spec multi-tenant: dos iglesias, verificar que no se pueden asignar ministerios cross-church.
- Spec de policy: usuario sin permiso de editar miembro recibe 403.
- Spec del search endpoint: resultados filtrados por iglesia y por `exclude[]`.

## Archivos a crear/modificar

| Archivo | Acción |
|---------|--------|
| `config/routes.rb` | Modificar |
| `app/controllers/church_admin/ministries_controller.rb` | Modificar (add `search`) |
| `app/controllers/church_admin/member_ministries_controller.rb` | Crear |
| `app/javascript/controllers/ministry_picker_controller.js` | Crear |
| `app/views/church_admin/ministries/search.html.erb` | Crear |
| `app/views/church_admin/members/_ministry_tag.html.erb` | Crear |
| `app/views/church_admin/members/show.html.erb` | Modificar |
| `config/locales/es.yml` | Modificar |
