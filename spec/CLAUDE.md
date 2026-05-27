# CLAUDE.md — `spec/`

Guía para escribir y mantener los tests del proyecto. Para contexto general, ver [`/CLAUDE.md`](../CLAUDE.md). Para el plan de testing global, ver sección 24 de [`general planification.md`](../general%20planification.md).

## Framework y librerías

- RSpec (`rspec-rails`).
- Factories con `factory_bot_rails`.
- Datos falsos con `faker` (preferir locale `:es` o `:es-MX` cuando aplique).
- Pruebas de sistema con `capybara` + `selenium-webdriver`.

## Estructura

```
spec/
  factories/          # una factory por modelo
  models/             # validaciones, scopes, callbacks
  policies/           # autorización por permiso y alcance
  services/           # lógica de negocio (incluye Permissions::*)
  requests/           # endpoints (HTTP, JSON, redirects)
  system/             # flujos end-to-end con navegador
  support/            # helpers compartidos
```

Cada policy y servicio crítico **debe** tener su spec. Los controladores se prueban vía `requests/` o `system/`.

## Reglas no negociables

### 1. Aislamiento multi-tenant

Toda feature que toque una tabla operativa **debe** tener al menos un spec que:

- Cree dos iglesias (`church_a`, `church_b`).
- Cree datos en ambas.
- Verifique que la operación vista desde `church_a` no toca datos de `church_b` y viceversa.

Ejemplo:

```ruby
it "no muestra miembros de otra iglesia" do
  church_a = create(:church)
  church_b = create(:church)
  member_a = create(:member, church: church_a)
  _member_b = create(:member, church: church_b)

  sign_in_as(user: create(:user), church: church_a, role_permissions: [["members", :list]])
  get church_admin_members_path
  expect(response.body).to include(member_a.first_name)
  expect(response.body).not_to include(_member_b.first_name)
end
```

### 2. Identificadores públicos

Todo modelo de dominio debe tener specs que confirmen:

- Tiene `public_id` UUID.
- `to_param` devuelve `public_id`.
- `find_by_public_id!` rechaza valores que no son UUID.
- Ningún request spec nuevo debe construir URLs con `record.id`.

### 3. Permisos por matriz, no por rol

Las specs de policies deben cubrir como mínimo:

- Sin permiso → todas las acciones `false`.
- `read_only` → `index?`, `show?` true; `create?`, `update?`, `activate?`, `deactivate?` false.
- `read_write` → añade `create?`, `update?` true.
- `full_access` → añade `activate?`, `deactivate?` true.
- Alcances `own`, `assigned_ministry`, `church`: cada uno con un test que confirme qué records sí ve y cuáles no.
- Si el módulo es `pastoral_notes`: test específico de que un admin **sin** rol pastoral no accede aunque tenga permisos full.

### 4. Soft-delete

Cuando un modelo soporta `active`/`status`:

- Test del scope `active` (excluye inactivos).
- Test de la acción `deactivate!` (cambia el flag, **no** llama `destroy`).
- Verificar que la UI lista solo activos por defecto.

### 5. Auditoría

Para acciones marcadas como auditables en `general planification.md` sección 21:

- Spec que verifica que se crea un `PaperTrail::Version` con el `whodunnit` correcto.

## Factories — convenciones

- Nombre singular: `create(:church)`, `create(:member)`.
- Traits para variantes: `:inactive`, `:owner`, `:with_address`, `:pastoral`.
- Asociaciones explícitas: `association :church` siempre que el modelo sea operativo.
- Faker en español: `Faker::Config.locale = :es`.
- No usar `build_stubbed` para tests multi-tenant — necesitas `church_id` real para los joins.

Ejemplo:

```ruby
FactoryBot.define do
  factory :member do
    association :church
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    second_last_name { Faker::Name.last_name }
    phone       { Faker::PhoneNumber.cell_phone }
    birth_date  { 30.years.ago.to_date }
    gender      { %w[male female].sample }
    marital_status { "single" }
    member_status  { "active" }

    trait :inactive do
      member_status { "inactive" }
    end

    trait :with_user do
      association :user
    end
  end
end
```

## Helpers en `support/`

Helpers esperados (crear cuando aparezcan):

- `AuthenticationHelpers#sign_in_as(user:, church:, role_permissions: [])` — loguea y prepara contexto de iglesia + permisos.
- `MultitenantHelpers#with_church(church)` — wrap para ejecutar bloque dentro del contexto de una iglesia.
- `PermissionHelpers#grant(user:, church:, module:, actions:, scope: :church)` — crea Role + RolePermission + MembershipRole listos para el test.

Mantener estos helpers **finos**: si crece la lógica, mover a servicios reales y testear los servicios directamente.

## Performance de tests

- Usar `transactional_fixtures` (default de Rails) — sin `database_cleaner` salvo que aparezcan tests de sistema que lo necesiten.
- Evitar `create` cuando `build` sirve.
- No correr `db:seed` global en tests; crear solo lo necesario por spec.
- Tags `:slow` o `:system` para tests largos, ejecutables aparte.

## Antes de mergear

```bash
bundle exec rspec                       # todo verde
bundle exec rubocop                     # estilo OK
bundle exec brakeman --no-pager         # sin warnings nuevos
```

Si la PR toca:

- **Modelo nuevo:** spec del modelo + factory + spec de `public_id` + spec de aislamiento si es operativo.
- **Policy nueva:** spec con los 4 niveles (sin permiso / read_only / read_write / full_access) + los 3 alcances cuando aplique.
- **Servicio nuevo:** spec del happy path + edge cases.
- **Endpoint nuevo:** request spec + (si es flujo de usuario) system spec.
- **Migración de soft-delete:** spec del scope `active`.

## Qué evitar

- Tests que comparten estado entre `it` (usar `let`/`let!`).
- Stubear `PermissionChecker` en vez de pasar por la matriz real — los bugs viven justo ahí.
- Asumir que `Faker` siempre da datos distintos: usar `sequence` cuando se necesita unicidad real.
- Tests de sistema sin esperar (`have_content`) — Capybara espera, pero asegura el matcher correcto.
- Olvidar cubrir el caso de iglesia distinta en specs de autorización.
