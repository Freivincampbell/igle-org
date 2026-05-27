# igle-org

Igle Org es una aplicacion web para la administracion de iglesias dentro de una plataforma multi-iglesia. La meta es que varias iglesias puedan usar el mismo sistema, pero que cada una mantenga sus datos completamente separados.

La guia funcional completa esta en [general planification.md](./general%20planification.md).

## Objetivo

Crear una plataforma que ayude a una iglesia a organizar miembros, usuarios, ministerios, junta administrativa, eventos, asistencia, ocupaciones, habilidades, directorio de servicios, reportes y permisos internos.

## Stack Actual

- Ruby 3.4.9.
- Ruby on Rails 8.1.3.
- PostgreSQL 16.
- Docker y Docker Compose para desarrollo.
- Tailwind CSS.
- Hotwire: Turbo y Stimulus.
- Devise para autenticacion.
- Pundit como base de autorizacion.
- Capa propia de permisos dinamicos por rol, modulo y accion.
- Active Storage para logos y fotos.
- Solid Queue, Solid Cache y Solid Cable.
- RSpec, FactoryBot y Faker para pruebas.
- Brakeman y Bundler Audit para auditoria de seguridad.
- DigitalOcean como destino futuro de produccion.

## Modelo General

- La plataforma sera multi-iglesia.
- Cada iglesia sera independiente.
- Solo el super administrador podra crear iglesias.
- Cada iglesia tendra un administrador inicial con acceso completo administrativo.
- Un usuario global puede pertenecer a una o varias iglesias.
- Los datos principales se aislaran por `church_id`.
- Todas las tablas de dominio usan `public_id` tipo UUID para URLs, APIs y referencias externas.
- El `id` interno de base de datos no debe exponerse fuera del backend.
- Ejemplo: `/churches/9d5f2f44-1b0c-4b8f-9d6b-8f1f0d7e3c21`.

## Funcionalidades Del MVP

- Super administrador de plataforma.
- Registro y administracion de iglesias.
- Usuarios por iglesia.
- Miembros oficiales.
- Roles personalizados por iglesia.
- Matriz de permisos por rol.
- Ministerios.
- Junta administrativa opcional.
- Eventos y calendario.
- Confirmacion y registro de asistencia.
- Ocupaciones, habilidades y directorio de servicios.
- Solicitudes de cambio de perfil.
- Reportes y exportaciones.
- Pagina publica basica por iglesia.

## Roles Y Permisos

Cada iglesia podra crear sus propios roles. Los roles no tendran permisos fijos por nombre.

La matriz de permisos usara checkboxes por accion:

- Leer.
- Crear.
- Editar.
- Activar.
- Desactivar.
- Exportar.
- Administrar.

Tambien tendra atajos:

- Solo lectura.
- Lectura y escritura.
- Acceso completo.

Las notas pastorales seran visibles solo para roles pastorales autorizados.

## Junta Administrativa

La junta administrativa no es un rol y no otorga permisos automaticamente.

Los cargos definidos son:

- Presidente.
- Vicepresidente.
- Secretario.
- Tesorero.
- Vocal 1.
- Vocal 2.
- Vocal 3.
- Fiscal.

Cada cargo se asignara seleccionando un miembro activo de la iglesia.

## Dependencias Necesarias

### Para correr con Docker

Este es el camino recomendado para desarrollo porque levanta Rails y PostgreSQL en contenedores.

- Docker Desktop o Docker Engine.
- Docker Compose.
- Git.

No es necesario instalar PostgreSQL local si se usa Docker.

### Para correr local sin Docker

En macOS, se recomienda usar Homebrew y `mise`:

```sh
brew install mise postgresql@16 libpq libvips pkg-config
mise install
```

El proyecto usa `.ruby-version` y `mise.toml` para fijar Ruby 3.4.9.

Tambien se necesita instalar las gems:

```sh
bundle install
```

Si usas PostgreSQL local con Homebrew:

```sh
brew services start postgresql@16
```

Si tu PostgreSQL local usa usuario y password especificos, define estas variables antes de correr Rails:

```sh
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export POSTGRES_USER=postgres
```

Si tu PostgreSQL local requiere password, tambien define `POSTGRES_PASSWORD` en tu shell con el valor local correspondiente. Si acepta conexiones con el usuario de tu sistema, puedes dejar esas variables vacias.

Nota: `.env.example` esta orientado al entorno Docker porque usa `DATABASE_HOST=db`. Para ejecucion nativa local, usa `localhost` o deja la variable sin definir.

## Correr El Proyecto Con Docker

Opcionalmente, crea el archivo local de variables de entorno si quieres cambiar los defaults de Docker:

```sh
cp .env.example .env
```

El archivo `.env` esta ignorado por Git y no debe commitearse. En desarrollo con Docker, PostgreSQL usa `POSTGRES_HOST_AUTH_METHOD=trust` dentro de la red local de contenedores para evitar guardar passwords de desarrollo en el repo.

Levantar la aplicacion:

```sh
docker compose up -d --build
```

El servicio `web` ejecuta automaticamente:

- `bundle check || bundle install`.
- `bin/rails db:prepare`.
- `bin/rails tailwindcss:build`.
- `bin/rails server -b 0.0.0.0`.

Verificar contenedores:

```sh
docker compose ps
```

Abrir la app:

- http://localhost:3000

Health check:

```sh
curl http://localhost:3000/up
```

Ver logs:

```sh
docker compose logs -f web
```

Detener contenedores:

```sh
docker compose down
```

Detener y borrar volumenes de desarrollo:

```sh
docker compose down -v
```

## Seeds Y Manual Testing

Los seeds preparan los datos base que necesita la plataforma para probarla manualmente:

- Catalogo global de permisos.
- Super administrador inicial, si existen las variables `SEED_SUPER_ADMIN_*`.

### 1. Preparar Variables Locales

Crea tu archivo local si aun no existe:

```sh
cp .env.example .env
```

Edita `.env` y define una clave local para el super administrador:

```sh
SEED_SUPER_ADMIN_EMAIL=admin@igle-org.local
SEED_SUPER_ADMIN_FIRST_NAME=Super
SEED_SUPER_ADMIN_LAST_NAME=Admin
SEED_SUPER_ADMIN_PASSWORD=
```

Rellena `SEED_SUPER_ADMIN_PASSWORD` solo en tu `.env` local. El archivo `.env` esta ignorado por Git.

### 2. Levantar La App

```sh
docker compose up -d --build
```

Confirma que los servicios esten arriba:

```sh
docker compose ps
curl http://localhost:3000/up
```

### 3. Preparar Base De Datos

Este comando crea la base, corre migraciones y carga el schema cuando haga falta:

```sh
docker compose exec -T web bin/rails db:prepare
```

### 4. Correr Seeds

```sh
docker compose exec -T web bin/rails db:seed
```

Resultado esperado:

```txt
Seeded super admin: admin@igle-org.local
```

Si ves este mensaje:

```txt
Skipped super admin seed. Set SEED_SUPER_ADMIN_EMAIL and SEED_SUPER_ADMIN_PASSWORD to create it.
```

revisa que `.env` tenga `SEED_SUPER_ADMIN_EMAIL` y `SEED_SUPER_ADMIN_PASSWORD`, y luego reinicia el servicio web para que Docker cargue las variables:

```sh
docker compose restart web
docker compose exec -T web bin/rails db:seed
```

### 5. Reset Completo De Desarrollo

Usa esto solo si quieres borrar toda la data local y empezar de cero:

```sh
docker compose down -v
docker compose up -d --build
docker compose exec -T web bin/rails db:seed
```

### 6. Probar Como Super Administrador

Abre:

- http://localhost:3000/users/sign_in

Inicia sesion con:

- Email: valor de `SEED_SUPER_ADMIN_EMAIL`.
- Clave: valor de `SEED_SUPER_ADMIN_PASSWORD`.

Luego abre:

- http://localhost:3000/platform

Flujo manual recomendado:

1. Crear una iglesia desde `Nueva iglesia`.
2. Confirmar que la URL use UUID, por ejemplo `/platform/churches/9d5f2f44-1b0c-4b8f-9d6b-8f1f0d7e3c21`, nunca `/platform/churches/1`.
3. Editar datos basicos de la iglesia.
4. Desactivar la iglesia y volver a activarla.
5. Entrar a `Asignar admin`.
6. Crear el administrador owner inicial de esa iglesia.
7. Confirmar que el owner aparezca en el detalle de la iglesia.

### 7. Probar Como Administrador Owner De Iglesia

Despues de asignar el owner:

1. Cierra la sesion actual o usa una ventana privada del navegador.
2. Entra a http://localhost:3000/users/sign_in.
3. Inicia sesion con el email y la clave inicial del owner.
4. Abre http://localhost:3000/churches.
5. Confirma que el usuario solo vea las iglesias donde tiene membresia activa.

### 8. Probar Roles Y Permisos

Desde el detalle de una iglesia, entra a:

- `/churches/:church_uuid/admin/roles`

Flujo manual recomendado:

1. Crear un rol desde `Nuevo rol`.
2. Entrar a `Editar`.
3. Marcar permisos en la matriz por modulo y accion.
4. Usar los atajos `Sin acceso`, `Lectura`, `Escritura` o `Total` para probar que los checkboxes cambien correctamente.
5. Guardar permisos.
6. Confirmar en el detalle del rol que aparezcan los permisos asignados.
7. Desactivar el rol y volver a activarlo.

Para probar permisos pastorales:

1. Crear o editar un rol y marcar `Rol pastoral`.
2. Guardar el rol.
3. Entrar a `Editar`.
4. Asignar permisos del modulo `Notas pastorales`.

Los permisos de `Notas pastorales` no se guardan en roles no pastorales.

### 9. Probar Asignacion De Roles A Usuarios

Desde el detalle de una iglesia, entra a:

- `/churches/:church_uuid/admin/memberships`

Flujo manual recomendado:

1. Seleccionar `Editar roles` en un usuario de iglesia.
2. Marcar uno o varios roles activos.
3. Guardar.
4. Confirmar que los roles aparezcan en la lista de usuarios.

Mientras no exista la pantalla completa de creacion de usuarios por iglesia, puedes crear un usuario de prueba desde consola:

```sh
docker compose exec -T web bin/rails runner '
church = Church.find_by!(public_id: "<church_uuid>")
temporary_access = SecureRandom.base58(20)
user = User.find_or_initialize_by(email: "tester@example.local")
user.assign_attributes(
  first_name: "Tester",
  last_name: "Manual",
  status: "active",
  platform_role: "user",
  password: temporary_access,
  password_confirmation: temporary_access
)
user.save!
ChurchMembership.find_or_create_by!(church:, user:) { |membership| membership.status = "active" }
puts "Usuario listo: #{user.email}"
puts "Clave temporal: #{temporary_access}"
'
```

Luego asigna roles a ese usuario desde `/churches/:church_uuid/admin/memberships`.

### 10. Smoke Tests Rapidos

```sh
curl -s -o /dev/null -w 'root:%{http_code}\n' http://localhost:3000
curl -s -o /dev/null -w 'up:%{http_code}\n' http://localhost:3000/up
curl -s -o /dev/null -w 'login:%{http_code}\n' http://localhost:3000/users/sign_in
curl -s -o /dev/null -w 'platform:%{http_code}\n' http://localhost:3000/platform
```

Resultado esperado sin sesion:

- `root:200`.
- `up:200`.
- `login:200`.
- `platform:302`, porque redirige al login.

## Correr El Proyecto Local Sin Docker

Preparar base de datos:

```sh
bin/rails db:prepare
```

Levantar Rails y Tailwind:

```sh
bin/dev
```

Abrir la app:

- http://localhost:3000

Si solo quieres levantar Rails sin watcher de Tailwind:

```sh
bin/rails tailwindcss:build
bin/rails server
```

## Validaciones Recomendadas

Con Docker:

```sh
docker compose exec -T web bin/rails db:prepare
docker compose exec -T web bin/rails about
docker compose exec -T web bundle exec rspec
docker compose exec -T web bin/rails test
docker compose exec -T web bin/rubocop
docker compose exec -T web bin/brakeman --quiet
docker compose exec -T web bin/bundler-audit check --update
```

Local sin Docker:

```sh
bin/rails db:prepare
bin/rails about
bundle exec rspec
bin/rails test
bin/rubocop
bin/brakeman --quiet
bin/bundler-audit check --update
```

Tambien se puede validar la respuesta HTTP:

```sh
curl -s -o /dev/null -w 'root:%{http_code}\n' http://localhost:3000
curl -s -o /dev/null -w 'up:%{http_code}\n' http://localhost:3000/up
```

Resultado esperado:

- `root:200`.
- `up:200`.
- RSpec sin fallos.
- Rails tests sin fallos.
- RuboCop sin offenses.
- Brakeman sin warnings de seguridad.
- Bundler Audit sin vulnerabilidades.

## Base De Datos

La base de datos principal es PostgreSQL.

La fundacion multi-tenant usa:

- `users`: usuarios globales con Devise y rol de plataforma (`user` o `super_admin`).
- `churches`: iglesias/tenants.
- `church_memberships`: relacion entre usuario global e iglesia, con `owner` y `status`.
- `roles`: roles internos configurables por iglesia, con marca `pastoral` cuando aplica.
- `permissions`: catalogo global de modulo + accion.
- `role_permissions`: permisos asignados a cada rol.
- `membership_roles`: roles asignados a usuarios dentro de una iglesia.

Todas estas tablas tienen `public_id` UUID único. Las tablas internas de Rails, como `active_storage_*`, no se tratan como recursos del dominio y no deben exponerse directamente.

En desarrollo con Docker:

- Host interno: `db`.
- Puerto interno: `5432`.
- Usuario: `postgres`.
- Password: no requerido en Docker development.
- Base de datos: `igle_org_development`.

El puerto de PostgreSQL no se expone al host para evitar conflictos con otros servicios locales. Rails se conecta a la base de datos usando la red interna de Docker.

## Archivos Importantes

- [general planification.md](./general%20planification.md): plan funcional completo.
- [compose.yml](./compose.yml): servicios Docker de desarrollo.
- [Dockerfile.dev](./Dockerfile.dev): imagen de desarrollo.
- [Gemfile](./Gemfile): dependencias Ruby.
- [config/database.yml](./config/database.yml): configuracion de PostgreSQL.
- [Procfile.dev](./Procfile.dev): procesos de desarrollo local.

## Seguridad De Archivos

No se debe commitear informacion sensible.

Archivos que no deben subirse:

- `config/master.key`.
- `.env`.
- Logs, temporales y archivos generados localmente.

`config/credentials.yml.enc` si puede versionarse porque esta cifrado.

## Decisiones Cerradas

- Nombre provisional: `igle-org`.
- Rails 8 como version objetivo.
- Docker desde desarrollo.
- Tailwind CSS y Tailwind UI Pro como base visual.
- DigitalOcean para produccion.
- Tarifa unica para iglesias; el monto se definira despues.
- Sin limites iniciales por cantidad de miembros o usuarios.
- Email del miembro opcional.
- Ocupacion, habilidades y ministerio se pueden completar despues.
- Finanzas, diezmos, ofrendas y gastos quedan para una fase futura.

## Fuera Del MVP

- Subdominios por iglesia.
- Pagos automaticos.
- App movil nativa.
- Notificaciones por email o WhatsApp.
- Importacion desde Excel.
- Visitantes.
- Documentos legales.
- Finanzas completas.

## Siguiente Paso

Con la fundacion multi-tenant, el panel de plataforma y la administracion de roles/permisos creada, el siguiente paso es construir la base de miembros oficiales.

El panel de plataforma ya permite al super administrador:

- Listar iglesias.
- Crear iglesias.
- Editar datos basicos.
- Activar o desactivar iglesias.
- Asignar el administrador owner inicial de cada iglesia.

La administracion interna de iglesia ya permite al owner o usuario autorizado:

- Crear roles personalizados por iglesia.
- Editar datos del rol.
- Activar o desactivar roles.
- Asignar permisos por modulo y accion.
- Asignar roles a usuarios de la iglesia.
