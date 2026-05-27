# CLAUDE.md — `app/services/permissions/`

Guía específica para trabajar en la capa de permisos dinámicos. Para contexto general del proyecto, leer [`/CLAUDE.md`](../../../CLAUDE.md) y la sección 14 de [`general planification.md`](../../../general%20planification.md).

## Qué vive aquí

- `PermissionChecker` — única autoridad para responder "¿este usuario puede hacer esta acción sobre este recurso en esta iglesia?".
- `PermissionMatrixBuilder` — arma la matriz que ve el admin al editar un rol.
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
7. **Acciones derivadas.** `read_only` implica `read`. `read_write` añade `create/update`. `full_access` añade `activate/deactivate`. `export` y `manage` son siempre checkboxes independientes — no caen en los atajos.

## Cómo agregar un módulo nuevo

1. Agregar registro a `permissions` en seeds (`db/seeds.rb` o seed dedicado), con `module_key`, `action_key`, `name` y `position`.
2. Si el módulo es sensible (como `pastoral_notes`), marcarlo en `PermissionChecker` para que valide la condición especial.
3. Actualizar la matriz visible en `ChurchAdmin::RolePermissionsController`.
4. Especificar todas las acciones soportadas — no todas las tablas necesitan `activate/deactivate/export`.
5. Agregar specs: cada módulo nuevo debe tener al menos un test de "rol sin permiso no puede" y "rol con permiso sí puede".

## Cómo agregar una acción nueva

1. Agregar el `action_key` a `Permission::ACTION_KEYS`.
2. Agregar los registros necesarios en seeds para cada `module_key` que soporte esa acción.
3. Actualizar `RolePermission` si la acción necesita una validación especial.
3. Actualizar UI de la matriz para mostrar el checkbox.
4. Documentar aquí (en este CLAUDE.md) qué significa esa acción y si entra en `read_only / read_write / full_access` o queda aparte.
5. Specs: la acción nueva debe tener cobertura completa en `permission_checker_spec.rb`.

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
  - Unión de permisos: dos roles, uno read_only y otro full_access → full_access gana.
  - Aislamiento: el mismo usuario en dos iglesias, los permisos no se mezclan.

## Qué evitar

- Cachear permisos efectivos en `users` (cambian por iglesia y por sesión).
- Validar permisos en el modelo (`before_save`) — pertenece a controllers/policies.
- Saltarse el checker en "casos rápidos". No hay casos rápidos.
- Permitir que un permiso de `pastoral_notes` se guarde en un rol con `pastoral: false`. Validar en `RolePermission`.
