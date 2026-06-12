# Rediseño UX: asignación de líder, co-líderes y miembros de un ministerio

**Fecha:** 2026-06-11
**Pantalla:** `ChurchAdmin::Ministries#show` — panel lateral "Gestión de miembros"
**Skills usados:** `superpowers:brainstorming`, `ui-ux-pro-max` (guías de jerarquía visual, formularios y accesibilidad)

## Problema

El panel actual muestra a todos los asignados en una lista plana donde el rol
(`Líder`, `Co-líder`, `Miembro`) solo se distingue leyendo el `<select>` de cada
fila:

1. **Sin jerarquía visual.** Con 9+ asignados no se ve de un vistazo quién
   lidera el ministerio. El líder aparece mezclado (incluso al final de la
   lista) con los miembros regulares.
2. **Sin señal de liderazgo faltante.** Nada indica que un ministerio no tiene
   líder asignado.
3. **Select estrecho** (`w-24`) que trunca la etiqueta "Co-líder".
4. **Accesibilidad pobre.** El select de rol y el botón de quitar no indican a
   qué persona pertenecen (sin `aria-label` contextual).
5. **Copy con erratas.** Las etiquetas i18n decían "Lider" y "Co-lider" (sin
   tilde).

## Enfoques considerados

| Enfoque | Descripción | Trade-offs |
|---|---|---|
| **A. Agrupación por rol + promoción in-place (elegido)** | La lista se divide en secciones Líder / Co-líderes / Miembros. Al cambiar el rol en el select, la fila se mueve animada a su sección. | Cero cambios de backend; reutiliza la semántica del formulario actual; accesible (basado en select nativo). |
| B. Slots dedicados con búsqueda propia por rol | Un buscador para líder (max 1), otro para co-líderes y otro para miembros. | Triplica la UI de búsqueda, más código Stimulus y más fricción para reasignar roles. |
| C. Drag & drop entre grupos | Arrastrar filas entre secciones. | JS pesado, accesibilidad difícil (HIG: no depender solo de gestos), fuera del stack ligero Hotwire. |

Se eligió **A**: máxima claridad con mínimo riesgo. El formulario sigue
enviando exactamente los mismos parámetros (`ministry[member_public_ids][]` +
`ministry[member_roles][public_id]`), por lo que controlador, servicio
`Ministries::MemberAssignment` y specs de request/servicio no cambian.

## Diseño

### Estructura del panel (sidebar)

```
Gestión de miembros                       9 asignados
──────────────────────────────────────────────────────
AGREGAR MIEMBRO
[🔍 Buscar por nombre...]
──────────────────────────────────────────────────────
LIDERAZGO
  Líder                                          (1)
    [WS] Wilson Segura        [Líder ▾]      ✕
  Co-líderes                                     (0)
    · Sin co-líderes ·                  (placeholder)
──────────────────────────────────────────────────────
MIEMBROS                                         (8)
  [PP] Pablo Perez            [Miembro ▾]    ✕
  ...
──────────────────────────────────────────────────────
[ Guardar asignación ]
```

### Reglas de interacción

- **Agregar:** la búsqueda no cambia. Un miembro agregado entra a la sección
  *Miembros* con rol `Miembro`; se promueve con el select de su fila.
- **Promover/degradar:** cambiar el select mueve la fila a la sección
  correspondiente con la animación `animate-fade-in-up` existente
  (Material: la moción expresa causa-efecto).
- **Líder vacío:** placeholder ámbar "Sin líder asignado" — nudge visible sin
  bloquear el guardado (el backend sigue permitiendo 0..n líderes).
- **Contadores por sección** actualizados en vivo por Stimulus.
- **Color semántico del select** (no solo posición): Líder = violeta,
  Co-líder = cielo (sky), Miembro = neutro. Color + texto + agrupación
  (`color-not-only`, WCAG).

### Accesibilidad (ui-ux-pro-max §1, §8)

- `aria-label="Rol de {nombre}"` en cada select de rol.
- `aria-label="Quitar a {nombre}"` en cada botón de quitar.
- Jerarquía por tamaño/peso/espaciado, no solo color.
- Targets táctiles ≥ 40px en controles de fila (compactos pero con padding).

### Cambios técnicos

| Archivo | Cambio |
|---|---|
| `app/views/church_admin/ministries/show.html.erb` | `tagsZone` ahora contiene tres zonas de grupo (`data-role-group`), cada una con encabezado, contador (`data-member-search-target="groupCount"`) y placeholder (`groupEmpty`). |
| `app/views/church_admin/ministries/_member_row.html.erb` | Select más ancho (`w-28`), clases por rol, `data-action="change->member-search#roleChanged"`, `aria-label` contextuales. |
| `app/javascript/controllers/member_search_controller.js` | Nuevos targets **opcionales** `group`, `groupCount`, `groupEmpty` y acción `roleChanged`. Si la vista no define grupos (boards, events, families), el comportamiento es idéntico al actual — retro-compatible. |
| `config/locales/es.yml` | Tildes: `Líder`, `Co-líder`. |

**Sin cambios:** rutas, controlador, servicio de asignación, modelo,
`members/search.html.erb` (resultados de búsqueda compartidos), demás vistas
que usan `member-search`.

### Compatibilidad del controller Stimulus compartido

`member-search` también se usa en `boards/show`, `events/_form` y
`families/show`. Toda la lógica nueva está protegida con
`this.hasGroupTarget`; sin zonas de grupo, `addMember` sigue anexando a
`tagsZone` y `removeTag`/`emptyState` no cambian.

### Pruebas

- Backend sin cambios → los specs existentes de request
  (`spec/requests/church_admin/ministries_spec.rb`) y servicio
  (`spec/services/ministries/member_assignment_spec.rb`) cubren la asignación.
- No hay infraestructura de system specs con JS en el proyecto; la interacción
  Stimulus se verifica manualmente (no se introduce Selenium en este cambio).
- Verificación: `bundle exec rspec` + `bundle exec rubocop`.

## Fuera de alcance

- Forzar un único líder por ministerio (regla de dominio nueva; requeriría
  validación en `Ministries::MemberAssignment` y migración de datos).
- Acciones rápidas "agregar como líder" en los resultados de búsqueda.
- Reordenar miembros manualmente.
