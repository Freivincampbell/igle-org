# Diseño: Búsqueda de Miembros con Autocomplete

**Fecha:** 2026-05-29  
**Branch objetivo:** `feature/member-search-ui`  
**Scope:** Reemplazar todos los checkboxes y selects de asignación de miembros con un patrón de búsqueda tipo search-as-you-type consistente en todo el panel de administración.

---

## Problema actual

Los formularios de familias, ministerios, junta directiva y asistencia a eventos usan checkboxes o `<select>` con la lista completa de miembros de la iglesia. Con 50+ miembros la experiencia es torpe: hay que hacer scroll por una lista larga para encontrar a alguien.

---

## Patrón central: Tags + Turbo Frame search

Selecciones múltiples (familias, ministerios): campo de búsqueda que consulta al servidor, resultados en dropdown, selección que genera una "etiqueta" (tag) removible con selector de rol/relación integrado en la misma etiqueta.

Selección única (junta directiva, miembro responsable de evento): misma mecánica pero limitada a una sola selección por slot.

Asistencia a eventos: lista completa de miembros con filtro client-side (sin round-trip al servidor), agrupada por RSVP.

---

## Arquitectura

### Endpoint de búsqueda (nuevo)

```
GET /churches/:church_public_id/admin/members/search
Parámetros: q (string), exclude[] (array de public_ids ya seleccionados)
Responde: Turbo Frame con lista de resultados
Autorización: requiere permiso read sobre members
```

Acción nueva en `ChurchAdmin::MembersController`:

```ruby
def search
  authorize Member, :index?, policy_class: MemberPolicy
  @members = @church.members.active
    .where.not(public_id: Array(params[:exclude]))
    .search_by_name(params[:q].to_s.strip)
    .order(:last_name, :first_name)
    .limit(10)
  render layout: false
end
```

La vista devuelve `<turbo-frame id="member-search-results">` con hasta 10 resultados. Sin `q` devuelve frame vacío. Con `q` de 1 carácter devuelve frame vacío también (mínimo 2 chars).

### Stimulus controller: `member-search`

Archivo: `app/javascript/controllers/member_search_controller.js`

**Responsabilidades:**
- Debounce de 300ms en el input → actualiza `src` del Turbo Frame con `?q=...&exclude[]=...`
- Al hacer clic en un resultado: agrega tag al DOM, agrega hidden input, registra public_id en lista de excluidos, limpia el input
- Al hacer clic en × de un tag: remueve el tag, remueve el hidden input, saca el public_id de excluidos
- Cierra el dropdown al hacer clic fuera (click outside)
- Oculta el campo de búsqueda cuando se alcanza el máximo de selecciones (solo para selección única)

**Values del controller:**
- `fieldName` (string): prefijo del nombre de campo, e.g. `family[member_public_ids]`
- `metaFieldName` (string): campo de metadata por miembro, e.g. `family[member_relationships]` (vacío si no aplica)
- `metaOptions` (JSON array): opciones del selector de metadata, e.g. `[["Esposo/a","spouse"],["Hijo/a","child"]]`
- `maxSelections` (number, default 0 = ilimitado): para slots de junta directiva = 1

**Targets:**
- `input`: campo de texto de búsqueda
- `results`: el `<turbo-frame>` de resultados
- `tagsZone`: contenedor donde se renderizan los tags
- `searchArea`: el bloque entero de búsqueda (para ocultarlo cuando max=1 y ya hay selección)

### Stimulus controller: `attendance-filter`

Archivo: `app/javascript/controllers/attendance_filter_controller.js`

Filtro client-side puro. Lee el valor del input y muestra/oculta filas (`[data-member-name]`) que incluyan el texto. Sin debounce (respuesta instantánea). Actualiza un contador `"X ✓ / Y total"` al marcar/desmarcar checkboxes.

---

## Partials compartidos

### `app/views/shared/_member_tag.html.erb`

Recibe locals:
- `member_public_id` (string)
- `member_name` (string)
- `member_initials` (string, 2 chars)
- `field_name_ids` (string): e.g. `family[member_public_ids][]`
- `meta_field_name` (string, opcional): e.g. `family[member_relationships][PUBLIC_ID]`
- `meta_options` (array of [label, value], opcional)
- `meta_selected` (string, opcional): valor seleccionado actual
- `primary_contact` (boolean, opcional, solo familias)

Genera: pill con avatar de iniciales + nombre + select de rol/relación (si aplica) + radio de contacto principal (si aplica) + botón ×.

### `app/views/church_admin/members/search.html.erb`

Solo el contenido del Turbo Frame. Cada resultado es un `<button>` con `data-action="click->member-search#addMember"` y data attributes: `public_id`, `name`, `initials`.

---

## Vistas a modificar

### 1. Familias — `church_admin/families/show.html.erb`

Reemplaza el bloque actual de checkboxes (líneas ~32–56) con:

```
[zona de tags: miembros ya en la familia, cada uno con select de relación y radio de contacto principal]
[input de búsqueda → turbo-frame de resultados]
[hidden input para primary_contact_public_id]
```

El formulario sigue enviando `PATCH members` con los mismos parámetros que hoy (`family[member_public_ids][]`, `family[member_relationships][PUBLIC_ID]`, `family[primary_contact_public_id]`). Solo cambia la UI.

### 2. Ministerios — `church_admin/ministries/show.html.erb`

Reemplaza el bloque de checkboxes (líneas ~88–116) con:

```
[zona de tags: miembros ya en el ministerio, cada uno con select de rol]
[input de búsqueda → turbo-frame de resultados]
```

Parámetros sin cambio: `ministry[member_public_ids][]`, `ministry[member_roles][PUBLIC_ID]`.

### 3. Junta Directiva — `church_admin/boards/show.html.erb`

Reemplaza los selects (líneas ~32–49) con tabla de 8 filas:

Cada fila = `[label de cargo] + [tag del miembro asignado con × | botón "Asignar miembro..." si vacío]`

Al hacer clic en "Asignar...": muestra un input de búsqueda inline en esa fila con `max-selections=1`. Al seleccionar un miembro: el input se oculta, aparece el tag. Al hacer clic en ×: el tag desaparece, vuelve el botón.

Cada cargo usa el mismo Stimulus controller `member-search` con instancia separada por cargo (usando el scope de Stimulus). El `fieldName` es `board[positions][CARGO]`.

### 4. Formulario de Evento — `church_admin/events/_form.html.erb`

Reemplaza el `select` de `responsible_member_public_id` (líneas ~42–48) con el mismo patrón de búsqueda, `max-selections=1`. El `select` de `ministry_id` se mantiene como está (es una lista corta de ministerios, no requiere búsqueda).

### 5. Asistencia — `church_admin/events/attendance.html.erb`

Reemplaza la tabla actual (líneas ~8–37) con:

```
[barra superior: input de búsqueda + badge "X ✓ / Y"]
[sección "Confirmaron asistencia": miembros con RSVP attending, pre-marcados]
[sección "Otros miembros": resto de miembros activos en orden alfabético]
```

El filtro client-side (Stimulus `attendance-filter`) muestra/oculta filas basándose en el texto escrito. Los headers de sección se ocultan si todas sus filas quedan filtradas. Los miembros con RSVP `attending` vienen pre-checked desde el servidor. Los parámetros de envío no cambian (`attendance[member_ids][]`).

---

## Rutas nuevas

```ruby
# Dentro de resources :members (que ya existe en church_admin)
collection do
  get :search
end
```

URL resultado: `GET /churches/:church_public_id/admin/members/search`

---

## UX aplicada

- **Mínimo 2 caracteres** antes de lanzar búsqueda (evita resultados ruidosos al primer keystroke)
- **Debounce 300ms** en el input del buscador (evita peticiones en cada tecla)
- **Loading state**: el Turbo Frame muestra un spinner mientras carga
- **Resultados vacíos**: texto "Sin resultados para «…»" en el dropdown
- **Excluir seleccionados**: el endpoint recibe `exclude[]` con los public_ids ya elegidos para que no aparezcan en resultados
- **Cerrar al hacer clic fuera**: el dropdown se cierra con `click outside`
- **Teclado**: Enter selecciona el primer resultado del dropdown; Escape cierra el dropdown y limpia el input
- **Avatares**: iniciales del miembro (primera letra de nombre + primera de apellido) con color generado de forma determinista desde el public_id (para consistencia entre cargas)
- **Tags responsivos**: en pantallas pequeñas los tags hacen wrap dentro de la zona
- **Asistencia**: el badge "X ✓ / Y" se actualiza en tiempo real al marcar/desmarcar sin guardar

---

## Lo que NO cambia

- Los parámetros enviados al servidor por todos los formularios son idénticos a los actuales — los service objects (`Families::MemberAssignment`, `Ministries::MemberAssignment`, `Boards::PositionAssignment`) y el `update_attendance` no requieren cambios.
- La autorización (Pundit) no cambia. El nuevo endpoint `search` reutiliza `MemberPolicy#index?`.
- Las rutas de envío de formularios no cambian.
- `pg_search` está en el Gemfile pero aún no está configurado en ningún modelo. Hay que agregar `include PgSearch::Model` y `pg_search_scope :search_by_name, against: %i[first_name middle_name last_name second_last_name], using: { tsearch: { prefix: true } }` al modelo `Member` como parte de esta implementación.

---

## Archivos nuevos y modificados en modelos

| Archivo | Cambio |
|---|---|
| `app/models/member.rb` | Agregar `include PgSearch::Model` + `pg_search_scope :search_by_name` |

## Archivos nuevos (JS y vistas)

| Archivo | Tipo |
|---|---|
| `app/javascript/controllers/member_search_controller.js` | Stimulus controller |
| `app/javascript/controllers/attendance_filter_controller.js` | Stimulus controller |
| `app/views/shared/_member_tag.html.erb` | Partial compartido |
| `app/views/church_admin/members/search.html.erb` | Vista Turbo Frame |

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `app/controllers/church_admin/members_controller.rb` | Agregar acción `search` |
| `config/routes.rb` | Agregar `get :search` en collection de members |
| `app/views/church_admin/families/show.html.erb` | Reemplazar checkboxes con tag search |
| `app/views/church_admin/ministries/show.html.erb` | Reemplazar checkboxes con tag search |
| `app/views/church_admin/boards/show.html.erb` | Reemplazar selects con inline search por cargo |
| `app/views/church_admin/events/_form.html.erb` | Reemplazar select de responsable con search |
| `app/views/church_admin/events/attendance.html.erb` | Lista filtrable con secciones RSVP |
