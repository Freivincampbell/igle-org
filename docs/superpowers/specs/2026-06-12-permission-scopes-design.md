# Alcances de permisos configurables (`own` / `assigned_ministry` / `church`)

**Fecha:** 2026-06-12
**Estado:** aprobado por el usuario (matriz completa configurable; Planes/Suscripciones fuera de alcance)
**Skills usados:** `superpowers:brainstorming`

## Problema

El CLAUDE.md y la planificación definen que la autorización es `rol × permiso ×
acción × **alcance**`, con alcances `own`, `assigned_ministry`, `church`. Hoy:

- `role_permissions` **no tiene columna `scope`** → el alcance no se puede
  configurar; todo permiso es de facto `church`.
- `PermissionChecker#allow?` **ignora el alcance** (firma sin `scope_hint`/`record`).
- `assigned_ministry` existe solo como **fallback hardcodeado** en
  `MinistryPolicy`/`EventPolicy` (si no hay permiso global, filtra por
  ministerios liderados). `own` no existe.
- La UI de la matriz solo permite marcar permisos, no elegir alcance.

El contrato objetivo ya está documentado en
`app/services/permissions/CLAUDE.md` ("Contrato de PermissionChecker"). Este
spec lo implementa.

## Decisiones

- **Matriz completa configurable** (no el enfoque liviano): columna `scope` real
  + selector en la UI + evaluación centralizada en `PermissionChecker`.
- **Módulos con alcance sub-iglesia configurable:** `members`, `events`,
  `ministries` (los que tienen una relación natural con ministerio/usuario). El
  resto de módulos queda **solo `church`** (el selector no ofrece otros alcances
  para ellos). Esto evita lockouts por configurar un alcance que ningún filtro
  sabe aplicar.
- Planes/Suscripciones: **fuera de alcance**.

## Modelo de datos

### Migración

`add_column :role_permissions, :scope, :string, null: false, default: "church"`

La unicidad sigue siendo `[role_id, permission_id]` (un permiso se concede a un
rol en **exactamente un** alcance). Backfill implícito: filas existentes quedan
`church` por el default → comportamiento idéntico al actual.

### `RolePermission`

```ruby
SCOPES = %w[own assigned_ministry church].freeze
enum :scope, SCOPES.index_with(&:itself), default: "church", validate: true
```

## Servicio de permisos

### `UserContext`

Agregar lo que el contrato exige. Como `Data.define` es inmutable, se computa
de forma perezosa con memoización a nivel de request vía un objeto auxiliar; la
implementación concreta: añadir métodos `membership_roles` y
`assigned_ministry_ids` al `Data` (consultas, no estado mutable), y que el
**checker** memoice por request lo que necesite.

`assigned_ministry_ids`: ids de `Ministry` donde el `Member` del usuario (en la
iglesia actual) tiene `MinistryMembership` activa con rol `leader`/`co_leader`.

### `PermissionChecker` (contrato)

- `allow?(user_context:, module_key:, action:, record: nil)` → `Boolean`.
  - `false` si no hay iglesia / membresía inactiva (regla 1).
  - Owner bootstrap: `true` para módulos no-pastorales (regla 4) — alcance
    efectivo `church`.
  - Calcula el **alcance efectivo** = el más amplio entre los roles que
    conceden `módulo+acción` (orden de amplitud `church > assigned_ministry >
    own`).
  - Si `record` es `nil` → `true` cuando hay algún alcance que concede.
  - Si `record` presente → `true` si el record cae dentro del alcance efectivo
    (ver "evaluación por record").
- `scope_for(user_context:, module_key:, action:)` → `:own | :assigned_ministry
  | :church | nil` (alcance efectivo, sin record). Lo usan las policies y el
  `filter`.
- `filter(user_context:, module_key:, action:, relation:)` →
  `ActiveRecord::Relation` con el alcance aplicado. Centraliza el "qué significa
  cada alcance" por módulo (regla: lógica de permisos solo aquí, no en policies).
- `effective_permissions(user_context:, module_key:)` → hash
  `{ "read" => scope, "create" => scope, "manage" => scope }` (para la UI/uso
  futuro).

### Evaluación por record y filtro por módulo

Tabla centralizada en el checker (`SCOPE_FILTERS` por `module_key`):

| módulo | `assigned_ministry` (relación) | `own` (relación) |
|---|---|---|
| `ministries` | `Ministry.where(id: assigned_ministry_ids)` | (no aplica → `none`) |
| `events` | `Event.where(ministry_id: assigned_ministry_ids)` | (no aplica → `none`) |
| `members` | members con `MinistryMembership` en `assigned_ministry_ids` | `members.where(user_id: user.id)` |

- `church`: `relation.where(church: current_church)` (sin restricción extra).
- record check: el record pertenece al alcance si está incluido en la relación
  filtrada (`filter(...).exists?(record.id)`), o equivalentemente comparando
  ids — implementación a criterio, pero **una sola fuente de verdad** (el mismo
  mapa).
- Módulo sin entrada en el mapa + alcance no-`church` → `none` (deny seguro).

## Policies

`ApplicationPolicy` gana helpers que delegan en el checker:

- `scoped_permission?(module_key, action, record = nil)` → usa `allow?` con
  record.
- El `Scope#resolve` de cada policy con alcance usa
  `PermissionChecker.filter(...)` en vez de la lógica hardcodeada.

El alcance configurable es **aditivo y sin regresión**: el fallback de líder
existente (`ministry_leader_of?` / `user_led_ministries`) se **mantiene** en
`MinistryPolicy`/`EventPolicy`, así que ningún líder pierde acceso. Lo que se
agrega es que ahora un rol puede conceder un permiso con alcance configurado, y
las policies lo respetan **además** del fallback:

- `MemberPolicy` (el valor nuevo principal): un rol con `members:read` scope
  `assigned_ministry` ve solo los miembros de sus ministerios; scope `own` ve
  solo su propio registro; scope `church` ve todos (como hoy). Antes no había
  forma de acotar `members`.
- `EventPolicy`/`MinistryPolicy`: el `Scope#resolve` se reescribe sobre
  `PermissionChecker.filter(...)`, que devuelve la unión de (lo que concede el
  permiso configurado) ∪ (ministerios liderados, por el fallback). Resultado:
  comportamiento actual preservado, más la capacidad de configurar `church`
  explícito vs `assigned_ministry`.

Regla: la lógica de "qué significa cada alcance" vive en `PermissionChecker`
(`filter`/`scope_for`), no duplicada en las policies.

## UI de la matriz

`ChurchAdmin::RolesController#update_permissions` +
`Permissions::RoleMatrixAssignment` pasan a recibir, por permiso seleccionado,
su **alcance**. La vista de la matriz muestra, para los módulos configurables,
un selector de alcance (radio/dropdown: Propio / Ministerio asignado / Iglesia)
junto al permiso; para los demás módulos, solo el check (alcance `church`
fijo). `PermissionMatrixBuilder` expone qué alcances son válidos por módulo.

## Auditoría

`RolePermission` ya tiene `paper_trail`; el cambio de alcance queda versionado.
Cambios en la matriz son auditables (regla 7 del CLAUDE.md raíz).

## Testing (reglas de spec/CLAUDE.md)

- `permission_checker_spec`: por cada alcance (`own`/`assigned_ministry`/
  `church`) y acción — sin permiso, con permiso y record dentro/fuera del
  alcance; owner bootstrap = church; pastoral_notes sin tocar.
- Policy specs (member/event/ministry): los tres alcances con
  `Scope#resolve` devolviendo el conjunto correcto, y `show?/update?` por record
  dentro/fuera.
- `RoleMatrixAssignment` spec: guarda scope por permiso; cambiar scope; scope
  inválido para módulo no configurable → rechazado o forzado a church.
- Aislamiento: dos iglesias en los specs de scope.
- Request spec de la matriz: el admin setea un permiso con scope
  `assigned_ministry` y persiste.

## Fuera de alcance

- `own` para módulos sin relación natural con el usuario (queda `none`).
- Caché de permisos efectivos (`PermissionEffectiveCache`) — futuro.
- Denegaciones explícitas (hoy solo unión positiva).
