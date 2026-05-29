# Diseño: Etapa 9 — Alcance `assigned_ministry` para líderes de ministerio

## Contexto

La Etapa 9 de `igle-org` tenía pendiente implementar el alcance avanzado `assigned_ministry`: que los líderes y co-líderes de un ministerio puedan administrar ese ministerio y ver sus eventos, sin tener permisos a nivel de toda la iglesia.

El alcance se deriva **implícitamente** del `ministry_role` del usuario en `MinistryMembership` (`leader` o `co_leader`), sin agregar columnas a `role_permissions`.

## Arquitectura

### Helper en `ApplicationPolicy`

Se agregan dos métodos privados a `ApplicationPolicy`:

- `ministry_leader_of?(ministry)` — resuelve el `Member` del usuario actual en la iglesia actual via `Member.find_by(user: user_context.user, church: current_church)`, luego verifica si existe un `MinistryMembership` activo con `ministry_role` de `leader` o `co_leader` para ese ministerio.
- `user_led_ministries` — devuelve el scope de `Ministry` donde el usuario es líder/co-líder activo. Usado en los Scopes de policy para filtrar listas.

### `MinistryPolicy`

**Acciones individuales** (`show?`, `update?`, `activate?`, `deactivate?`):

```
super_admin? || (same_church? && (permission?("ministries", acción) || ministry_leader_of?(record)))
```

**`MinistryPolicy::Scope`**:
- Si tiene permiso `ministries/read` a nivel de iglesia → todos los ministerios activos de la iglesia
- Si no tiene permiso pero es líder/co-líder de alguno → solo esos ministerios
- Si ninguna condición → `scope.none`

### `EventPolicy`

**Acciones individuales** (`show?`, `update?`, acciones de gestión):

```
super_admin? || (same_church? && (permission?("events", acción) || (record.ministry.present? && ministry_leader_of?(record.ministry))))
```

**`EventPolicy::Scope`**:
- Si tiene permiso `events/read` a nivel de iglesia → todos los eventos de la iglesia
- Si no tiene permiso pero es líder/co-líder → solo eventos cuyo `ministry_id` esté en sus ministerios liderados
- Eventos sin `ministry_id` (`nil`) no son visibles para líderes con solo alcance `assigned_ministry`

## Reglas de negocio

- Solo `leader` y `co_leader` activos en `MinistryMembership` obtienen el alcance implícito. El rol `member` no.
- Un usuario sin `Member` vinculado en esa iglesia no obtiene alcance de liderazgo.
- El alcance de liderazgo **no reemplaza** los permisos de rol — son aditivos. Si el usuario tiene ambos, tiene acceso más amplio.
- Eventos sin ministerio asignado solo los ven usuarios con permiso `church`-wide en `events`.

## Tests requeridos

- `MinistryPolicy`: líder de ministerio puede ver/editar su ministerio pero no otro de la misma iglesia.
- `MinistryPolicy::Scope`: líder solo ve sus ministerios; usuario con permiso `church`-wide ve todos.
- `EventPolicy::Scope`: líder ve solo eventos de sus ministerios; no ve eventos sin ministerio ni de otros ministerios.
- `ApplicationPolicy`: `ministry_leader_of?` retorna `true` solo para `leader`/`co_leader` activos.

## Lo que NO cambia

- Esquema de base de datos: sin migraciones.
- `PermissionChecker`: no cambia su firma ni lógica.
- Vistas: el filtrado ocurre en el Scope de policy; las vistas existentes funcionan sin cambios.
- Namespace de controladores: todo sigue en `ChurchAdmin::`.
