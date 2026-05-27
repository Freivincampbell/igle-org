---
description: Crea una policy Pundit que delega en Permissions::PermissionChecker
argument-hint: <NombreModelo>
---

Crea una policy Pundit para el modelo indicado en `$ARGUMENTS`, siguiendo las reglas de autorización de `igle-org`.

Reglas fundamentales:

- La policy **nunca** decide permisos por nombre de rol. Delega siempre en `Permissions::PermissionChecker`.
- La policy **siempre** valida que el `record` pertenece a la iglesia actual antes de cualquier otra cosa.
- Los métodos `index?`, `show?`, `create?`, `update?`, `destroy?`, `activate?`, `deactivate?`, `export?` corresponden a acciones declaradas en `PermissionModule`.
- El `Scope` filtra por `church_id` de la iglesia actual antes de aplicar cualquier permiso.
- Si el módulo tiene alcance `assigned_ministry`, el `Scope` y los métodos respetan ese alcance.

Estructura a generar (`app/policies/<modelo>_policy.rb`):

```ruby
class <Modelo>Policy < ApplicationPolicy
  PERMISSION_MODULE = "<key_del_modulo>" # ej: "members", "events"

  def index?
    can?(:list)
  end

  def show?
    in_current_church? && can?(:show, scope_for_record)
  end

  def create?
    can?(:create)
  end

  def update?
    in_current_church? && can?(:update, scope_for_record)
  end

  def activate?
    in_current_church? && can?(:activate, scope_for_record)
  end

  def deactivate?
    in_current_church? && can?(:deactivate, scope_for_record)
  end

  def export?
    can?(:export)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      base = scope.where(church_id: user_context.current_church.id)
      Permissions::PermissionChecker.filter(
        user_context: user_context,
        module_key: PERMISSION_MODULE,
        relation: base
      )
    end
  end

  private

  def can?(action, scope_hint = :church)
    Permissions::PermissionChecker.allow?(
      user_context: user_context,
      module_key: PERMISSION_MODULE,
      action: action,
      scope_hint: scope_hint,
      record: record
    )
  end

  def in_current_church?
    record.church_id == user_context.current_church.id
  end

  def scope_for_record
    # Devuelve :own, :assigned_ministry o :church según el record y user
    Permissions::PermissionChecker.scope_for(user_context: user_context, record: record)
  end
end
```

Specs a generar (`spec/policies/<modelo>_policy_spec.rb`):

- Sin permiso: todas las acciones devuelven `false`.
- Permiso `read_only`: `index?`, `show?` true; resto false.
- Permiso `read_write`: añade `create?`, `update?` true; `activate?`/`deactivate?` false.
- Permiso `full_access`: todo true salvo acciones especiales (`export`, `manage`).
- Alcance `own`: solo el record propio del usuario.
- Alcance `assigned_ministry`: solo records de ministerios asignados al usuario.
- Alcance `church`: todos los records de la iglesia actual.
- **Aislamiento**: con dos iglesias, el usuario de A no puede operar sobre records de B aunque tenga permisos full en A.
- Notas pastorales: si el modelo es `PastoralNote`, agregar test específico de que admin sin rol pastoral no accede.

Antes de crear, valida:

- ¿Existe `Permissions::PermissionChecker`? Si no, avisa que primero hay que implementarlo (Etapa 5 del plan).
- ¿Existe la entrada del módulo en `permission_modules` (seeds)? Si no, recuerda agregarla.
- ¿La policy hereda de `ApplicationPolicy`? Si `ApplicationPolicy` aún no existe, créalo también.

Reporta al final: archivos creados, qué módulo de permisos hay que tener en seeds, y el comando para correr las specs.
