# Slug Validation Inline + Botón "Ver Perfil Público"

**Fecha:** 2026-05-30  
**Área:** `ChurchAdmin::SettingsController`  
**Estado:** Aprobado

---

## Contexto

La pantalla `church_admin/settings` tiene un campo "Slug público" que determina la URL pública de la iglesia (`/c/:slug`). Actualmente el campo no limpia el input mientras el usuario escribe, no da feedback de disponibilidad hasta que se guarda el formulario, y no hay acceso rápido al perfil público desde esta pantalla.

El modelo `Church` ya tiene:
- `normalizes :slug` → downcase + strip al guardar
- `validates :slug, uniqueness: { case_sensitive: false }` con formato `/\A[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?\z/`

---

## Objetivos

1. Limpiar el slug en tiempo real mientras el usuario escribe
2. Mostrar disponibilidad del slug con feedback inline (sin esperar el submit)
3. Agregar un botón "Ver perfil público" en el header de la página

---

## Diseño

### 1. Limpieza en tiempo real

Un Stimulus controller `slug-validator` escucha el evento `input` del campo y transforma el valor:

- Convierte a minúsculas
- Reemplaza espacios y caracteres no alfanuméricos (excepto `-`) por `-`
- Colapsa guiones consecutivos en uno
- Elimina guiones al inicio y al final

El valor del campo se actualiza en vivo con el resultado limpio, de modo que el usuario ve exactamente lo que se guardará.

### 2. Badge de disponibilidad

Aparece junto al label del campo slug. Estados posibles:

| Estado | Apariencia | Condición |
|--------|-----------|-----------|
| Oculto | — | Campo vacío |
| Verificando | `⟳ Verificando...` (violeta) | Durante debounce (500ms) o request en vuelo |
| Disponible | `✓ Disponible` (verde) | Slug válido y no tomado por otra iglesia |
| Ya en uso | `✗ Ya está en uso` (rojo) | Slug tomado por otra iglesia |
| Formato inválido | `✗ Formato inválido` (rojo) | No pasa la regex del modelo |

### 3. Hint de URL

Debajo del input, siempre visible cuando el campo tiene contenido:

```
🔗 tuapp.com/c/iglesia-genesis
```

El dominio se inyecta vía `data-attribute` en el elemento desde el erb usando `request.base_url`, así funciona en desarrollo, staging y producción sin hardcodear URLs.

### 4. Botón "Ver perfil público"

Ubicado en el header de la página, alineado a la derecha del título. Comportamiento:

- **Activo:** cuando `@church.slug.present?` y `@church.public_page_enabled?` → abre `/c/:slug` en nueva pestaña
- **Deshabilitado:** si falta slug o la página pública está desactivada → botón con estilo opaco y `title` explicativo

### 5. Endpoint de verificación

```
GET /church_admin/:church_public_id/settings/check_slug?slug=:value
```

**Respuestas:**

```json
{ "available": true }
{ "available": false, "reason": "taken" }
{ "available": false, "reason": "invalid_format" }
```

La consulta excluye la iglesia actual (`where.not(id: @church.id)`) para que la iglesia pueda reguardar su propio slug sin recibir error.

No requiere autorización adicional — el controller ya verifica acceso via `ChurchSettingPolicy`.

---

## Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `config/routes.rb` | Agregar `get :check_slug` al resource de settings |
| `app/controllers/church_admin/settings_controller.rb` | Agregar acción `check_slug` |
| `app/javascript/controllers/slug_validator_controller.js` | Nuevo Stimulus controller |
| `app/javascript/controllers/index.js` | Registrar el nuevo controller |
| `app/views/church_admin/settings/show.html.erb` | Header con botón + slug field con data-attributes y badge |

---

## Decisiones de diseño

- **Debounce 500ms:** balance entre respuesta inmediata y no saturar el servidor con cada tecla.
- **Limpieza en el cliente, normalización en el servidor:** el modelo ya normaliza al guardar, el JS es solo UX. No hay riesgo de inconsistencia.
- **Botón condicional al slug guardado (no al valor actual del input):** el botón apunta a la URL real guardada, no al valor temporal del campo. Evita confusión si el usuario está editando el slug pero no ha guardado.
- **Sin autenticación extra en el endpoint:** el endpoint solo lee datos (no escribe) y ya está dentro del scope autenticado de `ChurchAdmin`.

---

## Fuera de scope

- Sugerencia automática de slug a partir del nombre de la iglesia
- Reserva de slugs / blacklist de palabras prohibidas
- Preview del perfil público embebido en la página de settings
