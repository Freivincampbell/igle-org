# Etapa 15 — Auditoría de Calidad y Seguridad

Fecha: 2026-05-29. Rama: `etapa-15-calidad-seguridad`. Base: `develop`.

## Alcance

Auditoría de seguridad del código actual (etapas 1–13 mergeadas). El módulo de
reportes (Etapa 14) se audita en su propio PR #20. Todo se ejecutó dentro del
contenedor Docker (`docker compose exec web ...`).

## Herramientas automáticas

| Herramienta | Resultado |
|---|---|
| Brakeman 8.0.4 | 0 security warnings |
| bundler-audit (ruby-advisory-db) | 0 vulnerabilidades en dependencias |
| RuboCop (omakase) | sin offenses en archivos tocados |
| RSpec (suite completa) | 238 examples, 0 failures |

## Auditoría manual (3 dimensiones, en paralelo)

### 1. Aislamiento multi-tenant — SÓLIDO
- Todos los `find_by_public_id!` parten de `@church.<asociación>` o del recurso padre scopeado.
- Servicios de asignación (ministries/families/boards/permissions) validan que los IDs referenciados pertenezcan a la iglesia.
- Modelos de unión validan cross-church (`member_belongs_to_ministry_church`, `*_in_same_church`).
- Policies `Scope` filtran por `current_church`. Rutas usan `public_id`.
- **No se encontraron fugas cross-tenant ni IDOR.**

### 2. Autorización (Pundit / PermissionChecker) — SÓLIDO con un gap de defensa en profundidad
- Las policies delegan correctamente en `Permissions::PermissionChecker`; no hay lógica por nombre de rol.
- Notas pastorales correctamente restringidas (rol pastoral + permiso; owner excluido).
- Strong params no exponen campos de escalada (owner, platform_role, church_id).
- **Gap corregido:** no existía `after_action :verify_authorized` / `verify_policy_scoped`. Una acción nueva que olvidara autorizar pasaría silenciosamente. Los controladores `Platform::` dependían solo del guard `super_admin?` del base controller, sin `authorize` Pundit.

### 3. Datos sensibles y exposición — SIN EXPOSICIÓN REAL
- **No existen vistas públicas todavía** (`app/controllers/public/`, `app/views/public/` vacíos); los hallazgos iniciales de "PII en vistas públicas" fueron falsos positivos: todas son vistas de admin autorizadas por permiso.
- El directorio de servicios respeta `church.member_work_contact_enabled` (campo existente en el esquema). Falso positivo descartado.
- No hay secretos hardcodeados, ni PII en logs. CSRF activo (Rails 8 por defecto).
- **Nota de convención (no seguridad):** dos selects usan `m.id` en vez de `public_id` (`pastor/pastoral_notes_controller.rb:58`, `church_admin/events_controller.rb:104`). El backend revalida el scope de iglesia, así que no hay exploit; se difiere a una tarea de limpieza para no arriesgar el flujo de creación.

## Cambios aplicados

1. **`ApplicationController`**: `after_action :verify_authorized` (toda acción salvo index) y `verify_policy_scoped` (index). Se usan condiciones lambda en vez de `only:`/`except:` porque Rails 8 valida la existencia de la acción en cada subcontrolador (los controladores Devise sin `index` rompían con `only: :index`).
2. **`Platform::ChurchesController`**: `authorize` en cada acción + `policy_scope(Church)` en index (defensa en profundidad sobre el guard `super_admin?`).
3. **`Platform::ChurchMembershipsController`**: `authorize ChurchMembership` en new/create.
4. **`HomeController`** y **`ChurchAdmin::ServiceDirectoryController`**: exención explícita de `verify_policy_scoped` (landing pública / scope manual por `@church`).
5. **Test de regresión** (`spec/requests/security_authorization_guard_spec.rb`): bloquea que los callbacks de Pundit sigan registrados y que un index respete el aislamiento por iglesia.

## Veredicto

El código está en excelente estado de seguridad: aislamiento multi-tenant
correcto, autorización dinámica sólida, sin vulnerabilidades automáticas. El
cambio principal de esta etapa es endurecer la autorización con verificación
obligatoria de Pundit, cerrando el riesgo de que futuras acciones omitan la
autorización sin ser detectadas.

## Pendiente (tech-debt, no bloqueante)
- Migrar los dos selects de `id` a `public_id` (ocupa cambios en el flujo de
  creación de eventos y notas; bajo riesgo de seguridad, alta probabilidad de
  romper si se hace sin cuidado).
