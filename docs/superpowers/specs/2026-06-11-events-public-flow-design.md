# Flujo de eventos: vista pública, RSVP de invitados, conteo y validación de asistencia

**Fecha:** 2026-06-11
**Estado:** aprobado por el usuario (RSVP de invitado sí; alcance completo A+B+C+D; validación por cruce RSVP vs check-in)
**Skills usados:** `superpowers:brainstorming`

## Problema

El dominio de eventos tiene los modelos completos (`Event`, `EventRsvp`,
`EventAttendance`) pero el flujo end-to-end está incompleto:

1. **El público no ve los eventos.** `Event.visibility` soporta `public`, pero
   la página pública (`/c/:slug`) solo muestra horarios de culto. El campo no
   tiene efecto real.
2. **No se sabe cuántos asistirán de un vistazo.** El RSVP de miembros funciona
   (Sí/No/Tal vez + acompañantes) pero el admin solo ve contadores sueltos; no
   hay resumen contra `capacity` (campo que existe y no se usa).
3. **Sin cuenta no se puede confirmar.** El RSVP vive en el portal de miembro;
   un visitante que ve un evento público no puede anotarse.
4. **La asistencia se cuenta pero no se valida.** El check-in manual existe,
   pero no hay cruce entre lo confirmado y lo real. Además hay dos defectos
   estructurales:
   - El índice único `event_id + member_id` en `event_attendances` impide
     registrar asistencia por fecha en eventos recurrentes (la del segundo
     domingo pisa la del primero).
   - `member_id` es obligatorio: los walk-ins (visitantes que llegaron sin
     RSVP) no se pueden contar.
   - El controlador hace `destroy` de asistencias al desmarcar — viola la
     regla "sin borrado físico".

## Decisiones tomadas (con el usuario, 2026-06-11)

| Decisión | Elección |
|---|---|
| ¿RSVP sin cuenta? | **Sí** — RSVP de invitado ligero (nombre + email/teléfono), sin crear `User` ni `Member`. La alternativa con verificación de email se descartó por fricción e infraestructura. |
| Alcance | **Completo (A+B+C+D)** en 3 PRs. |
| Validación de asistencia | **Cruce RSVP vs check-in** (no-shows, espontáneos, tasa). QR en puerta descartado para MVP. |

Nota de scope: la planificación marca "visitantes" como fuera del MVP. Esta
decisión habilita únicamente el RSVP de invitado y el walk-in con nombre; **no**
construye un módulo de visitantes (sin perfiles, sin seguimiento, sin
conversión a miembro).

## Fase A — Eventos en la página pública (PR 1)

- `Public::ChurchesController#show` agrega `@upcoming_events`:
  `church.events.upcoming.where(visibility: "public", status: "scheduled")`,
  ordenados por `starts_at`, límite razonable (ej. 6).
- Nuevo `Public::EventsController#show` bajo `scope "/c/:slug", module: :public`
  → `GET /c/:slug/eventos/:public_id`. Resuelve la iglesia por `slug` activo y
  el evento **solo si** es `public` (members_only/private → 404).
- El detalle muestra: título, fecha/hora, lugar, tipo, descripción,
  "X confirmados" y cupos restantes si hay `capacity`.
- **Nunca** se muestran datos de miembros (nombres de confirmados, responsable
  con datos de contacto, etc.) — regla de datos sensibles del CLAUDE.md.
- Diseño visual: mismo design system de la página pública existente.

## Fase B — RSVP de invitado sin cuenta (PR 2)

### Tabla nueva `event_guest_rsvps`

| Campo | Tipo | Notas |
|---|---|---|
| `public_id` | uuid | único, convención del proyecto |
| `church_id` | FK | aislamiento multi-tenant, indexado |
| `event_id` | FK | |
| `name` | string | obligatorio |
| `email` | string | obligatorio email **o** phone |
| `phone` | string | |
| `guests_count` | integer, default 0 | ≥ 0 |
| `status` | string enum | `attending` / `cancelled` — soft-cancel, sin destroy |
| `access_token` | string | único, generado con `SecureRandom.urlsafe_base64(32)`; capacidad de edición, separado del `public_id` |

Índices: único `[event_id, lower(email)]` (cuando email presente), `church_id`,
único `access_token`.

### Reglas

- Solo se puede crear RSVP en eventos `public` + `scheduled` de una iglesia
  activa.
- Validación de cupo: si `capacity` está definida, rechazar cuando
  `confirmed_attendees_count + 1 + guests_count > capacity` (primera vez que
  `capacity` tiene efecto).
- Anti-spam sin infraestructura nueva: campo honeypot oculto + throttle por IP
  en el controlador (contador en `Rails.cache`, ej. 5 intentos / 10 min).
- El invitado recibe (en pantalla de confirmación) la URL
  `GET /c/:slug/rsvp/:access_token` para **editar o cancelar** su confirmación.
  El token no expira en el MVP; cancelar = `status: cancelled`.
- `paper_trail` en `EventGuestRsvp` (registro de creación/cancelación).

### Conteo

`Event#confirmed_attendees_count` pasa a sumar:
RSVPs de miembros `attending` + sus `guests_count` + guest RSVPs `attending` +
sus `guests_count`.

### Lógica en servicio

Creación/edición/cancelación del guest RSVP en
`app/services/events/guest_rsvp.rb` (validación de cupo, normalización de
email/teléfono, honeypot fuera del servicio — eso es del controlador).

## Fase C — Panel de conteo en el admin (PR 2, misma entrega)

En `church_admin/events/show`:

- Tarjeta resumen: **Confirmados** (desglose: miembros / acompañantes /
  invitados), **Tal vez**, **No asisten**, y barra de ocupación contra
  `capacity` cuando exista.
- Lista de invitados confirmados (nombre + contacto + acompañantes), visible
  solo con permiso sobre el módulo de eventos (policy existente de eventos —
  el show ya está autorizado; no se agrega permiso nuevo).

## Fase D — Check-in y validación (PR 3)

### Cambios en `event_attendances`

1. **`occurrence_date` (date, not null)**: índice único pasa a
   `[event_id, member_id, occurrence_date]` (cuando `member_id` presente).
   Para eventos no recurrentes, `occurrence_date = event.starts_at.to_date`.
   Migración: backfill de filas existentes con `starts_at.to_date` del evento.
2. **Walk-ins:** `member_id` pasa a nullable y se agrega `guest_name` (string).
   Validación: `member_id` **o** `guest_name` presente. `church_id` sigue
   obligatorio.
3. **Sin borrado físico:** desmarcar pone `attended: false`; el controlador
   deja de hacer `destroy`. `paper_trail` en `EventAttendance`.

### Modo check-in

La vista de asistencia se rediseña como modo de uso "en la puerta":

- Selector de fecha de ocurrencia (solo si el evento es recurrente; por
  defecto, la fecha de hoy o la del evento).
- Búsqueda rápida de miembros, confirmados primero.
- Marcar/desmarcar de un toque vía Turbo (request por persona, sin submit
  gigante al final).
- Botón "Agregar visitante" inline: nombre → crea asistencia walk-in.

### Validación (el cruce)

En el show del admin, para eventos `completed` (o con asistencia registrada):

- **Asistencia real** vs **confirmados**.
- **No-shows:** miembros con RSVP `attending` sin asistencia en la fecha.
- **Espontáneos:** asistencias (miembros o walk-ins) sin RSVP previo.
- **Tasa de no-show** (no-shows / confirmados).
- Auditoría: `checked_in_by` + `checked_in_at` ya existen; paper_trail suma el
  historial de cambios.

## Qué NO cambia

- `EventRsvp` (RSVP de miembros) y el portal de miembro siguen igual.
- Permisos: sin módulos nuevos en la matriz; lo público no requiere permisos y
  lo admin usa `EventPolicy` existente.
- Recurrencia: **no** se implementa la expansión de ocurrencias (sigue siendo
  una fila por evento). `occurrence_date` en asistencia es el arreglo mínimo
  para que los recurrentes puedan registrar asistencia por fecha; la expansión
  real queda fuera de alcance.
- Sin notificaciones por email/WhatsApp (fuera del MVP).

## Testing (reglas de spec/CLAUDE.md)

- **Aislamiento:** dos iglesias en todo spec nuevo — el público de `/c/a` no ve
  eventos de la iglesia B; un `access_token` de la iglesia A no edita nada en B.
- **public_id:** specs estándar para `EventGuestRsvp`.
- **Guest RSVP:** happy path; email o teléfono requerido; evento privado → 404;
  evento cancelado → rechazo; cupo lleno → rechazo; duplicado por email →
  actualiza en lugar de duplicar; honeypot lleno → descarte silencioso;
  token inválido → 404; cancelación = soft-cancel.
- **Conteo:** `confirmed_attendees_count` suma miembros + acompañantes +
  invitados; excluye `cancelled` / `not_attending` / `maybe`.
- **Fase D:** dos asistencias del mismo miembro en fechas distintas coexisten;
  desmarcar no destruye el registro (queda `attended: false`); walk-in sin
  member válido; walk-in sin nombre inválido; backfill de `occurrence_date`.
- **Cruce:** spec del reporte con no-shows y espontáneos calculados sobre datos
  conocidos.

## División en PRs

| PR | Contenido | Riesgo |
|---|---|---|
| 1 | Fase A: página pública de eventos (solo lectura) | Mínimo |
| 2 | Fases B+C: `event_guest_rsvps` + servicio + UI pública de RSVP + panel de conteo admin | Medio (tabla nueva + endpoint público) |
| 3 | Fase D: `occurrence_date`, walk-ins, modo check-in Turbo, reporte de cruce | Medio-alto (migración con backfill) |
