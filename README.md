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
docker compose exec -T web bin/brakeman --quiet
docker compose exec -T web bin/bundler-audit check
```

Local sin Docker:

```sh
bin/rails db:prepare
bin/rails about
bundle exec rspec
bin/rails test
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
- Brakeman sin warnings de seguridad.
- Bundler Audit sin vulnerabilidades.

Nota: RuboCop queda pendiente de investigacion porque en este entorno se queda colgado al ejecutarse. Por ahora no se considera una validacion obligatoria.

## Base De Datos

La base de datos principal es PostgreSQL.

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

Con el setup base funcionando, el siguiente paso es crear el modelo multi-iglesia y la estructura inicial de usuarios, iglesias, membresias, roles y permisos.
