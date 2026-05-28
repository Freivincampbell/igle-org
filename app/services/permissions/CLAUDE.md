# CLAUDE.md — `app/services/permissions/`

Guía específica para trabajar en la capa de permisos dinámicos. Para contexto general del proyecto, leer [`/CLAUDE.md`](../../../CLAUDE.md) y la sección 14 de [`general planification.md`](../../../general%20planification.md).

## Qué vive aquí

- `PermissionChecker` — única autoridad para responder "¿este usuario puede hacer esta acción sobre este recurso en esta iglesia?".
- `PermissionMatrixBuilder` — arma la matriz que ve el admin al editar un rol.
- `RoleMatrixAssignment` — actualiza la matriz `role_permissions` usando `public_id` de permisos.
- `MembershipRoleAssignment` — asigna roles a una membresía de iglesia usando `public_id` de roles.
- (futuro) `PermissionEffectiveCache` — caché por sesión de permisos efectivos del usuario.

Cualquier policy, controlador o servicio que necesite autorización **debe** pasar por este módulo. No replicar lógica de permisos fuera de aquí.

## Contrato de `PermissionChecker`

Métodos públicos esperados:

- `allow?(user_context:, module_key:, action:, scope_hint: :church, record: nil)` → `Boolean`.
- `scope_for(user_context:, record:)` → `:own | :assigned_ministry | :church | nil`.
- `filter(user_context:, module_key:, relation:)` → `ActiveRecord::Relation` (aplica alcance).
- `effective_permissions(user_context:, module_key:)` → estructura con acciones permitidas + alcance.

`user_context` es un objeto que conoce: `user`, `current_church`, `church_membership`, `membership_roles`, `assigned_ministry_ids`.

## Reglas no negociables

1. **Iglesia actual obligatoria.** Si `user_context.current_church` no está, la respuesta es `false`. No fallback a "alguna iglesia del usuario".
2. **Unión de permisos.** Si el usuario tiene varios roles activos en la iglesia, se devuelve la unión más amplia. No hay denegaciones explícitas (por ahora).
3. **Rol pastoral.** Para que `allow?(module_key: "pastoral_notes", ...)` devuelva `true`, **todos** estos deben cumplirse:
   - El usuario tiene al menos un `MembershipRole` activo a un `Role` con `pastoral: true`.
   - Ese rol tiene un `RolePermission` activo sobre el módulo `pastoral_notes` con la acción solicitada.
4. **Owner bootstrap.** Si `church_membership.owner == true`, las acciones admin estándar (todas excepto `pastoral_notes.*`) devuelven `true` aunque no haya roles configurados. Esto es excepción explícita, documentar siempre.
5. **Super admin.** `user.platform_role == "super_admin"` solo aplica a módulos de plataforma. **No** otorga acceso a notas pastorales ni a datos operativos cotidianos sin ir por la iglesia.
6. **Alcance.** Si el permiso tiene scope `assigned_ministry`, validar que `record` pertenece a un ministerio en `assigned_ministry_ids`. Si scope es `own`, validar `record.user_id == user.id` o `record.member.user_id == user.id` según corresponda.
7. **Acciones derivadas.** La matriz visible usa solo `read`, `create` y `manage`. `read` permite solo ver. `create` permite leer, crear y editar. `manage` permite leer, crear, editar, activar, desactivar y cualquier acción administrativa del módulo.

## Cómo agregar un módulo nuevo

1. Agregar el módulo a `Permission::ASSIGNABLE_MODULE_KEYS` solo cuando exista una pantalla real para administrarlo por iglesia.
2. Agregar registro a `permissions` en seeds (`db/seeds.rb` o seed dedicado), con `module_key`, `action_key`, `name` y `position`.
3. Si el módulo es sensible (como `pastoral_notes`), marcarlo en `PermissionChecker` para que valide la condición especial.
4. Actualizar la matriz visible en `ChurchAdmin::RolesController`.
5. Usar las tres acciones estándar: `read`, `create`, `manage`.
6. Agregar specs: cada módulo nuevo debe tener al menos un test de "rol sin permiso no puede" y "rol con permiso sí puede".

## Cómo agregar una acción nueva

1. Agregar el `action_key` a `Permission::ACTION_KEYS`.
2. Agregar los registros necesarios en seeds para cada `module_key` que soporte esa acción.
3. Actualizar `RolePermission` si la acción necesita una validación especial.
4. Evitar acciones nuevas salvo que `read/create/manage` no puedan expresar el caso real.
5. Actualizar UI de la matriz para mostrar el checkbox.
6. Documentar aquí qué significa esa acción y si implica otras acciones.
7. Specs: la acción nueva debe tener cobertura completa en `permission_checker_spec.rb`.

## Performance

- Cargar `MembershipRole` + `RolePermission` del usuario una sola vez por request (cachear en `user_context`).
- No hacer N+1 contra `role_permissions` desde una policy llamada en un `each`.
- `PermissionChecker.filter` debe traducirse a SQL (`where`) cuando el alcance es `church` o `assigned_ministry`; no traer todo a memoria.

## Tests requeridos

- `spec/services/permissions/permission_checker_spec.rb` debe cubrir:
  - Sin role assignments → todo false.
  - Owner bootstrap → admin true, pastoral_notes false.
  - Super admin → módulos de plataforma true, módulos operativos require role assignment.
  - Rol con `pastoral: false` + permiso pastoral_notes → false (validación a nivel modelo + checker).
  - Rol con `pastoral: true` + permiso pastoral_notes → true.
  - Alcance `own` → solo records propios.
  - Alcance `assigned_ministry` → solo records de ministerios asignados.
  - Unión de permisos: dos roles, uno `read` y otro `manage` → `manage` gana.
  - Aislamiento: el mismo usuario en dos iglesias, los permisos no se mezclan.

## Qué evitar

- Cachear permisos efectivos en `users` (cambian por iglesia y por sesión).
- Validar permisos en el modelo (`before_save`) — pertenece a controllers/policies.
- Saltarse el checker en "casos rápidos". No hay casos rápidos.
- Permitir que un permiso de `pastoral_notes` se guarde en un rol con `pastoral: false`. Validar en `RolePermission`.
