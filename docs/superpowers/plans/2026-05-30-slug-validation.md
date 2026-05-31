# Slug Validation Inline + Botón "Ver Perfil Público" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar validación inline del slug público (limpieza en tiempo real + check de disponibilidad via AJAX) y un botón "Ver perfil público" en el header de `church_admin/settings`.

**Architecture:** Un Stimulus controller (`slug-validator`) maneja la limpieza del input y el debounce. Hace un `fetch` a un nuevo endpoint `GET settings/check_slug` que responde JSON. La vista actualiza el badge de disponibilidad y el hint de URL en el DOM. El botón del header es un enlace estático que se activa solo si el slug ya está guardado y la página pública está habilitada.

**Tech Stack:** Rails 8, Stimulus (Hotwire), Tailwind CSS, RSpec (request spec + system spec).

---

## Mapa de archivos

| Archivo | Acción | Responsabilidad |
|---------|--------|----------------|
| `config/routes.rb` | Modificar línea 57 | Agregar `get :check_slug` al resource de settings |
| `app/controllers/church_admin/settings_controller.rb` | Modificar | Agregar acción `check_slug` que responde JSON |
| `app/javascript/controllers/slug_validator_controller.js` | Crear | Limpieza de input + debounce + fetch + actualizar badge/hint |
| `app/views/church_admin/settings/show.html.erb` | Modificar | Header con botón, slug field con data-attributes, badge y URL hint |
| `spec/requests/church_admin/settings_spec.rb` | Crear | Specs del endpoint check_slug |

---

## Task 1: Endpoint `check_slug` — ruta, controlador y specs

**Files:**
- Modify: `config/routes.rb:57`
- Modify: `app/controllers/church_admin/settings_controller.rb`
- Create: `spec/requests/church_admin/settings_spec.rb`

- [ ] **Paso 1: Escribir el spec que falla**

Crear `spec/requests/church_admin/settings_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Church admin settings" do
  describe "GET check_slug" do
    let(:church) { create(:church) }
    let(:membership) { create(:church_membership, :owner, church:) }

    before { sign_in membership.user }

    it "retorna disponible para un slug libre" do
      get check_slug_church_admin_settings_path(church),
          params: { slug: "iglesia-libre" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => true)
    end

    it "retorna disponible cuando el slug pertenece a la misma iglesia" do
      church.update!(slug: "mi-slug-actual")

      get check_slug_church_admin_settings_path(church),
          params: { slug: "mi-slug-actual" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => true)
    end

    it "retorna no disponible cuando el slug pertenece a otra iglesia" do
      create(:church, slug: "slug-tomado")

      get check_slug_church_admin_settings_path(church),
          params: { slug: "slug-tomado" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => false, "reason" => "taken")
    end

    it "retorna formato inválido para slug con espacios y mayúsculas" do
      get check_slug_church_admin_settings_path(church),
          params: { slug: "SLUG INVALIDO!" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => false, "reason" => "invalid_format")
    end

    it "retorna formato inválido para slug vacío" do
      get check_slug_church_admin_settings_path(church),
          params: { slug: "" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("available" => false, "reason" => "invalid_format")
    end

    it "requiere autenticación" do
      sign_out membership.user

      get check_slug_church_admin_settings_path(church),
          params: { slug: "cualquier-slug" },
          as: :json

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
```

- [ ] **Paso 2: Correr el spec y confirmar que falla por ruta inexistente**

```bash
bundle exec rspec spec/requests/church_admin/settings_spec.rb
```

Salida esperada: `NameError: undefined method 'check_slug_church_admin_settings_path'` o `ActionController::RoutingError`.

- [ ] **Paso 3: Agregar la ruta**

En `config/routes.rb`, línea 57, cambiar:

```ruby
resource :settings, only: %i[show update], controller: :settings
```

por:

```ruby
resource :settings, only: %i[show update], controller: :settings do
  get :check_slug
end
```

- [ ] **Paso 4: Correr el spec y confirmar que falla por acción faltante**

```bash
bundle exec rspec spec/requests/church_admin/settings_spec.rb
```

Salida esperada: `AbstractController::ActionNotFound: The action 'check_slug' could not be found`.

- [ ] **Paso 5: Agregar la acción en el controller**

En `app/controllers/church_admin/settings_controller.rb`, agregar después de `update` y antes de `private`:

```ruby
def check_slug
  authorize @church, :update?, policy_class: ChurchSettingPolicy

  slug = params[:slug].to_s.strip.downcase.presence

  unless slug&.match?(/\A[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?\z/)
    render json: { available: false, reason: "invalid_format" }
    return
  end

  taken = Church.where(slug:).where.not(id: @church.id).exists?

  if taken
    render json: { available: false, reason: "taken" }
  else
    render json: { available: true }
  end
end
```

- [ ] **Paso 6: Correr los specs y confirmar que todos pasan**

```bash
bundle exec rspec spec/requests/church_admin/settings_spec.rb
```

Salida esperada: `6 examples, 0 failures`.

- [ ] **Paso 7: Verificar que no rompiste rutas existentes**

```bash
bundle exec rspec spec/requests/
```

Salida esperada: sin failures nuevos.

- [ ] **Paso 8: Commit**

```bash
git add config/routes.rb app/controllers/church_admin/settings_controller.rb spec/requests/church_admin/settings_spec.rb
git commit -m "feat: endpoint check_slug para validación inline del slug público"
```

---

## Task 2: Stimulus controller `slug-validator`

**Files:**
- Create: `app/javascript/controllers/slug_validator_controller.js`

> El controller se auto-registra porque el proyecto usa `eagerLoadControllersFrom("controllers", application)` en `index.js`. No se necesita modificar `index.js`.

- [ ] **Paso 1: Crear el controller**

Crear `app/javascript/controllers/slug_validator_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

const SLUG_REGEX = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/

const BADGE_STATES = {
  checking: {
    text: "⟳ Verificando...",
    classes: "text-violet-700 bg-violet-50 border border-violet-200"
  },
  available: {
    text: "✓ Disponible",
    classes: "text-green-700 bg-green-50 border border-green-200"
  },
  taken: {
    text: "✗ Ya está en uso",
    classes: "text-red-700 bg-red-50 border border-red-200"
  },
  invalid: {
    text: "✗ Formato inválido",
    classes: "text-red-700 bg-red-50 border border-red-200"
  }
}

export default class extends Controller {
  static targets = ["input", "badge", "urlHint"]
  static values = { checkUrl: String, baseUrl: String }

  connect() {
    this.debounceTimer = null
    // Mostrar el URL hint si ya hay un slug guardado al cargar la página
    const current = this.inputTarget.value.trim()
    if (current) this.#updateUrlHint(current)
  }

  disconnect() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  sanitize() {
    const raw = this.inputTarget.value
    const clean = raw
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-+|-+$/g, "")

    if (this.inputTarget.value !== clean) {
      this.inputTarget.value = clean
    }

    this.#updateUrlHint(clean)

    if (!clean) {
      this.#hideBadge()
      return
    }

    this.#showBadge("checking")
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.#checkAvailability(clean), 500)
  }

  #updateUrlHint(slug) {
    if (!this.hasUrlHintTarget) return
    if (slug) {
      this.urlHintTarget.textContent = `🔗 ${this.baseUrlValue}/c/${slug}`
      this.urlHintTarget.classList.remove("hidden")
    } else {
      this.urlHintTarget.classList.add("hidden")
    }
  }

  #showBadge(state) {
    if (!this.hasBadgeTarget) return
    const { text, classes } = BADGE_STATES[state]
    const badge = this.badgeTarget
    badge.className = `text-xs font-medium rounded-full px-2 py-0.5 ${classes}`
    badge.textContent = text
    badge.classList.remove("hidden")
  }

  #hideBadge() {
    if (this.hasBadgeTarget) this.badgeTarget.classList.add("hidden")
  }

  async #checkAvailability(slug) {
    try {
      const url = new URL(this.checkUrlValue, window.location.origin)
      url.searchParams.set("slug", slug)
      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) { this.#hideBadge(); return }
      const data = await response.json()
      if (data.available) {
        this.#showBadge("available")
      } else {
        this.#showBadge(data.reason === "invalid_format" ? "invalid" : "taken")
      }
    } catch {
      this.#hideBadge()
    }
  }
}
```

- [ ] **Paso 2: Verificar que el archivo no tiene errores de sintaxis**

```bash
node --input-type=module < app/javascript/controllers/slug_validator_controller.js 2>&1 || echo "check syntax manually"
```

Si el comando no está disponible, continuar al siguiente paso — Rails compilará el JS y los errores aparecerán en consola del navegador.

- [ ] **Paso 3: Commit parcial**

```bash
git add app/javascript/controllers/slug_validator_controller.js
git commit -m "feat: Stimulus controller slug-validator con limpieza y check de disponibilidad"
```

---

## Task 3: Actualizar la vista settings/show.html.erb

**Files:**
- Modify: `app/views/church_admin/settings/show.html.erb`

- [ ] **Paso 1: Reemplazar el header de la página (líneas 1-6 actuales)**

Reemplazar:

```erb
<section class="mx-auto w-full max-w-4xl px-6 py-8">
  <div>
    <p class="text-xs font-semibold uppercase tracking-widest text-violet-500"><%= @church.name %></p>
    <h1 class="mt-1 text-2xl font-bold text-slate-900">Configuracion de iglesia</h1>
    <p class="mt-1 text-sm text-slate-600">Define la informacion publica, marca y opciones visibles de tu iglesia.</p>
  </div>
```

por:

```erb
<section class="mx-auto w-full max-w-4xl px-6 py-8">
  <div class="flex items-start justify-between gap-4">
    <div>
      <p class="text-xs font-semibold uppercase tracking-widest text-violet-500"><%= @church.name %></p>
      <h1 class="mt-1 text-2xl font-bold text-slate-900">Configuracion de iglesia</h1>
      <p class="mt-1 text-sm text-slate-600">Define la informacion publica, marca y opciones visibles de tu iglesia.</p>
    </div>
    <% if @church.slug.present? && @church.public_page_enabled? %>
      <%= link_to public_church_path(@church.slug),
            target: "_blank", rel: "noopener noreferrer",
            class: "mt-1 shrink-0 inline-flex items-center gap-2 rounded-lg border border-violet-200 bg-violet-50 px-4 py-2 text-sm font-semibold text-violet-700 hover:bg-violet-100 transition-colors" do %>
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
        </svg>
        Ver perfil publico
      <% end %>
    <% else %>
      <span class="mt-1 shrink-0 inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-4 py-2 text-sm font-semibold text-slate-400 cursor-not-allowed"
            title="<%= @church.slug.blank? ? 'Configura un slug para habilitar el perfil publico' : 'Habilita la pagina publica en Opciones para acceder' %>">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
        </svg>
        Ver perfil publico
      </span>
    <% end %>
  </div>
```

- [ ] **Paso 2: Reemplazar el campo slug (líneas 31-33 actuales)**

Reemplazar el `<div>` que contiene el campo slug:

```erb
        <div>
          <%= form.label :slug, "Slug publico", class: "block text-sm font-medium text-slate-700" %>
          <%= form.text_field :slug, placeholder: "mi-iglesia", class: "mt-1 w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-500/20" %>
        </div>
```

por:

```erb
        <div data-controller="slug-validator"
             data-slug-validator-check-url-value="<%= check_slug_church_admin_settings_path(@church) %>"
             data-slug-validator-base-url-value="<%= request.base_url %>">
          <div class="flex items-center justify-between mb-1">
            <%= form.label :slug, "Slug publico", class: "block text-sm font-medium text-slate-700" %>
            <span data-slug-validator-target="badge" class="hidden text-xs font-medium rounded-full px-2 py-0.5"></span>
          </div>
          <%= form.text_field :slug,
                placeholder: "mi-iglesia",
                data: {
                  slug_validator_target: "input",
                  action: "input->slug-validator#sanitize"
                },
                class: "w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-500/20" %>
          <p data-slug-validator-target="urlHint"
             class="mt-1 text-xs text-slate-500 <%= 'hidden' unless @church.slug.present? %>">
            🔗 <%= request.base_url %>/c/<%= @church.slug %>
          </p>
        </div>
```

- [ ] **Paso 3: Commit**

```bash
git add app/views/church_admin/settings/show.html.erb
git commit -m "feat: validación inline de slug y botón ver perfil publico en settings"
```

---

## Task 4: Verificación manual en el navegador

- [ ] **Paso 1: Levantar el servidor**

```bash
bin/dev
```

- [ ] **Paso 2: Ir a la pantalla de settings de una iglesia**

Navegar a `/churches/:public_id/admin/settings`.

- [ ] **Paso 3: Verificar limpieza en tiempo real**

Escribir `"Mi Iglesia 2024!"` en el campo Slug. El valor debe limpiarse a `"mi-iglesia-2024"` mientras se escribe. El hint debajo debe mostrar `🔗 localhost:3000/c/mi-iglesia-2024`.

- [ ] **Paso 4: Verificar badge "Verificando..."**

Mientras se escribe antes de los 500ms, debe aparecer el badge violeta `⟳ Verificando...`.

- [ ] **Paso 5: Verificar badge "Disponible"**

Esperar 500ms sin escribir. El badge debe cambiar a verde `✓ Disponible` si el slug está libre.

- [ ] **Paso 6: Verificar badge "Ya está en uso"**

Escribir el slug de una iglesia existente en la base de datos de desarrollo. El badge debe mostrar rojo `✗ Ya está en uso`.

- [ ] **Paso 7: Verificar badge "Formato inválido"**

Escribir un string que no pase la limpieza (el JS lo limpia, pero prueba escribiendo un solo guion `-`). El badge debe mostrar `✗ Formato inválido`.

- [ ] **Paso 8: Verificar botón "Ver perfil público"**

- Si la iglesia no tiene slug o tiene `public_page_enabled: false`: botón deshabilitado (gris, cursor no permitido) con tooltip.
- Guardar la configuración con un slug válido y `public_page_enabled: true`: el botón debe volverse violeta y abrir `/c/:slug` en nueva pestaña.

---

## Task 5: Rubocop y limpieza final

- [ ] **Paso 1: Correr rubocop**

```bash
bundle exec rubocop app/controllers/church_admin/settings_controller.rb
```

Salida esperada: `no offenses detected`. Si hay offenses, aplicar autocorrección:

```bash
bundle exec rubocop -a app/controllers/church_admin/settings_controller.rb
```

- [ ] **Paso 2: Correr suite de tests completa**

```bash
bundle exec rspec spec/requests/ spec/models/
```

Salida esperada: sin failures nuevos.

- [ ] **Paso 3: Commit final si hubo correcciones de rubocop**

```bash
git add app/controllers/church_admin/settings_controller.rb
git commit -m "style: rubocop fixes en settings_controller"
```
