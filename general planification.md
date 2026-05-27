# General Planification - Igle Org

## 1. Propósito Del Proyecto

Crear una aplicación web con Ruby on Rails y PostgreSQL para administrar iglesias dentro de una plataforma multi-iglesia.

La aplicación debe permitir que varias iglesias usen la misma plataforma, pero que cada iglesia trabaje de forma independiente, con sus propios miembros, usuarios, roles internos, ministerios, junta directiva, eventos, reportes, configuración, datos de contacto y reglas de privacidad.

El sistema tendrá un super administrador de plataforma, responsable de registrar iglesias y administrar el uso global del sistema. Cada iglesia tendrá sus propios administradores, pastores, líderes de ministerio y miembros.

Este archivo funciona como guía principal del proyecto. Debe actualizarse conforme se tomen decisiones nuevas.

## 2. Decisiones Ya Confirmadas

Estas decisiones quedan definidas desde el inicio:

- La aplicación será multi-iglesia.
- Cada iglesia será independiente y no podrá ver datos de otras iglesias.
- Existirá un super administrador de plataforma.
- Solo el super administrador podrá crear nuevas iglesias.
- Cada iglesia tendrá al menos un administrador propio.
- Una misma persona/usuario podrá pertenecer a más de una iglesia.
- Cada iglesia será una entidad independiente, no una sede de otra iglesia.
- Cada iglesia tendrá su propia configuración: logo, nombre, colores, horarios y contactos.
- Los subdominios por iglesia son deseados en el futuro, pero no son prioridad del MVP.
- Los usuarios normales serán registrados por el administrador de cada iglesia.
- Los miembros podrán iniciar sesión para ver su perfil, eventos e información permitida.
- Los miembros podrán editar su perfil, pero los cambios deben aprobarse antes de aplicarse.
- Los roles de plataforma deben estar separados de los roles internos de cada iglesia.
- Los roles internos de iglesia no deben venir con permisos fijos desde el inicio.
- Cada iglesia podrá crear todos los roles que necesite.
- Cada iglesia debe configurar los permisos de cada rol desde una pantalla tipo matriz.
- Los permisos deben asignarse por módulo o vista de la plataforma.
- Los permisos deben permitir lectura, escritura, activación/desactivación y otras acciones necesarias.
- La matriz de permisos debe tener checkboxes por cada acción.
- Los atajos de permisos deben funcionar así: lectura solo permite leer; escritura permite leer, crear y editar; total permite leer, crear, editar, activar y desactivar.
- Una persona podrá tener varios roles al mismo tiempo.
- La junta directiva será una entidad separada, no solo un rol.
- Solo se manejarán miembros oficiales, no visitantes, en la primera versión.
- La junta directiva será opcional.
- La junta administrativa tendrá cargos definidos: presidente, vicepresidente, secretario, tesorero, vocal 1, vocal 2, vocal 3 y fiscal.
- Los miembros de la junta administrativa deben seleccionarse desde la lista de miembros de la iglesia.
- Ser parte de la junta administrativa no debe crear ni depender de un rol de permisos.
- Debe existir historial de juntas anteriores.
- Los eventos podrán repetirse.
- Los miembros podrán confirmar asistencia a eventos.
- Se desea registrar asistencia a eventos.
- La información laboral podrá alimentar un directorio de servicios por iglesia.
- Cada iglesia podrá activar o desactivar si los miembros pueden contactar a otros por temas laborales.
- Las notas pastorales serán privadas y visibles solo para roles pastorales.
- Un administrador de iglesia no puede ver notas pastorales salvo que también tenga un rol pastoral real.
- Los registros deben activarse/desactivarse, no borrarse físicamente.
- Debe existir auditoría de cambios importantes.
- La app debe funcionar bien en español.
- Debe ser responsive para computadora, teléfono y tablet.
- El deployment objetivo es DigitalOcean.
- La plataforma tendrá una tarifa única para iglesias; el monto se definirá después.
- La versión objetivo de Rails será Rails 8.
- El proyecto usará Docker.
- La estrategia exacta de despliegue en DigitalOcean se definirá en la etapa de producción.
- El nombre comercial provisional será `igle-org`.
- El diseño visual base usará Tailwind CSS y componentes estilo Tailwind UI Pro.
- Finanzas, diezmos, ofrendas y gastos serán funcionalidades futuras.
- El administrador inicial de cada iglesia tendrá acceso completo administrativo.
- Las ocupaciones y habilidades del miembro podrán completarse después del registro inicial.
- Un miembro puede existir sin pertenecer a un ministerio.
- El email del miembro será opcional.
- La página pública básica de cada iglesia será parte del MVP.

## 3. Objetivos Principales

- Centralizar la administración de iglesias dentro de una plataforma multi-tenant.
- Permitir que cada iglesia administre sus datos de forma aislada.
- Registrar iglesias desde un panel de super administrador.
- Registrar usuarios por iglesia.
- Registrar miembros oficiales.
- Registrar pastores, líderes de ministerio y administradores internos.
- Administrar roles internos personalizados por iglesia.
- Administrar una matriz de permisos por rol, módulo y acción.
- Registrar ministerios y miembros asignados.
- Registrar junta directiva cuando la iglesia la tenga.
- Registrar eventos, actividades, cultos y reuniones.
- Permitir eventos recurrentes.
- Permitir confirmación de asistencia.
- Registrar asistencia real a eventos.
- Registrar datos personales importantes de miembros.
- Registrar familia/hogar de miembros.
- Registrar ocupaciones, habilidades y disponibilidad laboral.
- Crear directorio de servicios por iglesia.
- Proteger datos sensibles mediante permisos.
- Registrar notas pastorales privadas.
- Generar reportes básicos.
- Exportar información a CSV/Excel.

## 4. Alcance Inicial Del MVP

El MVP debe incluir desde el inicio la arquitectura multi-iglesia, aunque algunas funciones avanzadas se implementen después.

Incluye:

- Plataforma multi-iglesia.
- Super administrador.
- Creación de iglesias por super administrador.
- Configuración básica por iglesia.
- Usuario administrador por iglesia.
- Login de usuarios.
- Miembros oficiales.
- Perfil de miembro.
- Solicitud y aprobación de cambios de perfil.
- Página pública básica de iglesia con nombre, logo y detalles generales.
- Roles de sistema y roles internos de iglesia.
- Matriz configurable de permisos por rol.
- Pastores.
- Líderes de ministerio.
- Ministerios.
- Junta directiva opcional.
- Eventos y actividades.
- Eventos recurrentes.
- Confirmación de asistencia.
- Registro básico de asistencia.
- Ocupaciones y habilidades.
- Directorio de servicios por iglesia.
- Reportes básicos.
- Exportación CSV/Excel.
- Auditoría de cambios importantes.
- Activar/desactivar registros.

No incluye en la primera versión:

- Subdominios por iglesia.
- Pagos automáticos integrados.
- Notificaciones por WhatsApp.
- Notificaciones por email avanzadas.
- Importación de miembros desde Excel.
- Aplicación móvil nativa.
- Finanzas completas: diezmos, ofrendas y gastos.
- Visitantes.
- Documentos legales de iglesia.

## 5. Tipo De Aplicación

Aplicación web monolítica usando Ruby on Rails y PostgreSQL.

Stack sugerido:

- Ruby on Rails.
- PostgreSQL.
- Hotwire/Turbo/Stimulus para interactividad.
- Tailwind CSS para interfaz moderna y flexible.
- Tailwind UI Pro como referencia/base visual para componentes.
- Docker para desarrollo y preparación de despliegue.
- Devise para autenticación.
- Pundit como base de autorización.
- Capa propia de permisos dinámicos por rol, módulo y acción.
- Active Storage para logos y fotos.
- Active Job con Solid Queue para trabajos en segundo plano si se necesitan.
- PostgreSQL como base relacional principal.

## 6. Versiones Definidas

Versiones y entorno definidos para iniciar desarrollo:

- Ruby: 3.4.9.
- Rails: Rails 8.x, usando la última versión estable disponible al momento de crear la app.
- PostgreSQL: versión 15 o superior.
- Node/Yarn/Bun: según el setup elegido.
- Docker: sí, para desarrollo local y preparación de ambientes.
- Sistema operativo de producción: Linux en DigitalOcean.

## 7. Comando Inicial Sugerido

Cuando llegue el momento de crear la aplicación:

```bash
rails new igle-org --database=postgresql --css=tailwind
```

Definido antes de ejecutar:

- Usar Rails 8.
- Usar Docker.
- Usar Tailwind CSS como base visual.
- Mantener el nombre provisional `igle-org`.
- Dejar la estrategia exacta de DigitalOcean para la etapa de despliegue.

## 8. Gemas Recomendadas

### Autenticación

- `devise`: login, logout, recuperación de contraseña e invitación base si se extiende.

### Autorización

- `pundit`: políticas por modelo, útil para multi-tenant.
- Sistema propio de permisos dinámicos para roles internos de iglesia.

Notas:

- Pundit debe validar la iglesia actual y llamar a un servicio interno de permisos.
- Los permisos de iglesia no deben estar quemados en código por nombre de rol.
- La app debe preguntar si el usuario tiene permiso para una acción específica sobre un módulo específico.

### Interfaz

- `tailwindcss-rails`: estilos.
- `turbo-rails`: navegación y actualizaciones parciales.
- `stimulus-rails`: interacciones pequeñas.
- `simple_form`: formularios más limpios.

### Paginación Y Búsqueda

- `pagy`: paginación ligera.
- `pg_search`: búsqueda por nombre, ocupación, habilidad, ministerio y datos relevantes.

### Archivos

- `image_processing`: procesamiento de logos y fotos con Active Storage.

### Auditoría

- `paper_trail`: historial de cambios importantes.

### Exportaciones

- `csv`: librería estándar de Ruby para CSV.
- `caxlsx`: exportación a Excel si se necesita `.xlsx`.

### Eventos Recurrentes

Opciones a evaluar:

- Usar campos propios simples para recurrencia semanal/mensual.
- Usar una gema como `ice_cube` si se necesita recurrencia compleja.

Recomendación:

- Para MVP, empezar con recurrencia simple: diaria, semanal, mensual y fecha final opcional.
- Si luego se necesitan reglas complejas, evaluar `ice_cube`.

### Testing

- `rspec-rails`: pruebas.
- `factory_bot_rails`: factories.
- `faker`: datos falsos para pruebas y seeds.
- `capybara`: pruebas de sistema.

### Calidad Y Seguridad

- `rubocop-rails`: estilo de código.
- `brakeman`: seguridad.
- `bundler-audit`: vulnerabilidades de gemas.
- `dotenv-rails`: variables de entorno en desarrollo.

## 9. Arquitectura Multi-Tenant

La aplicación debe diseñarse como multi-tenant desde el inicio.

Tenant principal:

- `churches`

Regla central:

- Toda información operativa debe pertenecer a una iglesia mediante `church_id`, salvo entidades globales de plataforma.
- Toda tabla de dominio debe tener un `public_id` tipo UUID único.
- Las rutas públicas o internas que identifiquen cualquier recurso de dominio no deben exponer el `id` numérico.
- URLs, APIs, formularios, logs visibles y referencias externas deben usar `public_id`.
- Ejemplo de ruta segura: `/churches/9d5f2f44-1b0c-4b8f-9d6b-8f1f0d7e3c21`.
- Las tablas internas de Rails, como `active_storage_*`, no se tratan como recursos del dominio y no deben exponerse directamente.

Entidades globales:

- `users`
- `platform_roles`, si se decide separar roles de plataforma.
- `permissions`
- `plans`
- `subscriptions`
- Configuración global del sistema.

Entidades por iglesia:

- Miembros.
- Ministerios.
- Eventos.
- Junta directiva.
- Roles internos.
- Permisos por rol.
- Ocupaciones.
- Habilidades.
- Contactos.
- Reportes.
- Configuración visual.
- Solicitudes de cambio.
- Notas pastorales.

Reglas de aislamiento:

- Un propietario o rol autorizado solo ve datos de su iglesia.
- Un usuario con permiso pastoral solo ve datos pastorales dentro de su iglesia.
- Un usuario con alcance de ministerio solo administra ministerios asignados dentro de su iglesia.
- Un miembro solo ve su perfil, eventos permitidos y datos públicos autorizados.
- El super administrador puede ver y administrar todas las iglesias.

Consideración importante:

- Como una misma persona puede pertenecer a más de una iglesia, `users` debe ser global.
- La pertenencia a iglesias debe manejarse con una tabla intermedia como `church_memberships`.
- El perfil de miembro debe pertenecer a una iglesia y puede estar conectado a un usuario global.

## 10. Estructura General Del Proyecto Rails

Estructura base esperada:

```text
app/
  controllers/
  models/
  views/
  policies/
  helpers/
  mailers/
  jobs/
  services/
  components/
config/
db/
  migrate/
  seeds.rb
spec/
```

Estructura sugerida por dominio:

```text
app/models/
  user.rb
  church.rb
  church_membership.rb
  church_setting.rb
  member.rb
  family.rb
  family_member.rb
  role.rb
  membership_role.rb
  permission.rb
  role_permission.rb
  ministry.rb
  ministry_membership.rb
  board.rb
  board_member.rb
  event.rb
  event_occurrence.rb
  event_attendance.rb
  event_rsvp.rb
  occupation.rb
  member_occupation.rb
  skill.rb
  member_skill.rb
  profile_change_request.rb
  pastoral_note.rb
  contact_method.rb
  address.rb
  plan.rb
  subscription.rb

app/controllers/
  platform/
    dashboard_controller.rb
    churches_controller.rb
    users_controller.rb
    plans_controller.rb
    subscriptions_controller.rb
  church_admin/
    dashboard_controller.rb
    members_controller.rb
    users_controller.rb
    roles_controller.rb
    role_permissions_controller.rb
    ministries_controller.rb
    boards_controller.rb
    events_controller.rb
    reports_controller.rb
    settings_controller.rb
  pastor/
    dashboard_controller.rb
    members_controller.rb
    pastoral_notes_controller.rb
  ministry_leader/
    dashboard_controller.rb
    ministries_controller.rb
    events_controller.rb
  member_portal/
    profiles_controller.rb
    profile_change_requests_controller.rb
    events_controller.rb
    service_directory_controller.rb
  public/
    churches_controller.rb

app/policies/
  church_policy.rb
  role_policy.rb
  role_permission_policy.rb
  member_policy.rb
  ministry_policy.rb
  event_policy.rb
  board_policy.rb
  pastoral_note_policy.rb
  profile_change_request_policy.rb
  service_directory_policy.rb

app/services/
  tenants/
    current_church_resolver.rb
  permissions/
    permission_checker.rb
    permission_matrix_builder.rb
  members/
    search_service.rb
  events/
    recurrence_builder.rb
  reports/
    members_report_service.rb
    birthdays_report_service.rb
    work_directory_report_service.rb
```

## 11. Conceptos Principales Del Dominio

### Plataforma

Representa el sistema completo.

Responsabilidades:

- Administrar iglesias registradas.
- Administrar planes.
- Administrar estado de suscripción.
- Permitir al super administrador revisar el estado general.

### Iglesia

Representa una iglesia independiente dentro de la plataforma.

Datos confirmados:

- Nombre.
- Dirección.
- Teléfono.
- Email.
- Logo.
- Horarios de cultos.
- Colores de marca.
- Información pública básica.

Datos sugeridos adicionales:

- Nombre legal.
- Descripción.
- WhatsApp.
- Sitio web.
- Redes sociales.
- País.
- Ciudad.
- Estado/provincia.
- Estado de cuenta: activa, suspendida, cancelada.
- Slug para URL pública.
- Subdominio futuro.

### Usuario

Representa una cuenta global que puede iniciar sesión.

Un usuario puede:

- Ser super administrador.
- Administrar una iglesia.
- Ser pastor en una iglesia.
- Ser líder de ministerio en una iglesia.
- Ser miembro en una o varias iglesias.

El usuario no debe guardar directamente todos sus permisos dentro de la tabla `users`, porque sus permisos pueden cambiar según la iglesia.

### Church User

Representa la relación entre un usuario global y una iglesia específica.

Ejemplo:

- El usuario Juan puede ser administrador en Iglesia A.
- El mismo usuario Juan puede ser miembro normal en Iglesia B.

Esta tabla es clave para multi-iglesia.

### Roles Y Permisos Configurables

Cada iglesia podrá crear sus propios roles, sin depender de permisos fijos definidos por el sistema.

La administración de roles debe funcionar como una página separada:

- El propietario de iglesia o un usuario autorizado entra a la sección de roles.
- Crea o selecciona un rol.
- El sistema muestra todos los módulos o vistas disponibles para esa iglesia.
- Para cada módulo/vista, el administrador marca los permisos permitidos.
- El usuario que tenga ese rol solo podrá hacer lo que su matriz de permisos permita.

Permisos base sugeridos:

- Sin acceso.
- Lectura/listado.
- Ver detalle.
- Crear.
- Editar.
- Activar.
- Desactivar.
- Exportar.
- Administrar permisos, solo para roles autorizados.

La interfaz puede incluir accesos rápidos como:

- Sin acceso para todo el módulo.
- Solo lectura para todo el módulo.
- Acceso completo para todo el módulo.

Ejemplos de módulos o vistas:

- Dashboard.
- Miembros.
- Usuarios.
- Roles y permisos.
- Ministerios.
- Junta directiva.
- Eventos.
- Asistencia.
- Directorio de servicios.
- Reportes.
- Configuración de iglesia.
- Solicitudes de cambio.
- Notas pastorales.

Reglas importantes:

- Los roles son por iglesia.
- Cada iglesia puede crear cualquier cantidad de roles.
- Los roles no deben tener permisos automáticos por su nombre.
- Un rol llamado `Pastor` solo tendrá permisos pastorales si la iglesia se los asigna.
- Un rol llamado `Líder de ministerio` solo administrará ministerios si tiene esos permisos.
- La app debe validar permisos por acción, no solo por nombre de rol.
- Algunos permisos pueden tener alcance: toda la iglesia, solo ministerios asignados, solo perfil propio.

### Miembro

Representa un miembro oficial de una iglesia.

Datos obligatorios confirmados:

- Nombre.
- Apellido.
- Segundo apellido.
- Teléfono.
- Email.
- Fecha de nacimiento.
- Género.
- Estado civil.
- Ocupación.
- Habilidades.
- Ministerios a los que pertenece.

Datos adicionales confirmados:

- Dirección exacta.
- Fecha de bautismo.
- Fecha de membresía oficial.
- Familia/hogar.
- Estado: activo o inactivo.

No se manejarán visitantes en la primera versión.

### Familia U Hogar

Permite relacionar miembros entre sí.

Ejemplos:

- Esposo.
- Esposa.
- Hijo.
- Hija.
- Padre.
- Madre.
- Encargado.
- Otro.

Cada familia debe pertenecer a una iglesia.

### Pastor

No debe ser una tabla totalmente separada al inicio.

Recomendación:

- Un pastor es un miembro o usuario con un rol interno dentro de una iglesia.
- El nombre del rol puede ser `Pastor`, `Pastor general` u otro definido por la iglesia.
- El rol debe estar marcado como pastoral para recibir permisos de notas pastorales.
- El acceso pastoral real depende de permisos asignados en la matriz.
- Las notas pastorales solo serán visibles para usuarios con rol pastoral y permiso de notas pastorales.

### Ministerio

Representa un área de servicio dentro de una iglesia.

Ejemplos:

- Alabanza.
- Jóvenes.
- Niños.
- Ujieres.
- Evangelismo.
- Intercesión.
- Escuela dominical.
- Matrimonios.

Cada ministerio puede tener:

- Nombre.
- Descripción.
- Líder.
- Miembros asignados.
- Eventos propios.
- Estado activo/inactivo.

### Líder De Ministerio

Un líder de ministerio no debe depender solamente del nombre del rol.

Para que un usuario administre un ministerio:

- Debe tener un rol con permisos sobre ministerios.
- El permiso puede limitarse al alcance `solo ministerios asignados`.
- Debe existir una relación que indique qué ministerio lidera o administra.

Permisos posibles:

- Ver su ministerio.
- Ver miembros asignados.
- Crear eventos para su ministerio.
- Editar eventos de su ministerio.
- Gestionar información relacionada con su ministerio.

No debe poder administrar toda la iglesia salvo que tenga otro rol adicional.

### Junta Directiva

Entidad opcional por iglesia.

Debe permitir:

- Crear junta administrativa o directiva.
- Definir periodo de inicio y fin.
- Asignar miembros existentes de la iglesia a cargos definidos.
- Seleccionar cada integrante desde la lista de miembros activos de la iglesia.
- Mantener historial de juntas anteriores.
- Activar/desactivar junta.

Campos/cargos definidos:

- Presidente.
- Vicepresidente.
- Secretario.
- Tesorero.
- Vocal 1.
- Vocal 2.
- Vocal 3.
- Fiscal.

Reglas:

- La junta directiva no tendrá permisos especiales por defecto.
- Formar parte de la junta no convierte al miembro en usuario administrador.
- Formar parte de la junta no asigna roles automáticamente.
- Si un miembro de junta necesita acceso al sistema, debe recibir un rol/permisos desde la matriz de roles.

### Eventos Y Actividades

Eventos confirmados para primera versión:

- Horarios de cultos.
- Reuniones de ministerios.
- Bodas.
- Bautismos.
- Retiros.
- Eventos especiales.

Características:

- Eventos públicos.
- Eventos privados.
- Eventos solo para miembros.
- Eventos recurrentes.
- Confirmación de asistencia.
- Registro de asistencia real.
- Responsable del evento.
- Ministerio asociado opcional.

Pueden crear eventos:

- Usuarios con permiso `events.can_create`.
- Usuarios con alcance `church`, para eventos de toda la iglesia.
- Usuarios con alcance `assigned_ministry`, solo para eventos de sus ministerios asignados.

### Ocupaciones, Habilidades Y Directorio De Servicios

Objetivo:

- Saber en qué trabaja cada miembro.
- Saber si busca trabajo.
- Saber si ofrece servicios.
- Recomendar miembros dentro de su iglesia.
- Crear un directorio de servicios por iglesia.

Debe distinguir:

- Miembro busca trabajo.
- Miembro ofrece servicios.
- Miembro tiene ocupación actual.
- Miembro tiene habilidades específicas.

Cada iglesia podrá configurar si los miembros pueden contactar a otros por temas laborales.

### Notas Pastorales

Notas privadas relacionadas con seguimiento pastoral.

Reglas confirmadas:

- Solo roles pastorales pueden ver notas pastorales.
- Un administrador de iglesia no puede ver notas pastorales solo por ser administrador.
- Si una persona es administradora y también pastor, debe tener un rol pastoral separado para acceder a notas pastorales.
- Deben pertenecer a una iglesia.
- Deben estar asociadas a un miembro.
- Deben quedar protegidas por políticas estrictas.
- Deben auditarse cambios importantes.

### Solicitudes De Cambio De Perfil

Como los miembros pueden editar su perfil, pero los cambios deben aprobarse:

- El miembro propone un cambio.
- El sistema guarda una solicitud pendiente.
- Un administrador o rol autorizado revisa.
- Si se aprueba, se aplican los cambios al perfil.
- Si se rechaza, se guarda motivo opcional.

## 12. Modelo De Base De Datos Propuesto

Este modelo es la base recomendada para evitar cambios grandes durante desarrollo.

Regla de identificadores:

- Todo modelo de dominio debe incluir `public_id` UUID único además del `id` interno.
- El `id` interno queda solo para relaciones de base de datos.
- URLs, APIs, formularios, logs visibles y referencias externas deben usar `public_id`.
- Si una lista de campos futura omite `public_id`, se asume igualmente obligatorio para mantener esta regla.

### users

Responsabilidad:

- Cuenta global de acceso.

Campos sugeridos:

- `id`
- `public_id`
- `email`
- `encrypted_password`
- `reset_password_token`
- `reset_password_sent_at`
- `remember_created_at`
- `first_name`
- `last_name`
- `phone`
- `platform_role`
- `active`
- `last_sign_in_at`
- `created_at`
- `updated_at`

Valores sugeridos para `platform_role`:

- `regular`
- `super_admin`

Relaciones:

- `has_many :church_memberships`
- `has_many :churches, through: :church_memberships`
- `has_many :members`

Notas:

- El super administrador se maneja aquí.
- Los permisos internos de iglesia no deben vivir directamente en `users`.

### churches

Responsabilidad:

- Tenant principal de la aplicación.

Campos sugeridos:

- `id`
- `public_id`
- `name`
- `legal_name`
- `slug`
- `subdomain`
- `description`
- `email`
- `phone`
- `whatsapp`
- `website`
- `address_line_1`
- `address_line_2`
- `city`
- `state`
- `country`
- `postal_code`
- `status`
- `primary_color`
- `secondary_color`
- `public_page_enabled`
- `service_directory_enabled`
- `member_work_contact_enabled`
- `created_by_id`
- `created_at`
- `updated_at`

Valores sugeridos para `status`:

- `active`
- `suspended`
- `cancelled`

Relaciones:

- `has_many :church_memberships`
- `has_many :users, through: :church_memberships`
- `has_many :members`
- `has_many :ministries`
- `has_many :boards`
- `has_many :events`
- `has_many :roles`
- `has_many :families`
- `has_many :subscriptions`
- `has_one_attached :logo`

Notas:

- `subdomain` queda listo para futuro.
- `service_directory_enabled` controla si existe directorio de servicios.
- `member_work_contact_enabled` controla si miembros pueden contactar a otros por temas laborales.

### church_memberships

Responsabilidad:

- Relacionar usuarios globales con iglesias.

Campos sugeridos:

- `id`
- `public_id`
- `church_id`
- `user_id`
- `status`
- `owner`
- `invited_by_id`
- `invited_at`
- `accepted_at`
- `last_accessed_at`
- `created_at`
- `updated_at`

Valores sugeridos para `status`:

- `invited`
- `active`
- `inactive`
- `suspended`

Índices:

- Único para `church_id` + `user_id`.
- Índice por `user_id`.
- Índice por `church_id`.

Notas:

- Esta tabla permite que un mismo usuario pertenezca a más de una iglesia.
- Los roles internos deben asignarse sobre esta relación o sobre el miembro relacionado.
- `owner` permite dar acceso bootstrap al administrador principal sin depender de roles predefinidos.
- Este es el nombre implementado en la base actual del proyecto.

### roles

Responsabilidad:

- Definir roles internos de iglesia.

Campos sugeridos:

- `id`
- `public_id`
- `church_id`
- `name`
- `key`
- `description`
- `pastoral`
- `protected`
- `active`
- `created_at`
- `updated_at`

Notas:

- Los roles son por iglesia.
- Cada iglesia puede crear roles personalizados sin límite práctico.
- El nombre del rol no debe definir sus permisos.
- Los permisos se definen en `role_permissions`.
- `pastoral` identifica roles pastorales y permite controlar acceso a notas pastorales.
- `protected` puede usarse para evitar borrar o desactivar un rol crítico si la iglesia lo decide.

Ejemplos de nombres de rol que una iglesia podría crear:

- Administrador.
- Pastor general.
- Pastor asistente.
- Líder de jóvenes.
- Líder de alabanza.
- Secretario.
- Tesorero.
- Miembro.

Importante:

- No se deben crear permisos automáticos solo por llamar a un rol `Administrador` o `Pastor`.
- Cada rol debe pasar por la matriz de permisos.
- El módulo de notas pastorales solo puede asignarse a roles marcados como pastorales.
- El primer administrador/propietario de iglesia necesita un acceso bootstrap para poder crear roles y permisos iniciales.

### permissions

Responsabilidad:

- Definir el catálogo global de módulo/vista + acción disponible para permisos.

Campos sugeridos:

- `id`
- `public_id`
- `module_key`
- `action_key`
- `name`
- `description`
- `position`
- `created_at`
- `updated_at`

Ejemplos de `module_key`:

- `dashboard`
- `members`
- `users`
- `roles_permissions`
- `ministries`
- `boards`
- `events`
- `event_attendance`
- `service_directory`
- `reports`
- `church_settings`
- `profile_change_requests`
- `pastoral_notes`

Ejemplos de `action_key`:

- `read`
- `create`
- `update`
- `activate`
- `deactivate`
- `export`
- `manage`

Notas:

- Esta tabla puede ser global de plataforma.
- Define qué filas y checkboxes aparecen en la pantalla de permisos.
- Una iglesia no crea estos permisos base; la plataforma los ofrece según funcionalidades disponibles.
- Si en el futuro un plan no incluye un módulo, se puede ocultar o bloquear para esa iglesia.

### role_permissions

Responsabilidad:

- Guardar qué permisos concretos tiene un rol.

Campos sugeridos:

- `id`
- `public_id`
- `role_id`
- `permission_id`
- `created_at`
- `updated_at`

Modelo implementado:

- Cada fila representa un permiso asignado.
- `permission_id` apunta a una combinación `module_key` + `action_key`.
- Los atajos de interfaz como `read_only`, `read_write` y `full_access` se calculan marcando varias filas de permisos.

Campos futuros si se necesita alcance granular:

- `own`
- `assigned_ministry`
- `church`

Notas:

- La interfaz debe mostrar un checkbox por cada acción disponible del módulo.
- `read_only` activa lectura/listado/ver detalle.
- `read_write` activa lectura/listado/ver detalle, crear y editar.
- `full_access` activa lectura/listado/ver detalle, crear, editar, activar y desactivar.
- Permisos especiales como exportar o administrar pueden seguir siendo checkboxes separados cuando aplique.
- `no_access` debe desactivar todos los permisos de ese módulo.
- El módulo `pastoral_notes` solo puede tener permisos activos para roles marcados como pastorales.
- El alcance `assigned_ministry` es importante para líderes de ministerio.
- El alcance `own` es importante para miembros que solo deben administrar su perfil.
- Un usuario con varios roles debe recibir la unión de permisos más amplia, salvo que se decida implementar denegaciones explícitas.

### membership_roles

Responsabilidad:

- Asignar roles internos a un usuario dentro de una iglesia.

Campos sugeridos:

- `id`
- `public_id`
- `church_membership_id`
- `role_id`
- `assignable_type`
- `assignable_id`
- `created_at`
- `updated_at`

Uso:

- Rol general de iglesia: `assignable` puede quedar vacío.
- Rol de líder de ministerio: `assignable` puede apuntar a `Ministry`.

Índices:

- `church_membership_id`
- `role_id`
- `assignable_type` + `assignable_id`

Notas:

- Permite varios roles por persona.
- Permite roles limitados a un ministerio específico.

### members

Responsabilidad:

- Perfil oficial de miembro dentro de una iglesia.

Campos sugeridos:

- `id`
- `public_id`
- `church_id`
- `user_id`
- `first_name`
- `middle_name`
- `last_name`
- `second_last_name`
- `email`
- `phone`
- `secondary_phone`
- `birth_date`
- `gender`
- `marital_status`
- `children_count`
- `baptized_on`
- `official_membership_on`
- `member_status`
- `notes`
- `emergency_contact_name`
- `emergency_contact_phone`
- `created_at`
- `updated_at`

Valores sugeridos para `member_status`:

- `active`
- `inactive`

Relaciones:

- `belongs_to :church`
- `belongs_to :user, optional: true`
- `has_many :ministry_memberships`
- `has_many :ministries, through: :ministry_memberships`
- `has_many :member_occupations`
- `has_many :occupations, through: :member_occupations`
- `has_many :member_skills`
- `has_many :skills, through: :member_skills`
- `has_many :pastoral_notes`

Validaciones:

- Nombre requerido.
- Apellido requerido.
- Segundo apellido requerido.
- Teléfono requerido.
- Email opcional.
- Fecha de nacimiento requerida.
- Género requerido.
- Estado civil requerido.
- Si el email existe, debe tener formato válido.
- Fecha de nacimiento no puede ser futura.
- Fecha de bautismo no puede ser futura.
- Fecha de membresía oficial no puede ser futura.

Notas:

- Un usuario global puede tener varios perfiles de miembro, uno por iglesia.
- No se debe borrar físicamente; usar `member_status`.

### families

Responsabilidad:

- Representar hogares o familias dentro de una iglesia.

Campos sugeridos:

- `id`
- `church_id`
- `name`
- `address_id`
- `notes`
- `active`
- `created_at`
- `updated_at`

### family_members

Responsabilidad:

- Relacionar miembros con una familia/hogar.

Campos sugeridos:

- `id`
- `church_id`
- `family_id`
- `member_id`
- `relationship`
- `primary_contact`
- `created_at`
- `updated_at`

Valores sugeridos para `relationship`:

- `spouse`
- `child`
- `parent`
- `guardian`
- `sibling`
- `other`

### addresses

Responsabilidad:

- Guardar direcciones exactas de miembros, familias o iglesias.

Campos sugeridos:

- `id`
- `church_id`
- `addressable_type`
- `addressable_id`
- `line_1`
- `line_2`
- `city`
- `state`
- `country`
- `postal_code`
- `reference`
- `created_at`
- `updated_at`

Notas:

- Aunque la relación sea polimórfica, debe incluir `church_id` para aislamiento.

### ministries

Responsabilidad:

- Registrar ministerios por iglesia.

Campos sugeridos:

- `id`
- `church_id`
- `name`
- `description`
- `active`
- `created_at`
- `updated_at`

Relaciones:

- `belongs_to :church`
- `has_many :ministry_memberships`
- `has_many :members, through: :ministry_memberships`
- `has_many :events`

### ministry_memberships

Responsabilidad:

- Relacionar miembros con ministerios.

Campos sugeridos:

- `id`
- `church_id`
- `ministry_id`
- `member_id`
- `role`
- `starts_on`
- `ends_on`
- `active`
- `created_at`
- `updated_at`

Valores sugeridos para `role`:

- `leader`
- `assistant`
- `member`

Notas:

- El líder de ministerio también debe tener un rol/permisos en `membership_roles`.

### boards

Responsabilidad:

- Registrar juntas directivas opcionales por iglesia.

Campos sugeridos:

- `id`
- `church_id`
- `name`
- `starts_on`
- `ends_on`
- `active`
- `notes`
- `created_at`
- `updated_at`

Validaciones:

- Iglesia requerida.
- Nombre requerido.
- Fecha inicial requerida.
- Fecha final posterior a fecha inicial.

### board_members

Responsabilidad:

- Relacionar miembros existentes de la iglesia con una junta y un cargo definido.

Campos sugeridos:

- `id`
- `church_id`
- `board_id`
- `member_id`
- `position`
- `starts_on`
- `ends_on`
- `active`
- `created_at`
- `updated_at`

Valores sugeridos para `position`:

- `president`
- `vice_president`
- `secretary`
- `treasurer`
- `vocal_1`
- `vocal_2`
- `vocal_3`
- `fiscal`

Notas:

- El `member_id` debe salir de la lista de miembros de la misma iglesia.
- No debe permitir seleccionar usuarios que no sean miembros de esa iglesia.
- No debe permitir seleccionar miembros inactivos, salvo que se decida permitir historial.
- Cada cargo debe estar ocupado por un solo miembro dentro de una misma junta activa.
- Permite historial de miembros en juntas anteriores.
- No otorga permisos especiales automáticamente.
- Aunque la base de datos use `board_members` con `position`, la interfaz debe presentarse como campos claros: presidente, vicepresidente, secretario, tesorero, vocal 1, vocal 2, vocal 3 y fiscal.

### church_service_times

Responsabilidad:

- Registrar horarios fijos de cultos o reuniones.

Campos sugeridos:

- `id`
- `church_id`
- `name`
- `day_of_week`
- `starts_at`
- `ends_at`
- `location`
- `active`
- `created_at`
- `updated_at`

Notas:

- Estos horarios pueden mostrarse en la página pública de la iglesia.
- También pueden servir para crear eventos recurrentes.

### events

Responsabilidad:

- Registrar eventos, actividades, cultos y reuniones.

Campos sugeridos:

- `id`
- `church_id`
- `ministry_id`
- `responsible_member_id`
- `title`
- `description`
- `event_type`
- `location`
- `starts_at`
- `ends_at`
- `visibility`
- `status`
- `recurring`
- `recurrence_frequency`
- `recurrence_until`
- `capacity`
- `food_expected`
- `created_at`
- `updated_at`

Valores sugeridos para `event_type`:

- `service`
- `ministry_meeting`
- `wedding`
- `baptism`
- `retreat`
- `special`
- `class`
- `other`

Valores sugeridos para `visibility`:

- `public`
- `members_only`
- `private`

Valores sugeridos para `status`:

- `scheduled`
- `cancelled`
- `completed`

Valores sugeridos para `recurrence_frequency`:

- `none`
- `daily`
- `weekly`
- `monthly`

Notas:

- `capacity` puede ayudar a eventos con cupo.
- `food_expected` puede ayudar a identificar eventos donde importa la cantidad de asistentes para comida.

### event_rsvps

Responsabilidad:

- Registrar confirmaciones de asistencia.

Campos sugeridos:

- `id`
- `church_id`
- `event_id`
- `member_id`
- `status`
- `guests_count`
- `notes`
- `created_at`
- `updated_at`

Valores sugeridos para `status`:

- `attending`
- `not_attending`
- `maybe`

### event_attendances

Responsabilidad:

- Registrar asistencia real a eventos.

Campos sugeridos:

- `id`
- `church_id`
- `event_id`
- `member_id`
- `attended`
- `checked_in_at`
- `checked_in_by_id`
- `notes`
- `created_at`
- `updated_at`

Notas:

- Puede usarse después para reportes de asistencia.

### occupations

Responsabilidad:

- Catálogo de ocupaciones por iglesia o global.

Campos sugeridos:

- `id`
- `church_id`
- `name`
- `description`
- `active`
- `created_at`
- `updated_at`

Notas:

- Para MVP, puede ser por iglesia para que cada iglesia administre sus términos.
- También se podría crear catálogo global futuro.
- La ocupación del miembro puede completarse después del registro inicial.

### member_occupations

Responsabilidad:

- Relacionar miembros con ocupación, trabajo y disponibilidad.

Campos sugeridos:

- `id`
- `church_id`
- `member_id`
- `occupation_id`
- `company_name`
- `job_title`
- `employment_status`
- `work_type`
- `looking_for_work`
- `offers_services`
- `available_for_projects`
- `years_of_experience`
- `professional_contact`
- `profile_url`
- `description`
- `current`
- `public_in_directory`
- `created_at`
- `updated_at`

Valores sugeridos para `employment_status`:

- `employed`
- `unemployed`
- `self_employed`
- `student`
- `retired`
- `homemaker`
- `looking_for_work`

Valores sugeridos para `work_type`:

- `full_time`
- `part_time`
- `freelance`
- `temporary`
- `volunteer`

### skills

Responsabilidad:

- Catálogo de habilidades por iglesia o global.

Campos sugeridos:

- `id`
- `church_id`
- `name`
- `description`
- `active`
- `created_at`
- `updated_at`

Notas:

- Las habilidades del miembro pueden completarse después del registro inicial.

### member_skills

Responsabilidad:

- Relacionar miembros con habilidades.

Campos sugeridos:

- `id`
- `church_id`
- `member_id`
- `skill_id`
- `level`
- `notes`
- `created_at`
- `updated_at`

Valores sugeridos para `level`:

- `basic`
- `intermediate`
- `advanced`
- `professional`

### profile_change_requests

Responsabilidad:

- Guardar cambios propuestos por miembros antes de aprobarlos.

Campos sugeridos:

- `id`
- `church_id`
- `member_id`
- `requested_by_id`
- `reviewed_by_id`
- `status`
- `changes_payload`
- `review_notes`
- `reviewed_at`
- `created_at`
- `updated_at`

Valores sugeridos para `status`:

- `pending`
- `approved`
- `rejected`

Notas:

- `changes_payload` puede ser JSONB.
- Al aprobar, se aplican cambios al miembro.

### pastoral_notes

Responsabilidad:

- Notas pastorales privadas.

Campos sugeridos:

- `id`
- `church_id`
- `member_id`
- `pastor_id`
- `title`
- `body`
- `note_type`
- `created_at`
- `updated_at`

Valores sugeridos para `note_type`:

- `general`
- `counseling`
- `follow_up`
- `prayer`

Regla:

- Solo usuarios con rol pastoral y permiso explícito de notas pastorales pueden ver estas notas.
- Un administrador sin rol pastoral no puede ver notas pastorales.

### contact_methods

Responsabilidad:

- Guardar métodos de contacto flexibles.

Campos sugeridos:

- `id`
- `church_id`
- `contactable_type`
- `contactable_id`
- `kind`
- `value`
- `label`
- `primary`
- `public`
- `created_at`
- `updated_at`

Valores sugeridos para `kind`:

- `phone`
- `whatsapp`
- `email`
- `facebook`
- `instagram`
- `youtube`
- `website`
- `other`

### plans

Responsabilidad:

- Tarifa comercial de la plataforma.

Campos sugeridos:

- `id`
- `name`
- `description`
- `price_cents`
- `currency`
- `active`
- `created_at`
- `updated_at`

Notas:

- Para MVP puede existir sin pagos automáticos.
- Será una tarifa única.
- El monto se define después.
- No tendrá límites iniciales por cantidad de miembros o usuarios.

### subscriptions

Responsabilidad:

- Relacionar iglesias con estado de suscripción o pago.

Campos sugeridos:

- `id`
- `church_id`
- `plan_id`
- `status`
- `starts_on`
- `ends_on`
- `trial_ends_on`
- `notes`
- `created_at`
- `updated_at`

Valores sugeridos para `status`:

- `trial`
- `active`
- `past_due`
- `cancelled`
- `suspended`

## 13. Relaciones Principales

```text
User has_many ChurchMemberships
User has_many Churches through ChurchMemberships
User has_many Members

Church has_many ChurchMemberships
Church has_many Users through ChurchMemberships
Church has_many Members
Church has_many Roles
Church has_many RolePermissions
Church has_many Ministries
Church has_many Boards
Church has_many Events
Church has_many Families
Church has_many Subscriptions

ChurchMembership belongs_to Church
ChurchMembership belongs_to User
ChurchMembership has_many MembershipRoles

Role belongs_to Church
Role has_many MembershipRoles
Role has_many RolePermissions
Role has_many Permissions through RolePermissions

Permission has_many RolePermissions

MembershipRole belongs_to ChurchMembership
MembershipRole belongs_to Role

RolePermission belongs_to Role
RolePermission belongs_to Permission

Member belongs_to Church
Member belongs_to User optional
Member has_many MinistryMemberships
Member has_many Ministries through MinistryMemberships
Member has_many MemberOccupations
Member has_many Occupations through MemberOccupations
Member has_many MemberSkills
Member has_many Skills through MemberSkills
Member has_many PastoralNotes
Member has_many FamilyMembers
Member has_many Families through FamilyMembers

Ministry belongs_to Church
Ministry has_many MinistryMemberships
Ministry has_many Members through MinistryMemberships
Ministry has_many Events

Board belongs_to Church
Board has_many BoardMembers
Board has_many Members through BoardMembers

Event belongs_to Church
Event belongs_to Ministry optional
Event belongs_to ResponsibleMember optional
Event has_many EventRsvps
Event has_many EventAttendances

Family belongs_to Church
Family has_many FamilyMembers
Family has_many Members through FamilyMembers
```

## 14. Permisos Y Accesos

### Super Administrador

Puede:

- Ver todas las iglesias.
- Crear iglesias.
- Editar iglesias.
- Activar, suspender o cancelar iglesias.
- Crear administradores iniciales de iglesia.
- Ver estado de suscripciones.
- Asignar planes manualmente.
- Ver métricas generales de la plataforma.

No debería usar normalmente:

- Notas pastorales internas.
- Información sensible de miembros, salvo soporte técnico autorizado.

### Propietario O Administrador Inicial De Iglesia

Debe existir una forma segura de bootstrap para la primera persona que administra una iglesia.

Recomendación:

- El super administrador crea la iglesia.
- El super administrador asigna un propietario o administrador inicial.
- Ese propietario tiene acceso completo administrativo inicial a la iglesia para crear roles, configurar permisos y asignarlos.
- Este acceso inicial puede manejarse con un campo como `church_memberships.owner`.
- Después de crear roles, la iglesia puede operar principalmente con roles y permisos configurables.

Nota:

- Esto evita depender de roles predefinidos con permisos fijos.
- Es una excepción necesaria para que una iglesia nueva no quede sin acceso para configurar su propia seguridad.
- Este acceso completo administrativo no incluye notas pastorales, salvo que esa misma persona tenga un rol pastoral.

### Matriz De Permisos Por Rol

Cada iglesia tendrá una página separada para administrar roles y permisos.

Flujo esperado:

1. El propietario o usuario autorizado entra a `Roles y permisos`.
2. Crea un rol o selecciona uno existente.
3. La pantalla muestra los módulos/vistas disponibles.
4. Para cada módulo/vista, el administrador marca permisos.
5. Guarda la matriz de permisos del rol.
6. Asigna el rol a uno o varios usuarios.

Permisos por acción:

- Sin acceso.
- Leer/listar.
- Ver detalle.
- Crear.
- Editar.
- Activar.
- Desactivar.
- Exportar.
- Administrar.

Atajos de interfaz:

- Sin acceso.
- Solo lectura: activa leer/listar/ver detalle.
- Lectura y escritura: activa leer/listar/ver detalle, crear y editar.
- Acceso completo: activa leer/listar/ver detalle, crear, editar, activar y desactivar.

Notas:

- Aunque existan atajos, la pantalla debe mostrar checkboxes individuales por acción.
- Exportar y administrar deben manejarse como checkboxes separados cuando el módulo los soporte.

Alcances posibles:

- Solo propio.
- Solo ministerios asignados.
- Toda la iglesia.

Reglas:

- El nombre del rol no da permisos por sí mismo.
- Un rol puede tener permisos en varios módulos.
- Un usuario puede tener varios roles.
- Los permisos efectivos de un usuario son la suma de sus roles dentro de esa iglesia.
- Las vistas y botones deben ocultarse si el usuario no tiene permiso.
- El backend siempre debe validar permisos aunque la vista oculte botones.

### Roles Internos De Iglesia

Cada iglesia podrá crear roles como:

- Administrador.
- Pastor general.
- Pastor asistente.
- Líder de ministerio.
- Secretario.
- Tesorero.
- Miembro.
- Cualquier rol personalizado.

Pero esos nombres son solo etiquetas. Los permisos reales dependen de la matriz.

Ejemplos:

- Un rol `Pastor general` puede tener lectura de miembros y acceso a notas pastorales.
- Un rol `Líder de jóvenes` puede tener permisos de eventos y miembros solo del ministerio de jóvenes.
- Un rol `Secretario` puede tener permisos de lectura y exportación de miembros.
- Un rol `Miembro` puede tener acceso solo a su perfil, eventos y directorio autorizado.

### Módulos Iniciales Para La Matriz

Módulos/vistas sugeridas para permisos:

- Dashboard.
- Iglesias, solo plataforma.
- Configuración de iglesia.
- Usuarios.
- Roles y permisos.
- Miembros.
- Familias.
- Ministerios.
- Junta directiva.
- Eventos.
- Confirmaciones de asistencia.
- Registro de asistencia.
- Ocupaciones.
- Habilidades.
- Directorio de servicios.
- Solicitudes de cambio de perfil.
- Notas pastorales.
- Reportes.
- Exportaciones.

### Permisos Especiales

Algunas áreas deben tener reglas adicionales:

- Notas pastorales: solo roles pastorales con permiso explícito.
- Roles y permisos: solo propietario o roles con permiso `roles_permissions.can_manage`.
- Configuración de iglesia: solo propietario o roles autorizados.
- Exportaciones: permiso separado, porque puede exponer datos sensibles.
- Activar/desactivar registros: permiso separado de editar.
- Líderes de ministerio: usar alcance `assigned_ministry` para limitar datos.

## 15. Reglas De Seguridad Y Privacidad

Reglas generales:

- Todo acceso debe validarse en backend con políticas.
- Cada consulta importante debe filtrar por `church_id`.
- Ningún usuario de una iglesia puede acceder a datos de otra iglesia.
- El super administrador debe tener acceso controlado a funciones globales.
- Los datos sensibles no deben exponerse en páginas públicas.
- Los registros se desactivan en lugar de borrarse.
- Los cambios importantes deben auditarse.
- Las notas pastorales deben estar protegidas con reglas estrictas.
- Los permisos deben validarse por módulo, acción, alcance e iglesia.
- No se debe confiar en el nombre del rol para autorizar acciones.

Datos sensibles:

- Teléfono.
- Dirección.
- Fecha de nacimiento.
- Estado civil.
- Información familiar.
- Notas pastorales.
- Información laboral cuando el miembro no la marca pública.

Acceso a datos sensibles:

- Usuarios con permisos explícitos sobre el módulo correspondiente.
- Usuarios con alcance suficiente dentro de la iglesia.
- Líderes de ministerio, solo para miembros de sus ministerios y solo si el permiso lo permite.

## 16. Pantallas Principales

### Panel De Super Administrador

Debe mostrar:

- Iglesias registradas.
- Estado de cada iglesia.
- Plan de cada iglesia.
- Total de miembros por iglesia.
- Fecha de creación.
- Acciones rápidas: crear iglesia, suspender iglesia, editar iglesia.

### Configuración De Iglesia

Debe permitir:

- Editar nombre.
- Editar contacto.
- Subir logo.
- Definir colores.
- Definir horarios de cultos.
- Activar/desactivar página pública.
- Activar/desactivar directorio de servicios.
- Activar/desactivar contacto laboral entre miembros.

### Dashboard De Iglesia

Debe mostrar:

- Total de miembros activos.
- Próximos eventos.
- Cumpleaños próximos.
- Miembros nuevos por mes.
- Miembros por ministerio.
- Miembros buscando trabajo.
- Servicios ofrecidos por miembros.
- Solicitudes de cambio pendientes.
- Asistencia esperada a eventos próximos.

### Gestión De Miembros

Pantallas:

- Lista de miembros.
- Crear miembro.
- Editar miembro.
- Ver perfil.
- Activar/desactivar miembro.
- Buscar y filtrar.
- Exportar CSV/Excel.

Filtros:

- Estado.
- Ministerio.
- Rol.
- Ocupación.
- Habilidad.
- Busca trabajo.
- Ofrece servicios.
- Estado civil.
- Fecha de membresía.

### Perfil De Miembro

Debe mostrar:

- Datos personales.
- Datos de contacto.
- Dirección.
- Familia/hogar.
- Fecha de bautismo.
- Fecha de membresía oficial.
- Ministerios.
- Roles.
- Ocupación.
- Habilidades.
- Servicios ofrecidos.
- Estado laboral.
- Eventos confirmados.
- Notas pastorales solo para roles pastorales autorizados.

### Solicitudes De Cambio

Debe permitir:

- Ver cambios pendientes.
- Comparar valor actual contra valor solicitado.
- Aprobar cambios.
- Rechazar cambios.
- Registrar nota de revisión.

### Gestión De Usuarios

Pantallas:

- Lista de usuarios de iglesia.
- Crear usuario para miembro.
- Asignar usuario a miembro.
- Asignar roles.
- Activar/desactivar acceso.

### Roles Y Permisos

Pantallas:

- Lista de roles creados por la iglesia.
- Crear rol.
- Editar nombre y descripción de rol.
- Activar/desactivar rol.
- Matriz de permisos por rol.
- Asignación de roles a usuarios.
- Asignación de alcance por rol, como toda la iglesia o ministerios asignados.

La matriz debe mostrar:

- Módulos o vistas de la plataforma.
- Permisos por acción.
- Accesos rápidos: sin acceso, solo lectura, lectura/escritura, acceso completo.
- Estado actual de permisos.

Ejemplo de acciones por módulo:

- Leer/listar.
- Ver detalle.
- Crear.
- Editar.
- Activar.
- Desactivar.
- Exportar.
- Administrar.

### Ministerios

Pantallas:

- Lista de ministerios.
- Crear ministerio.
- Editar ministerio.
- Asignar líder.
- Asignar miembros.
- Ver eventos del ministerio.

### Junta Directiva

Pantallas:

- Lista de juntas.
- Crear junta.
- Editar junta.
- Ver junta actual.
- Ver juntas históricas.
- Campos para presidente, vicepresidente, secretario, tesorero, vocal 1, vocal 2, vocal 3 y fiscal.
- Selector de miembros activos de la iglesia para cada cargo.
- Asignar o cambiar miembros por cargo.

Reglas de interfaz:

- Cada selector debe buscar únicamente miembros de la iglesia actual.
- La junta no debe mostrar estos cargos como roles del sistema.
- La junta no debe asignar permisos automáticamente.

### Calendario Y Eventos

Pantallas:

- Calendario mensual.
- Lista de eventos.
- Crear evento.
- Editar evento.
- Crear evento recurrente.
- Ver detalle.
- Confirmar asistencia.
- Registrar asistencia.

Filtros:

- Tipo.
- Ministerio.
- Visibilidad.
- Fecha.
- Estado.

### Directorio De Servicios

Pantallas:

- Lista de servicios ofrecidos.
- Buscar por ocupación.
- Buscar por habilidad.
- Miembros buscando trabajo.
- Contactar miembro, si la iglesia lo permite.

### Reportes

Reportes iniciales:

- Miembros activos/inactivos.
- Cumpleaños.
- Miembros nuevos por mes.
- Miembros por ministerio.
- Miembros por ocupación.
- Miembros buscando trabajo.
- Miembros que ofrecen servicios.
- Eventos próximos.
- Confirmaciones de asistencia.
- Asistencia real por evento.

## 17. Navegación Sugerida

### Super Administrador

- Dashboard.
- Iglesias.
- Planes.
- Suscripciones.
- Usuarios globales.
- Configuración plataforma.

### Administrador De Iglesia

- Dashboard.
- Miembros.
- Usuarios.
- Roles y permisos.
- Ministerios.
- Junta directiva.
- Eventos.
- Directorio de servicios.
- Reportes.
- Solicitudes pendientes.
- Configuración.

### Rol Con Permisos Pastorales

- Dashboard.
- Miembros.
- Notas pastorales.
- Eventos.
- Reportes pastorales.

### Rol Con Permisos De Ministerio

- Dashboard.
- Mi ministerio.
- Miembros del ministerio.
- Eventos del ministerio.

### Miembro

- Mi perfil.
- Solicitudes de cambio.
- Eventos.
- Directorio de servicios.
- Iglesia.

## 18. Reportes Recomendados Para MVP

Reportes indispensables:

- Miembros activos e inactivos.
- Cumpleaños por mes.
- Miembros nuevos por mes.
- Miembros por ministerio.
- Miembros por ocupación.
- Miembros por habilidad.
- Miembros buscando trabajo.
- Miembros que ofrecen servicios.
- Eventos próximos.
- Confirmaciones de asistencia.
- Asistencia real por evento.

Exportaciones:

- CSV de miembros.
- Excel de miembros.
- CSV/Excel de ocupaciones y servicios.
- CSV/Excel de asistencia por evento.

## 19. Seeds Iniciales

Datos globales:

- Usuario super administrador.
- Planes iniciales.
- Catálogo global de módulos/vistas para permisos.

Datos al crear una iglesia:

- Administrador o propietario inicial.
- Ministerios base opcionales.
- Ocupaciones comunes.
- Habilidades comunes.

Roles sugeridos, no obligatorios:

- Administrador de iglesia.
- Pastor general.
- Líder de ministerio.
- Miembro.

Notas sobre roles:

- Estos roles pueden ofrecerse como plantillas opcionales.
- No deben asignarse automáticamente si la iglesia no los quiere.
- Si se crean desde plantilla, sus permisos deben poder revisarse y modificarse desde la matriz.
- La iglesia puede crear roles completamente personalizados desde cero.

Ministerios sugeridos:

- Alabanza.
- Jóvenes.
- Niños.
- Ujieres.
- Evangelismo.
- Intercesión.
- Escuela dominical.

Cargos definidos de junta administrativa:

- Presidente.
- Vicepresidente.
- Secretario.
- Tesorero.
- Vocal 1.
- Vocal 2.
- Vocal 3.
- Fiscal.

## 20. Validaciones Importantes

Multi-tenant:

- Todo registro operativo debe tener `church_id`.
- No se debe permitir asociar registros de iglesias diferentes.
- Un evento no puede pertenecer a un ministerio de otra iglesia.
- Un miembro no puede asignarse a ministerio de otra iglesia.
- Un rol de iglesia no puede asignarse a usuario fuera de esa iglesia.
- Un permiso de rol debe pertenecer a la misma iglesia que el rol.
- Un permiso no puede apuntar a un módulo inactivo.
- Un usuario no puede administrar roles/permisos si no tiene permiso explícito.
- Los permisos de notas pastorales solo pueden asignarse a roles marcados como pastorales.

Miembros:

- Nombre requerido.
- Apellido requerido.
- Segundo apellido requerido.
- Teléfono requerido.
- Email opcional.
- Fecha de nacimiento requerida.
- Género requerido.
- Estado civil requerido.
- Ocupación opcional al crear; puede completarse después.
- Habilidades opcionales al crear; pueden completarse después.
- Ministerio opcional; un miembro puede existir sin ministerio.
- Si el email existe, debe tener formato válido.
- Fechas no pueden ser futuras.

Usuarios:

- Email requerido.
- Email único global.
- Usuario activo para iniciar sesión.

Iglesias:

- Nombre requerido.
- Email requerido.
- Teléfono requerido.
- Slug único.

Eventos:

- Título requerido.
- Fecha/hora de inicio requerida.
- Fecha/hora final posterior a fecha/hora inicial.
- Responsable válido dentro de la misma iglesia.

Ministerios:

- Nombre requerido.
- Líder debe pertenecer a la misma iglesia.

Junta directiva:

- Periodo requerido.
- Miembros deben pertenecer a la misma iglesia.
- Miembros deben estar activos al asignarse a una junta activa.
- El cargo debe ser uno de los cargos definidos.
- No puede haber dos miembros ocupando el mismo cargo en la misma junta activa.
- El mismo miembro no debería ocupar más de un cargo en la misma junta, salvo decisión explícita de la iglesia.

## 21. Auditoría

Debe auditarse:

- Creación de iglesia.
- Cambio de estado de iglesia.
- Cambio de plan o suscripción.
- Creación/desactivación de usuarios.
- Asignación de roles.
- Creación, edición o desactivación de roles.
- Cambios en matriz de permisos.
- Cambios en datos de miembros.
- Aprobación/rechazo de cambios de perfil.
- Cambios en junta directiva.
- Cambios en notas pastorales.
- Exportación de datos sensibles.

Gema sugerida:

- `paper_trail`

## 22. Funcionalidades Futuras Confirmadas

- Finanzas: diezmos, ofrendas y gastos.
- Grupos familiares o células.
- Solicitudes de oración.
- Seguimiento pastoral o consejería.
- Subdominio por iglesia.
- Pagos automáticos.

No prioritario por ahora:

- Notificaciones por email o WhatsApp.
- Importación de miembros desde Excel.
- Documentos legales.
- Visitantes.

## 23. Etapas De Desarrollo

### Etapa 0 - Preparación

- Usar Rails 8.
- Usar Docker para desarrollo.
- Mantener `igle-org` como nombre comercial provisional.
- Usar Tailwind CSS y Tailwind UI Pro como base visual.
- Dejar la estrategia exacta de DigitalOcean para la etapa de despliegue.
- Definir monto de tarifa única más adelante con finanzas.

### Etapa 1 - Creación Del Proyecto

- Crear app Rails con PostgreSQL y Tailwind.
- Configurar Docker.
- Configurar base de datos.
- Configurar variables de entorno.
- Configurar layout base.
- Configurar testing.
- Configurar RuboCop y Brakeman.

### Etapa 2 - Autenticación Global

- Instalar Devise.
- Crear `User`.
- Crear login/logout.
- Crear super administrador inicial.
- Proteger rutas privadas.

### Etapa 3 - Multi-Tenancy

- Crear `Church`.
- Crear `ChurchMembership`.
- Resolver iglesia actual.
- Aislar consultas por iglesia.
- Crear políticas base.
- Crear base del panel de super administrador.

### Etapa 4 - Creación Y Configuración De Iglesias

- Super admin crea iglesia.
- Super admin asigna administrador principal.
- Super admin edita datos básicos de iglesia.
- Super admin activa o desactiva iglesia.
- Crear configuración inicial.
- Crear acceso de propietario/administrador inicial.
- Crear tarifa/suscripción manual.
- Subir logo.
- Configurar colores y contactos.

Estado actual:

- Implementado: crear, listar, editar, activar/desactivar iglesias y asignar propietario inicial.
- Pendiente: configuración visual avanzada, logo y suscripción manual.

### Etapa 5 - Roles Y Permisos

- Crear catálogo global de módulos/vistas.
- Crear roles por iglesia.
- Crear matriz de permisos por rol.
- Crear asignación de roles a usuarios.
- Crear permisos por acción: leer, crear, editar, activar, desactivar, exportar y administrar.
- Crear alcances de permisos: propio, ministerios asignados y toda la iglesia.
- Implementar servicio `PermissionChecker`.
- Conectar Pundit con permisos dinámicos.
- Crear plantillas opcionales de roles, sin obligarlas.

### Etapa 6 - Miembros

- Crear `Member`.
- Crear CRUD de miembros.
- Asociar miembro con usuario.
- Crear perfil de miembro.
- Activar/desactivar miembros.
- Agregar dirección.
- Agregar datos de bautismo y membresía.

### Etapa 7 - Solicitudes De Cambio

- Permitir que miembro edite perfil mediante solicitud.
- Crear revisión de cambios.
- Aprobar/rechazar cambios.
- Auditar aprobación.

### Etapa 8 - Familias

- Crear familias/hogares.
- Relacionar miembros.
- Definir relaciones familiares.

### Etapa 9 - Ministerios

- Crear ministerios.
- Asignar líderes.
- Asignar miembros.
- Limitar permisos de líderes a su ministerio.

### Etapa 10 - Junta Directiva

- Crear juntas.
- Crear cargos definidos en el sistema: presidente, vicepresidente, secretario, tesorero, vocal 1, vocal 2, vocal 3 y fiscal.
- Asignar miembros activos de la iglesia a cada cargo.
- Validar que los cargos no funcionan como roles ni permisos.
- Guardar historial.
- Activar/desactivar junta.

### Etapa 11 - Eventos Y Calendario

- Crear eventos.
- Crear eventos recurrentes simples.
- Crear calendario/lista.
- Permitir visibilidad pública, privada y miembros.
- Permitir confirmación de asistencia.
- Registrar asistencia real.

### Etapa 12 - Ocupaciones, Habilidades Y Directorio

- Crear ocupaciones.
- Crear habilidades.
- Relacionar miembros.
- Registrar búsqueda de trabajo.
- Registrar servicios ofrecidos.
- Crear directorio de servicios.
- Respetar configuración de contacto entre miembros.

### Etapa 13 - Notas Pastorales

- Crear notas pastorales.
- Limitar acceso solo a roles con permiso explícito.
- Auditar cambios importantes.

### Etapa 14 - Reportes Y Exportaciones

- Crear reportes de miembros.
- Crear reportes de cumpleaños.
- Crear reportes de ministerios.
- Crear reportes laborales.
- Crear reportes de eventos y asistencia.
- Exportar CSV/Excel.

### Etapa 15 - Calidad Y Seguridad

- Agregar pruebas de modelos.
- Agregar pruebas de políticas.
- Agregar pruebas de sistema.
- Ejecutar RuboCop.
- Ejecutar Brakeman.
- Revisar aislamiento multi-tenant.
- Revisar permisos de datos sensibles.

### Etapa 16 - Producción En DigitalOcean

- Configurar servidor o App Platform.
- Configurar PostgreSQL.
- Configurar variables de entorno.
- Configurar Active Storage.
- Configurar dominio.
- Configurar SSL.
- Configurar backups.
- Crear usuario super administrador real.

## 24. Testing Recomendado

Pruebas de plataforma:

- Super admin puede crear iglesia.
- Super admin puede suspender iglesia.
- Super admin puede asignar administrador.
- Administrador de iglesia no puede ver otra iglesia.

Pruebas de multi-tenancy:

- Miembro de Iglesia A no aparece en Iglesia B.
- Evento de Iglesia A no aparece en Iglesia B.
- Ministerio de Iglesia A no puede asignarse a miembro de Iglesia B.
- Rol de Iglesia A no puede asignarse a usuario de Iglesia B sin relación.

Pruebas de permisos:

- Un rol sin permisos no puede acceder a módulos privados.
- Un rol con solo lectura no puede crear, editar, activar ni desactivar.
- Un rol con lectura y escritura puede crear y editar, pero no necesariamente desactivar.
- Un rol con permiso de activar/desactivar puede cambiar estado de registros.
- Un rol con permiso de exportar puede descargar reportes autorizados.
- Un usuario con varios roles recibe permisos combinados dentro de la misma iglesia.
- Un rol con alcance `assigned_ministry` solo administra ministerios asignados.
- Solo roles pastorales con permiso de notas pastorales pueden ver notas pastorales.
- Solo roles con permiso de administrar roles pueden cambiar la matriz de permisos.

Pruebas funcionales:

- Crear miembro.
- Crear usuario para miembro.
- Solicitar cambio de perfil.
- Aprobar cambio de perfil.
- Crear ministerio.
- Asignar líder de ministerio.
- Crear evento recurrente.
- Confirmar asistencia.
- Registrar asistencia.
- Crear servicio ofrecido.
- Buscar por ocupación.
- Exportar miembros.

## 25. Diseño De Interfaz

La interfaz debe ser clara, ordenada y fácil de usar.

Prioridades:

- Español como idioma principal.
- Diseño responsive.
- Buen uso en computadora, teléfono y tablet.
- Formularios simples.
- Tablas con búsqueda y filtros.
- Navegación separada por rol.
- Dashboards claros.
- Acciones importantes con confirmación.
- No saturar pantallas con información sensible innecesaria.

Estilo sugerido:

- Profesional.
- Limpio.
- Con buena legibilidad.
- Colores configurables por iglesia.
- Componentes consistentes.

## 26. Página Pública De Iglesia

Cada iglesia podrá tener una página pública básica.

Para el MVP debe mostrar:

- Nombre.
- Logo.
- Detalles generales básicos definidos por la iglesia.

Después del MVP puede mostrar:

- Dirección.
- Teléfono.
- Email institucional.
- Horarios de cultos.
- Descripción.
- Eventos públicos.
- Redes sociales.

No debe mostrar:

- Datos privados de miembros.
- Directorio interno.
- Notas.
- Reportes.

## 27. Tarifa Y Pagos

La plataforma tendrá una tarifa única para iglesias.

Para MVP:

- El super administrador crea iglesias manualmente.
- El monto de la tarifa se define después.
- El sistema guarda estado de suscripción.
- No habrá límites iniciales por cantidad de miembros o usuarios.
- No se integra pasarela de pago inicialmente.

Futuro:

- Integración con pasarela de pago.
- Facturación automática.
- Suspensión automática por falta de pago.

## 28. Backups Y Mantenimiento

En producción:

- Backups automáticos diarios de PostgreSQL.
- Backups antes de cambios grandes.
- Monitoreo de errores.
- Revisión periódica de dependencias.
- Actualización controlada de gems.
- Usuario super administrador secundario para emergencia.
- Logs de actividad crítica.

## 29. Deployment Sugerido

Destino confirmado:

- DigitalOcean.

Opciones:

- DigitalOcean App Platform.
- Droplet con Kamal.
- Droplet con Docker.

Elementos necesarios:

- App Rails.
- PostgreSQL administrado o PostgreSQL en servidor.
- Variables de entorno.
- Dominio.
- SSL.
- Backups.
- Logs.
- Almacenamiento para logos/fotos.

## 30. Checklist General

### Plataforma

- [x] Crear app Rails.
- [x] Configurar PostgreSQL.
- [x] Configurar Tailwind.
- [x] Configurar Docker.
- [x] Configurar autenticación.
- [x] Crear super administrador.
- [x] Crear panel de plataforma.
- [x] Crear iglesias.
- [ ] Configurar tarifa única.
- [ ] Crear suscripciones manuales.

### Multi-Iglesia

- [x] Crear `churches`.
- [x] Crear `church_memberships`.
- [x] Agregar `public_id` UUID a todo modelo de dominio.
- [x] Resolver iglesia actual.
- [x] Aislar consultas por `church_id`.
- [x] Probar que iglesias no comparten datos.

### Iglesia

- [ ] Configuración de iglesia.
- [ ] Logo.
- [ ] Colores.
- [ ] Contactos.
- [ ] Horarios de cultos.
- [ ] Página pública.

### Usuarios Y Roles

- [x] Propietario/administrador inicial de iglesia.
- [ ] Catálogo de módulos/vistas.
- [ ] Roles personalizados por iglesia.
- [ ] Matriz de permisos por rol.
- [ ] Permisos por acción.
- [ ] Alcances de permiso.
- [ ] Asignación de roles a usuarios.
- [ ] Plantillas opcionales de roles.

### Miembros

- [ ] CRUD de miembros.
- [ ] Perfil de miembro.
- [ ] Dirección.
- [ ] Familia/hogar.
- [ ] Bautismo.
- [ ] Membresía oficial.
- [ ] Activar/desactivar.
- [ ] Solicitudes de cambio.

### Ministerios

- [ ] CRUD de ministerios.
- [ ] Asignar líderes.
- [ ] Asignar miembros.
- [ ] Eventos por ministerio.

### Junta Directiva

- [ ] Juntas opcionales.
- [ ] Cargos definidos.
- [ ] Miembros de junta.
- [ ] Selectores desde miembros activos de la iglesia.
- [ ] Validar que junta no asigna roles.
- [ ] Historial.

### Eventos

- [ ] CRUD de eventos.
- [ ] Eventos recurrentes.
- [ ] Calendario.
- [ ] Confirmación de asistencia.
- [ ] Registro de asistencia.

### Trabajo Y Servicios

- [ ] Ocupaciones.
- [ ] Habilidades.
- [ ] Busca trabajo.
- [ ] Ofrece servicios.
- [ ] Directorio de servicios.
- [ ] Configuración de contacto entre miembros.

### Seguridad

- [ ] Pundit.
- [ ] Servicio de permisos dinámicos.
- [ ] Auditoría.
- [ ] Protección de notas pastorales.
- [ ] Protección de datos sensibles.
- [ ] Desactivar en vez de borrar.

### Reportes

- [ ] Miembros.
- [ ] Cumpleaños.
- [ ] Nuevos por mes.
- [ ] Ministerios.
- [ ] Ocupaciones.
- [ ] Servicios.
- [ ] Eventos.
- [ ] Asistencia.
- [ ] Exportación CSV/Excel.

### Producción

- [ ] DigitalOcean.
- [ ] PostgreSQL.
- [ ] Dominio.
- [ ] SSL.
- [ ] Backups.
- [ ] Logs.
- [ ] Storage.

## 31. Orden Recomendado Para Empezar

1. Crear proyecto Rails.
2. Configurar Devise.
3. Crear super administrador.
4. Crear `Church`.
5. Crear `ChurchMembership`.
6. Implementar aislamiento multi-tenant.
7. Crear panel de plataforma.
8. Crear catálogo de módulos/vistas.
9. Crear roles y matriz de permisos.
10. Crear asignación de roles a usuarios.
11. Crear configuración avanzada de iglesia.
12. Crear miembros.
13. Crear ministerios.
14. Crear eventos.
15. Crear solicitudes de cambio.
16. Crear ocupaciones, habilidades y directorio.
17. Crear junta directiva.
18. Crear página pública básica.
19. Crear reportes.
20. Crear notas pastorales.
21. Agregar pruebas.
22. Preparar DigitalOcean.

## 32. Primera Versión Recomendada

Primera versión funcional:

- Super administrador.
- Crear iglesias.
- Administrador por iglesia.
- Login.
- Roles personalizados.
- Matriz de permisos por rol.
- Permisos por módulo/vista y acción.
- Configuración de iglesia.
- Miembros oficiales.
- Perfil de miembro.
- Solicitudes de cambio.
- Página pública básica con nombre, logo y detalles generales.
- Ministerios.
- Líderes de ministerio.
- Eventos.
- Confirmación de asistencia.
- Ocupaciones y habilidades.
- Directorio de servicios.
- Reportes básicos.
- Exportación CSV/Excel.

Se puede dejar para una segunda versión:

- Subdominios.
- Pagos automáticos.
- Células/grupos familiares.
- Solicitudes de oración.
- Consejería avanzada.
- Notificaciones.
- Importación desde Excel.

## 33. Criterios De Éxito Del MVP

El MVP se considera útil cuando:

- El super administrador puede crear una iglesia.
- Cada iglesia puede operar sin ver datos de otras iglesias.
- Cada iglesia tiene su propio administrador.
- Un propietario o rol autorizado puede crear miembros.
- Un miembro puede iniciar sesión.
- Un miembro puede solicitar cambios a su perfil.
- Un usuario con permiso puede aprobar cambios.
- Una iglesia puede crear ministerios.
- Un rol con alcance de ministerio puede administrar solo su ministerio.
- Una iglesia puede registrar eventos.
- Los miembros pueden confirmar asistencia.
- La iglesia puede registrar asistencia real.
- La iglesia puede saber en qué trabaja un miembro.
- La iglesia puede saber quién busca trabajo.
- La iglesia puede saber quién ofrece servicios.
- La iglesia puede generar reportes básicos.
- Las notas pastorales son visibles solo para roles pastorales autorizados.
- Los registros pueden activarse/desactivarse sin borrarse.
- Los botones y vistas respetan la matriz de permisos.
- El backend bloquea acciones sin permiso aunque alguien intente acceder manualmente.

## 34. Decisiones Cerradas Antes De Desarrollo

Estas decisiones ya quedaron definidas:

- Finanzas, diezmos, ofrendas y gastos serán funcionalidades futuras.
- El administrador inicial tendrá acceso completo administrativo.
- Las notas pastorales serán solo para pastores.
- Ocupaciones y habilidades se podrán completar después del registro inicial del miembro.
- Un miembro puede existir sin ministerio.
- El email del miembro será opcional.
- La página pública básica de cada iglesia estará en el MVP.
- La plataforma tendrá tarifa única; el monto se define después.
- No habrá límites iniciales por cantidad de miembros o usuarios.
- La matriz de permisos tendrá checkboxes por acción y atajos de lectura, escritura y acceso total.
- Los permisos de notas pastorales solo pueden asignarse a roles marcados como pastorales.
- Rails 8 será la versión objetivo.
- Docker se usará desde el desarrollo.
- DigitalOcean será el destino de producción, con estrategia exacta definida durante despliegue.
- El nombre comercial provisional será `igle-org`.
- Tailwind CSS y Tailwind UI Pro serán la base visual.

## 35. Notas Finales

La decisión más importante del proyecto es diseñar todo desde el inicio como multi-iglesia.

La estructura debe proteger muy bien el aislamiento por iglesia. Casi todas las tablas operativas deben tener `church_id`, y las políticas de autorización deben validar la iglesia actual, los roles asignados, la matriz de permisos, la acción solicitada y el alcance permitido.

El proyecto debe crecer por etapas, pero la base de datos inicial debe quedar preparada para usuarios globales, iglesias independientes, roles personalizables por iglesia, permisos por módulo/vista, permisos por acción, permisos por ministerio, auditoría, reportes y planes futuros.
