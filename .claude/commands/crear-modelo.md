---
description: Crea un modelo nuevo siguiendo las convenciones multi-tenant de igle-org
argument-hint: <NombreModelo> [campos...]
---

Crea un modelo nuevo en `igle-org` siguiendo todas las convenciones del proyecto. El argumento `$ARGUMENTS` puede ser el nombre del modelo y opcionalmente sus campos al estilo Rails (`name:string status:string`).

Antes de generar nada, pregunta al usuario (vía `AskUserQuestion`):

1. ¿Es un modelo **operativo** (por iglesia) o **global de plataforma**?
2. ¿Debe tener auditoría con `paper_trail`? (default: sí para operativos importantes)
3. ¿Necesita búsqueda con `pg_search`? (default: no)
4. ¿Tiene scope `active` (soft-delete)? (default: sí para operativos)

Una vez confirmado, genera:

### 1. Migración

- Si es operativo: incluye `t.references :church, null: false, foreign_key: true, index: true`.
- Campos pedidos por el usuario.
- Si tiene soft-delete: `t.boolean :active, null: false, default: true` o `t.string :status` según corresponda.
- Timestamps siempre.
- Índice compuesto `[:church_id, :active]` (o equivalente) si tiene soft-delete.
- Índices adicionales por columnas frecuentes de filtro.

### 2. Modelo (`app/models/<nombre>.rb`)

- `belongs_to :church` si es operativo.
- Validaciones con mensajes i18n (en español, en `config/locales/es.yml`).
- Scope `active` (`where(active: true)` o equivalente).
- Validación `validate :same_church_as_<relacion>` si tiene asociaciones cruzadas.
- Si necesita auditoría: `has_paper_trail`.
- Si necesita búsqueda: `include PgSearch::Model` + `pg_search_scope`.
- **No** sobrescribir `destroy` para hacer soft-delete; usar `deactivate!` explícito.

### 3. Factory (`spec/factories/<plural>.rb`)

- Trait `:inactive` si tiene soft-delete.
- Usa Faker en español donde aplique.
- Si es operativo: `association :church`.

### 4. Specs mínimas (`spec/models/<nombre>_spec.rb`)

- Validaciones presentes.
- Scope `active` excluye inactivos.
- **Aislamiento multi-tenant**: crear dos iglesias y verificar que el scope no mezcla datos.
- Validación `same_church` rechaza asociaciones de otra iglesia (si aplica).

### 5. Traducciones

- Agregar entrada en `config/locales/es.yml` bajo `activerecord.models` y `activerecord.attributes.<modelo>`.

### 6. Reportar al final

- Lista de archivos creados/modificados.
- Comandos a correr: `bin/rails db:migrate` y `bundle exec rspec spec/models/<nombre>_spec.rb`.
- Recordatorio si toca actualizar `permission_modules` o seeds.

**No** ejecutes la migración automáticamente — solo genera los archivos y dile al usuario qué correr.
