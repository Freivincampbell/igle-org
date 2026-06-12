# Rediseño de la página pública de la iglesia — diseño

**Fecha:** 2026-06-12
**Estado:** aprobado por el usuario (dirección "A · Cálida"; degradado de marca solo; ubicación con botón a Google Maps; extras: navbar con anclas + WhatsApp flotante + teaser de directorio de servicios)
**Skills usados:** `superpowers:brainstorming`, `ui-ux-pro-max`

## Objetivo

Reemplazar la página pública actual (`/c/:slug`, hoy solo nombre + descripción + horarios + lista de eventos) por una landing fresca y moderna, usando solo los datos públicos de la iglesia y su color de marca.

## Dirección elegida: "A · Cálida"

Hero a pantalla completa con degradado de marca, recorrido vertical de secciones. Mockups de referencia (descartables): `tmp/mockups/a.html`.

## Datos públicos disponibles (modelo `Church`)

Identidad: `name`, `logo` (Active Storage), `description`, `primary_color`, `secondary_color`.
Contacto: `email`, `phone`, `whatsapp`, `website`.
Redes: `facebook_url`, `instagram_url`, `youtube_url`.
Ubicación: `address_line_1`, `address_line_2`, `city`, `state`, `country`, `postal_code`.
Relacionados (ya cargados o a cargar en el controller): `@service_times` (activos, ordenados), `@upcoming_events` (públicos, programados, futuros).
Flag: `service_directory_enabled`.

## Estructura de la página (orden de secciones)

1. **Navbar (sticky)** translúcido sobre el hero: logo + nombre a la izquierda; anclas a la derecha (`Cultos`, `Eventos`, `Ubicación`, `Contacto`) con scroll suave (`scroll-behavior: smooth` en CSS, sin JS). En móvil, las anclas colapsan a solo el CTA de contacto.
2. **Hero** con degradado de marca (`primary_color` → `secondary_color`; fallback violet-600 → violet-500). Formas geométricas sutiles (círculos translúcidos), **sin foto de stock**. Logo (si está adjunto; si no, monograma con iniciales), nombre (h1), descripción (si existe), y CTAs: "Ver próximos eventos" (ancla a #eventos) y "Horarios de culto" (ancla a #cultos). Onda divisoria SVG al pie del hero.
3. **Cultos** (`#cultos`) — solo si `@service_times.any?`: tarjetas/filas con día+nombre, lugar y horario.
4. **Próximos eventos** (`#eventos`) — solo si `@upcoming_events.any?`: tarjetas con chip de fecha (día/mes), título, hora y lugar, enlazando a `public_church_event_path`.
5. **Directorio de servicios** (teaser) — solo si `service_directory_enabled?`: bloque informativo invitando a contactar (NO enlaza a un directorio público porque aún no existe; ver "Fuera de alcance"). CTA a `#contacto`.
6. **Ubicación** (`#ubicacion`) — solo si hay dirección: dirección en texto + botón "Cómo llegar" que abre Google Maps (`https://www.google.com/maps/search/?api=1&query=<dirección urlencoded>`), `target="_blank" rel="noopener"`.
7. **Footer / Contacto** (`#contacto`): nombre, email/teléfono (si existen), y redes (solo los íconos cuyas URLs existen).
8. **WhatsApp flotante** — solo si `whatsapp` presente: botón fijo (`fixed bottom-right`) que abre `https://wa.me/<solo-dígitos>`.

Toda sección es **condicional**: si no hay datos, no se renderiza (nada vacío).

## Helpers nuevos (en `ApplicationHelper`)

- `church_maps_url(church)` → URL de Google Maps con la dirección compuesta (nil si no hay dirección).
- `church_whatsapp_url(church)` → `https://wa.me/<dígitos>` (nil si no hay whatsapp).
- `church_address_line(church)` → dirección legible en una línea (compact_blank join).
- Reutiliza `church_accent_color` (ya existe, con validación hex). Para el secundario: `church_accent_secondary_color` análogo (fallback a un violeta más claro).

El degradado se arma inline con los dos colores (igual patrón que `church_accent_color`, re-validado, defensa en profundidad para el atributo `style`).

## Controller

`Public::ChurchesController#show` ya resuelve `@church`, `@service_times`, `@upcoming_events`. No requiere cambios salvo, si hace falta, exponer un helper de "hay datos de contacto/redes/ubicación" (se puede resolver en la vista con condicionales simples).

## Accesibilidad / calidad (ui-ux-pro-max)

- Contraste AA: texto blanco sobre degradado de marca (los colores de marca válidos son hex de 6 dígitos; el violeta por defecto cumple). Para colores de marca muy claros subidos por el admin, el texto del hero podría perder contraste — **mitigación**: el hero siempre superpone un velo oscuro sutil (`bg-black/10`) y usa `text-white` con `drop-shadow` ligero; aceptable para MVP. (Mejora futura: calcular luminancia y elegir texto claro/oscuro.)
- `scroll-behavior: smooth` respeta `prefers-reduced-motion` (se desactiva con media query).
- Touch targets ≥ 44px en navbar, CTAs, botón flotante y redes; `aria-label` en íconos.
- Móvil primero; `max-w` consistente; sin scroll horizontal.
- Sin datos sensibles de personas. Solo datos de la iglesia.

## Testing (request specs)

Extender `spec/requests/public/churches_spec.rb`:
- Render OK con todos los datos: aparece hero (nombre), CTAs, y cada sección con datos.
- Secciones condicionales: sin service_times → no aparece "Cultos"; sin eventos → no "Próximos eventos"; sin dirección → no botón "Cómo llegar"; sin whatsapp → no botón flotante; `service_directory_enabled: false` → no teaser.
- WhatsApp: el enlace usa solo dígitos (`wa.me/50622223333`).
- Maps: el botón apunta a google.com/maps con la dirección.
- Redes: solo se renderizan los íconos cuyas URLs existen.
- Aislamiento: ya cubierto por el spec existente de eventos/iglesia (no se rompe).

## Fuera de alcance

- **Directorio de servicios público completo** (listar miembros que ofrecen servicios respetando privacidad): es una feature propia; aquí solo va el teaser condicional que invita a contactar.
- Cálculo de luminancia para texto del hero según color de marca (mejora futura).
- Mapa embebido (se eligió el botón a Google Maps).
- Foto de hero subible por la iglesia (no hay campo; se usa degradado).
