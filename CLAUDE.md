# CLAUDE.md

Guía operativa para Claude. Este archivo describe cómo trabajar en `igle-org` sin romper las reglas de arquitectura. Para el contexto completo del dominio, leer [`general planification.md`](./general%20planification.md).

## Resumen del proyecto

Aplicación web Rails 8 multi-tenant para administrar iglesias. Cada iglesia es un tenant aislado dentro de la misma plataforma. Existe un super administrador global y, dentro de cada iglesia, un administrador inicial que configura roles, permisos, miembros, ministerios, junta directiva y eventos.

Nombre comercial provisional: `igle-org`. Idioma principal: español.

## Stack

- Ruby 3.4.9, Rails 8.1.3.
- PostgreSQL (>= 15).
- Tailwind CSS, Hotwire (Turbo + Stimulus), importmap-rails.
- Devise (autenticación), Pundit (autorización base) y servicio propio de permisos dinámicos.
- Solid Queue, Solid Cache, Solid Cable.
- Active Storage con `image_processing`.
- `simple_form`, `pagy`, `pg_search`, `paper_trail`, `caxlsx`, `dotenv-rails`.
- Testing: RSpec, FactoryBot, Faker, Capybara, Selenium.
- Calidad y seguridad: RuboCop (omakase), Brakeman, Bundler-Audit.
- Docker para desarrollo. Kamal preparado para futuro despliegue en DigitalOcean.

## Reglas críticas (no negociables)

1. **Aislamiento multi-tenant.** Toda tabla operativa debe tener `church_id`. Toda consulta debe filtrar por `church_id`. Nunca se permite leer ni escribir datos cruzados entre iglesias.
2. **Sin borrado físico.** Los registros se desactivan (`active`, `status`) en lugar de hacer `destroy`. La única excepción son tablas de unión que se rehacen.
3. **Identificadores públicos.** Toda tabla de dominio debe tener `public_id: uuid` único. URLs, APIs, formularios, logs visibles y referencias externas usan `public_id`, nunca el `id` interno.
4. **Permisos dinámicos, no por nombre de rol.** El nombre del rol nunca otorga permisos. Toda autorización pasa por el servicio `Permissions::PermissionChecker`, validando módulo + acción + alcance + iglesia actual.
5. **Notas pastorales.** Solo accesibles a usuarios con un rol marcado `pastoral: true` y con permiso explícito sobre el módulo `pastoral_notes`. Un administrador sin rol pastoral no puede verlas, aunque sea owner.
6. **Owner bootstrap.** El primer administrador de una iglesia tiene acceso administrativo inicial via `church_memberships.owner = true`. Este acceso no incluye notas pastorales.
7. **Auditoría.** Cambios importantes se registran con `paper_trail` (creación de iglesias, asignación de roles, cambios en matriz de permisos, cambios en miembros, aprobación/rechazo de cambios de perfil, cambios en junta, notas pastorales, exportaciones sensibles).
8. **Idioma.** UI, validaciones y mensajes en español. Locales en `config/locales/es.yml`.
9. **Frontend.** Tailwind CSS y Hotwire. No introducir SPAs ni librerías JS pesadas sin discutirlo.

## Arquitectura de tenancy

- `users` es **global**. Una persona puede pertenecer a varias iglesias.
- `church_memberships` es la tabla pivote (incluye `status`, `owner`, `joined_at`; invitaciones quedan para etapa posterior).
- `members` pertenece a una iglesia y opcionalmente está conectado a un `user` global.
- `roles`, `role_permissions`, `membership_roles`, `ministries`, `boards`, `events`, etc. son **por iglesia** (`church_id`).
- `permissions` y `plans` son globales de plataforma.
- Los super administradores se identifican por `users.platform_role = "super_admin"`.
- Las rutas de cualquier recurso de dominio usan `public_id` tipo UUID, no el `id` interno.

Antes de cada query a una tabla operativa, validar que el scope incluye `church_id` de la iglesia actual. Resolver iglesia actual mediante `Tenants::CurrentChurchResolver` (a implementar en Etapa 3).

## Estructura del código

Controladores agrupados por área:

- `Platform::` — super administrador.
- `ChurchAdmin::` — administración interna de iglesia.
- `Pastor::` — vistas pastorales (notas, seguimiento).
- `MinistryLeader::` — administración acotada a ministerios asignados.
- `MemberPortal::` — portal de miembro (perfil, eventos, directorio).
- `Public::` — página pública de iglesia.

Lógica compleja vive en `app/services/` (no en modelos ni controladores). Ver estructura sugerida en la sección 10 de `general planification.md`.

Políticas Pundit en `app/policies/` siempre delegan en `Permissions::PermissionChecker`. No replicar lógica de permisos en las policies.

## Permisos

Cada iglesia define sus propios roles. La matriz de permisos relaciona `role × permission/module_key × acciones × alcance`.

- Acciones base: `read`, `create`, `update`, `activate`, `deactivate`, `export`, `manage`.
- `read` cubre listado y detalle hasta que exista una necesidad real de separar `list` y `show`.
- Atajos: `no_access`, `read_only` (read), `read_write` (read_only + create/update), `full_access` (read_write + activate/deactivate).
- Alcances: `own`, `assigned_ministry`, `church`.
- `pastoral_notes` solo puede activarse en roles con `pastoral: true`.
- Un usuario con varios roles recibe la **unión** de permisos.
- El backend siempre revalida (no confiar en que la vista oculte botones).

## Modelos clave (resumen)

`User`, `Church`, `ChurchMembership`, `Role`, `Permission`, `RolePermission`, `MembershipRole`, `Member`, `Family`, `FamilyMember`, `Address`, `Ministry`, `MinistryMembership`, `Board`, `BoardMember`, `ChurchServiceTime`, `Event`, `EventRsvp`, `EventAttendance`, `Occupation`, `MemberOccupation`, `Skill`, `MemberSkill`, `ProfileChangeRequest`, `PastoralNote`, `ContactMethod`, `Plan`, `Subscription`.

Detalle completo de campos, enums y relaciones en `general planification.md` sección 12.

## Convenciones

- Modelos: nombres en singular, snake_case en archivos. Toda tabla operativa con `church_id` indexado y toda tabla de dominio con `public_id` UUID único.
- Validaciones en español usando i18n.
- Formularios con `simple_form`.
- Paginación con `pagy`.
- Búsquedas con `pg_search`.
- Exportaciones CSV con la librería estándar y XLSX con `caxlsx`.
- Eventos recurrentes: empezar simple (daily/weekly/monthly + `recurrence_until`). Evaluar `ice_cube` solo si se necesita recurrencia compleja.
- Catálogos por iglesia (`occupations`, `skills`) hasta que se justifique un catálogo global.

## Tests

- RSpec en `spec/`. Factories en `spec/factories/`. Helpers en `spec/support/`.
- Toda feature multi-tenant debe tener al menos un test que cree **dos iglesias** y verifique aislamiento.
- Cada policy debe tener specs para: sin permiso, con permiso de lectura, con permiso de escritura, con permiso total, y alcances `own` / `assigned_ministry` / `church`.
- Notas pastorales: tests específicos verificando que un admin sin rol pastoral no puede acceder.

## Comandos comunes

```bash
# Entorno
docker compose up
bin/dev                           # foreman: rails + tailwind watcher

# Base de datos
bin/rails db:create db:migrate db:seed
bin/rails db:rollback

# Tests
bundle exec rspec
bundle exec rspec spec/models/member_spec.rb

# Calidad
bundle exec rubocop
bundle exec rubocop -a            # autocorrige lo seguro
bundle exec brakeman
bundle exec bundle-audit check --update
```

## Antes de hacer cambios

- Si la tarea toca **multi-tenant**: validar que toda query filtra por `church_id`.
- Si la tarea toca **permisos**: pasar por `Permissions::PermissionChecker`, nunca hardcodear nombre de rol.
- Si la tarea toca **notas pastorales**: revisar la regla de rol pastoral + permiso explícito.
- Si la tarea introduce un **nuevo modelo operativo**: asegurar `public_id`, `church_id`, scope `active`, índice compuesto, factory y specs de aislamiento.
- Si la tarea introduce un **nuevo modelo global de dominio**: asegurar `public_id`, factory y spec de identificador público.
- Si la tarea introduce una **nueva acción auditable**: integrarla con `paper_trail`.
- Si la tarea cambia la **matriz de permisos** o catálogo de módulos: actualizar seeds y documentación.

## Qué evitar

- `destroy` directo en registros operativos.
- Queries sin scope de iglesia.
- Lógica de autorización basada en `role.name == "Pastor"` u otros nombres.
- Datos sensibles (teléfono, dirección, fecha de nacimiento, notas pastorales) en vistas públicas.
- Romper aislamiento en relaciones polimórficas — siempre llevan `church_id`.
- Crear migraciones que borren datos sin un plan de respaldo.

## Funcionalidades fuera de scope (MVP)

No implementar a menos que se pida explícitamente: subdominios por iglesia, pagos automáticos, notificaciones por WhatsApp/email avanzadas, importación masiva desde Excel, finanzas (diezmos, ofrendas, gastos), visitantes, documentos legales, app móvil nativa.

## Etapa actual

Ver sección 23 de `general planification.md` para el orden recomendado. El proyecto empieza por: Devise + super admin → multi-tenant base → creación de iglesias → roles y matriz de permisos → miembros → ministerios → eventos → resto del MVP.
