# Diseño: Etapa 14 — Reportes y Exportaciones

## Contexto

La Etapa 14 cierra el módulo de reportes del MVP. Cubre las 5 categorías de la
sección 18 de `general planification.md` (11 reportes), cada uno con vista en
pantalla (tabla paginada) y exportación a CSV y XLSX.

Hallazgo previo: el `module_key` `"reports"` ya existe en
`Permission::MODULE_KEYS` pero **no** en `ASSIGNABLE_MODULE_KEYS`, por lo que aún
no se siembra ni se puede asignar. Esta etapa lo activa.

Hallazgo de esquema: los flags `looking_for_work` y `offers_services` viven en
`member_occupations`, no en `member_skills`. Los reportes laborales se basan en
`member_occupations` para empleo/servicios; `member_skills` solo aporta nivel.

## Permisos

- **Ver reportes** (HTML): requiere `reports/read`.
- **Exportar** (CSV/XLSX): requiere `reports/manage`.
- El **owner** obtiene acceso bootstrap (regla 6); reportes sí, notas pastorales no.
- Se agrega `"reports"` a `Permission::ASSIGNABLE_MODULE_KEYS` y su etiqueta
  `"Reportes"` a los seeds; se re-siembra.

## Arquitectura (Enfoque A)

### Contrato de reporte

Cada reporte vive en `app/services/reports/` y hereda de `Reports::BaseReport`.
Interfaz uniforme:

```ruby
report = Reports::MembersReport.new(church:, filters: {})
report.columns   # => [{ key: :full_name, label: "Nombre completo" }, ...]
report.rows      # => Enumerable de hashes { full_name: "...", ... }, scopeado por church
report.filename  # => "miembros" (base, sin extensión ni fecha)
report.title     # => "Reporte de miembros"
```

`Reports::BaseReport`:
- Guarda `church` y `filters` (hash con indifferent access).
- Define `columns`, `rows` como métodos abstractos (raise `NotImplementedError`).
- Provee helpers de scoping que siempre parten de la asociación de `church`
  (nunca `Model.all`), garantizando aislamiento multi-tenant.

### Exportador

`Reports::Exporter` recibe un objeto de reporte y no conoce ningún reporte
concreto:

```ruby
Reports::Exporter.new(report).to_csv   # => String CSV (librería estándar `csv`)
Reports::Exporter.new(report).to_xlsx  # => binario XLSX (caxlsx)
```

Itera `report.columns` para encabezados y `report.rows` para filas. El
controlador arma el nombre final: `"#{report.filename}-#{Date.current}.csv"`.

### Registro y despacho

`Reports::REGISTRY` mapea una clave de reporte a su clase y metadatos
(categoría, etiqueta, filtros soportados). El controlador usa una acción `show`
genérica que resuelve la clase desde el registro, evitando 11 acciones casi
idénticas.

```ruby
Reports::REGISTRY = {
  "members"               => { class: Reports::MembersReport,            category: :members,    label: "Miembros" },
  "new_members"           => { class: Reports::NewMembersReport,         category: :members,    label: "Miembros nuevos por mes" },
  "birthdays"             => { class: Reports::BirthdaysReport,          category: :birthdays,  label: "Cumpleaños por mes" },
  "members_by_ministry"   => { class: Reports::MembersByMinistryReport,  category: :ministries, label: "Miembros por ministerio" },
  "members_by_occupation" => { class: Reports::MembersByOccupationReport,category: :labor,      label: "Miembros por ocupación" },
  "members_by_skill"      => { class: Reports::MembersBySkillReport,     category: :labor,      label: "Miembros por habilidad" },
  "job_seekers"           => { class: Reports::JobSeekersReport,         category: :labor,      label: "Miembros buscando trabajo" },
  "service_providers"     => { class: Reports::ServiceProvidersReport,   category: :labor,      label: "Miembros que ofrecen servicios" },
  "upcoming_events"       => { class: Reports::UpcomingEventsReport,     category: :events,     label: "Eventos próximos" },
  "event_rsvps"           => { class: Reports::EventRsvpsReport,         category: :events,     label: "Confirmaciones de asistencia" },
  "event_attendance"      => { class: Reports::EventAttendanceReport,    category: :events,     label: "Asistencia real por evento" }
}.freeze
```

## Los 11 reportes

### Miembros
- **MembersReport** — filtro `status` (active/inactive/all). Columnas: nombre
  completo, género, estado civil, teléfono, email, fecha bautismo, fecha
  membresía, estado.
- **NewMembersReport** — filtro `month` (YYYY-MM sobre `official_membership_on`).
  Columnas: nombre, fecha de membresía, teléfono.

### Cumpleaños
- **BirthdaysReport** — filtro `month` (1-12 sobre `birth_date`). Columnas:
  nombre, día, mes, edad que cumple, teléfono. Ordenado por día.

### Ministerios
- **MembersByMinistryReport** — filtro `ministry_id` (o todos). Sobre
  `ministry_memberships` activas. Columnas: ministerio, miembro, rol en
  ministerio, estado.

### Laborales
- **MembersByOccupationReport** — filtro `occupation_id` (o todos). Sobre
  `member_occupations`. Columnas: ocupación, miembro, cargo, estado de empleo,
  teléfono.
- **MembersBySkillReport** — filtro `skill_id` (o todos). Sobre `member_skills`.
  Columnas: habilidad, miembro, nivel, teléfono.
- **JobSeekersReport** — `member_occupations.where(looking_for_work: true)`.
  Columnas: miembro, ocupación, contacto profesional, teléfono, email.
- **ServiceProvidersReport** — `member_occupations.where(offers_services: true)`.
  Columnas: miembro, ocupación, cargo, contacto profesional, teléfono.

### Eventos y asistencia
- **UpcomingEventsReport** — eventos futuros (`starts_at >= now`). Columnas:
  título, fecha, tipo, ministerio, lugar, confirmados.
- **EventRsvpsReport** — filtro `event_id`. Sobre `event_rsvps`. Columnas:
  evento, miembro, estado RSVP, invitados, notas.
- **EventAttendanceReport** — filtro `event_id`. Sobre `event_attendances`.
  Columnas: evento, miembro, ¿asistió?, hora check-in.

## Controlador, rutas y navegación

### `ChurchAdmin::ReportsController`
- `index` — menú de tarjetas agrupadas por categoría, cada una filtrada por
  permiso (solo muestra reportes si `ReportPolicy#index?`).
- `show` — acción genérica:
  1. Autoriza (`ReportPolicy#show?` para HTML, `#export?` para CSV/XLSX).
  2. Resuelve la clase desde `Reports::REGISTRY` por `params[:report]`; 404 si no existe.
  3. Instancia el reporte con `church: @church` y filtros de `params`.
  4. `respond_to`: HTML (tabla paginada con `pagy`), CSV y XLSX (vía `Reports::Exporter`).
  5. Para CSV/XLSX revalida `reports/manage`; si falta, deniega.

### `ReportPolicy`
Sin modelo asociado (estilo `ServiceDirectoryPolicy`), delega en
`Permissions::PermissionChecker`:
- `index?` / `show?` → `permission?("reports", "read")` (o super_admin/owner).
- `export?` → `permission?("reports", "manage")`.

### Rutas
Bajo `namespace :admin, module: :church_admin, as: :admin` dentro de
`resources :churches`:
```ruby
get "reports", to: "reports#index", as: :reports
get "reports/:report", to: "reports#show", as: :report
```

### Navegación
Link "Reportes" en `app/views/shared/_app_navigation.html.erb` condicionado a
`ReportPolicy.new(current_user, nil).index?`.

## Auditoría (regla 7)

Las exportaciones exponen datos sensibles. Como no hay un registro que cambie,
se audita el **evento de exportación** (no un modelo). Al escribir el plan se
verifica si ya existe un patrón de auditoría de acción en el proyecto:
- Si existe, se reutiliza.
- Si no, se registra un `PaperTrail::Version` manual con
  `event: "export"`, `whodunnit: current_user.id`, `item_type: "Report"`,
  `object_changes` con `{ report: clave, format:, filters:, church_id: }`.
Además un `Rails.logger.info` estructurado con los mismos campos.

## Aislamiento multi-tenant (regla 1)

`BaseReport` siempre parte de `church.<asociación>`; nunca `Model.all`. Test
obligatorio por reporte: dos iglesias con datos, verificar que cada reporte solo
devuelve filas de la iglesia actual.

## Testing

- **Servicios (un spec por reporte)**: verifica `columns`, `rows` con cada
  filtro relevante, y aislamiento entre dos iglesias.
- **Exporter**: a partir de un reporte fake, verifica cabeceras y filas en CSV y
  en XLSX (content y estructura).
- **Policy**: `reports/read` permite ver pero no exportar; `reports/manage`
  permite exportar; sin permiso, denegado; owner permitido; sin membresía,
  denegado.
- **Request**: cada acción responde HTML/CSV/XLSX con content-type correcto;
  export sin `reports/manage` devuelve 403/redirect; reporte inexistente 404;
  aislamiento entre iglesias.

## Lo que NO incluye (YAGNI)

- Permiso granular separado de exportación (queda `reports/manage` hasta que se
  justifique).
- Reportes PDF, gráficas o dashboards con métricas agregadas.
- Programación/envío automático de reportes.
- Filtros combinados complejos más allá de los listados por reporte.
