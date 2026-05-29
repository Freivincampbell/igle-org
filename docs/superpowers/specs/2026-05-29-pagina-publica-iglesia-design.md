# Diseño: Página Pública de Iglesia (MVP)

Fecha: 2026-05-29. Base: `develop`.

## Contexto

La sección 26 de `general planification.md` define una página pública básica por
iglesia. El panel de administración **ya permite** configurar todo lo necesario
(slug, descripción, colores, logo y el toggle `public_page_enabled` en
`ChurchAdmin::SettingsController`). Lo único que falta es la página pública en
sí: un controlador `Public::`, su ruta y su vista.

Decisiones de alcance (acordadas):
- **URL**: `/c/:slug` (prefijo dedicado, sin colisión con rutas existentes).
- **Contenido MVP**: nombre, logo, descripción, colores de marca y horarios de
  culto activos. (Teléfono/dirección/email/eventos/redes quedan POST-MVP.)
- Subdominios por iglesia: fuera de alcance.

## Arquitectura

### Ruta
```ruby
get "/c/:slug", to: "public/churches#show", as: :public_church
```
El slug no es UUID; es el identificador público amigable ya validado en el
modelo (`/\A[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?\z/`, único, indexado).

### `Public::BaseController < ApplicationController`
- **No** exige `authenticate_user!` (página pública).
- Exime los guards de Pundit añadidos en Etapa 15 (no usa Pundit):
  `skip_after_action :verify_authorized` y `skip_after_action :verify_policy_scoped`.
- Usa `layout "public"` (layout propio sin la navegación de admin, que asume
  `current_user`).

### `Public::ChurchesController#show`
1. `@church = Church.find_by(slug: params[:slug].to_s.downcase)`.
2. Aplica reglas de visibilidad (abajo); si no cumplen → 404.
3. `@service_times = @church.church_service_times.active.ordered`.

### Layout `app/views/layouts/public.html.erb`
Minimalista: sin barra de navegación de admin, sin email de usuario, sin enlaces
internos. Solo `yield` + estructura básica + estilos Tailwind.

## Reglas de visibilidad (404 estricto)

La página se muestra **solo si las tres** se cumplen:
1. Existe una iglesia con ese `slug`.
2. `church.public_page_enabled == true`.
3. `church.active?`.

Si cualquiera falla → **404 Not Found** (`raise ActiveRecord::RecordNotFound`).
No redirige ni revela información: no se filtra la existencia de iglesias con la
página deshabilitada o suspendidas.

Se añade un scope de modelo para encapsular la regla y testearla aislada:
```ruby
# Church
scope :publicly_visible, -> { where(public_page_enabled: true, status: "active") }
```
El controlador usa `Church.publicly_visible.find_by(slug:)` y 404 si `nil`.

## Contenido de la vista (`public/churches/show.html.erb`)

Solo datos **no sensibles**:
- **Encabezado**: logo (si `logo.attached?`, con variante redimensionada) + `name`.
- **Branding**: `primary_color`/`secondary_color` como acentos vía estilos inline,
  con defaults seguros (ej. slate) si están en blanco.
- **Descripción**: `description` (si presente).
- **Horarios de culto**: lista de `@service_times` con **día (`day_name`), nombre,
  hora inicio–fin, lugar**. Se **excluye `notes`** (puede contener notas internas).

Degradación elegante: sin logo/descripción → solo nombre + horarios; sin horarios
activos → se omite esa sección.

### Prohibido explícitamente (privacidad)
Ningún dato de miembros, directorio interno, notas pastorales, reportes, ni
teléfono/dirección/email institucional (POST-MVP). El layout público no expone
`current_user` ni enlaces internos.

## Testing

### Request specs (`spec/requests/public/churches_spec.rb`)
- 200 y muestra nombre, descripción y horarios activos cuando
  `public_page_enabled` + `active`.
- **404** cuando: slug inexistente / `public_page_enabled = false` / iglesia `inactive`.
- **Privacidad**: la respuesta NO incluye datos de miembros, teléfono/email/
  dirección institucional, ni `notes` de horarios.
- **Aislamiento multi-tenant**: dos iglesias con slugs distintos; `/c/slug-a` no
  muestra datos de la iglesia B.
- **Sin auth**: accesible sin login (no redirige a `new_user_session_path`).
- Solo horarios `active` aparecen (uno inactivo no se muestra).

### Model spec (`spec/models/church_spec.rb`)
- `Church.publicly_visible` incluye solo iglesias con `public_page_enabled` y
  `active`; excluye deshabilitadas e inactivas.

## Lo que NO incluye (YAGNI / POST-MVP)
- Teléfono, dirección, email institucional, redes sociales, eventos públicos.
- Subdominios por iglesia.
- SEO avanzado, sitemap, Open Graph (se puede añadir luego).
- Caché/CDN de la página (no necesario para MVP).
