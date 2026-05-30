# Sidebar Navigation — Spec

**Fecha:** 2026-05-30
**Estado:** Aprobado

## Problema

La navegación actual usa un topbar de dos niveles: una barra superior con logo/usuario y un sub-nav horizontal con ~15 ítems en scroll. Con el crecimiento del módulo de iglesia, el sub-nav se satura y dificulta la orientación.

## Decisiones de diseño

| Dimensión | Decisión |
|---|---|
| Estructura | Sidebar + topbar mínimo (Opción A) |
| Agrupación | 4 secciones funcionales (Opción 1) |
| Contexto global | Sin sidebar — solo topbar cuando no hay iglesia activa |
| Ancho sidebar | 224px fijo |
| Mobile | Drawer con overlay, toggle en topbar |

## Estructura del layout

```
┌─────────────────────────────────────────────────────┐
│  TOPBAR  (h-14, sticky)                             │
│  [Logo] [·] [Chip: Nombre iglesia →] ... [email][X] │
└─────────────────────────────────────────────────────┘
┌──────────┬──────────────────────────────────────────┐
│ SIDEBAR  │  CONTENT AREA                            │
│ 224px    │  bg-slate-50, padding 28px               │
│ sticky   │                                          │
│ h-full   │                                          │
└──────────┴──────────────────────────────────────────┘
```

## Topbar

**Siempre visible** cuando el usuario está autenticado.

| Elemento | Detalle |
|---|---|
| Logo | `igle·org` con icono violeta, link a `root_path` |
| Separador | `1px bg-slate-200` |
| Chip de iglesia | `bg-violet-50 text-violet-700`, muestra nombre de iglesia activa, link a `churches_path` para cambiar. Solo visible cuando `current_church.present?` |
| Email | `text-xs text-slate-400`, oculto en pantallas pequeñas |
| Avatar | Inicial del email, `bg-violet-100 text-violet-700 rounded-full` |
| Botón Salir | Border, icono + texto "Salir", `DELETE /users/sign_out` |

**Sin iglesia activa:** topbar muestra solo logo + email + avatar + salir. El chip no aparece.

**Super admin:** cuando `current_user.super_admin?`, el topbar muestra un link adicional "Plataforma" (→ `platform_root_path`) entre el logo y el separador. No aparece en el sidebar porque es un acceso global, no de iglesia.

## Sidebar

**Solo visible** cuando `current_church.present? && current_church_membership&.active?`.

**Ancho:** 224px fijo. Scrollable verticalmente (`overflow-y: auto`) cuando los ítems exceden la altura.

### Secciones y ítems

```
Resumen                           ← sin sección, separador arriba

── CONGREGACIÓN ──────────────────
👤  Miembros
🏠  Familias
🏛  Ministerios
👥  Junta directiva

── ACTIVIDADES ───────────────────
📅  Eventos
🕐  Horarios de servicio

── HERRAMIENTAS ──────────────────
📋  Directorio
📥  Solicitudes           [badge: N pendientes]
📊  Reportes
✏️  Notas pastorales      [tag: Pastoral]  ← condicional

── ADMINISTRACIÓN ────────────────
🛡  Roles y permisos
👤  Usuarios
📦  Catálogos             [badge: 2]  ← agrupa Ocupaciones + Habilidades

────────────────────── (separador)
👤  Mi perfil
⚙️  Configuración
```

### Visibilidad condicional de ítems

| Ítem | Condición |
|---|---|
| Miembros | `policy(Member).index?` |
| Familias | `policy(Family).index?` |
| Ministerios | `policy(Ministry).index?` |
| Junta directiva | `policy(Board).index?` |
| Eventos | `policy(Event).index?` |
| Horarios | `policy(ChurchServiceTime).index?` |
| Directorio | `ServiceDirectoryPolicy.new(current_user, nil).index?` |
| Solicitudes | `policy(ProfileChangeRequest).index?` |
| Reportes | `ReportPolicy.new(current_user, nil).index?` |
| Notas pastorales | `policy(PastoralNote).index?` |
| Roles y permisos | `policy(Role).index?` |
| Usuarios | `policy(ChurchMembership).index?` |
| Catálogos | `policy(Occupation).index? \|\| policy(Skill).index?` |

### Estado activo

- `bg-violet-50 text-violet-700 font-semibold` + `border-right: 2.5px solid rgb(124 58 237)` (violet-600)
- El estado activo usa `request.path.start_with?(ruta)` para secciones con sub-rutas, `current_page?` para rutas exactas.

### Badge de Solicitudes

- Número de `ProfileChangeRequest.where(church: current_church, status: :pending).count`
- Visible solo si > 0
- Colores: `bg-amber-100 text-amber-700`

### Tag "Pastoral"

- Badge pequeño `bg-fuchsia-100 text-fuchsia-700` junto al ítem de Notas pastorales
- Solo aparece cuando el ítem es visible (es decir, solo para usuarios con rol pastoral)

### "Catálogos" como agrupador

Los ítems "Ocupaciones" y "Habilidades" se consolidan bajo un único ítem "Catálogos" en el sidebar. El link destino es `church_admin_occupations_path` si `policy(Occupation).index?`, de lo contrario `church_admin_skills_path`. El badge `2` es un indicador fijo que señala que hay dos sub-módulos bajo este agrupador, no un conteo de pendientes.

## Archivos a modificar/crear

| Archivo | Acción |
|---|---|
| `app/views/shared/_app_navigation.html.erb` | Reemplazar completamente — nuevo topbar + sidebar |
| `app/views/shared/_app_sidebar.html.erb` | Nuevo partial: solo el `<nav>` del sidebar |
| `app/views/layouts/application.html.erb` | Ajustar estructura del `<body>` para layout con sidebar |
| `app/javascript/controllers/sidebar_controller.js` | Nuevo: toggle mobile drawer |
| Páginas con `max-w-7xl mx-auto px-6` | Ajustar padding y max-width según nuevo layout |

## Layout del body

```erb
<!-- application.html.erb -->
<body class="min-h-screen bg-slate-50 font-sans antialiased">
  <%= render "shared/app_navigation" %>  <%# topbar %>

  <% if user_signed_in? && current_church.present? && current_church_membership&.active? %>
    <div class="flex h-[calc(100vh-56px)]">
      <%= render "shared/app_sidebar" %>
      <main class="flex-1 overflow-y-auto">
        <%= yield %>
      </main>
    </div>
  <% else %>
    <main>
      <%= yield %>
    </main>
  <% end %>
</body>
```

## Mobile (drawer)

- El topbar muestra un botón hamburguesa en móvil (< 768px)
- Al hacer click, el sidebar aparece como overlay con backdrop semitransparente
- El drawer se cierra al hacer click en el backdrop o en cualquier ítem del sidebar
- Implementado con un Stimulus controller `sidebar` + clases CSS `translate-x-[-100%]` → `translate-x-0`

## Impacto en páginas existentes

Las páginas que usan `<section class="mx-auto w-full max-w-7xl px-6 py-8">` no necesitan cambios estructurales si el `<main>` tiene `overflow-y-auto`. El `max-w-7xl` sigue siendo válido para el contenido. Solo hay que verificar que el padding horizontal sea consistente.

## Lo que NO cambia

- Mensajes flash: siguen en `fixed top-4 right-4 z-[9999]`
- Rutas y policies: sin cambios
- Layout de formularios y tablas: sin cambios
- `layout :public` para páginas públicas: sin cambios

## Criterios de aceptación

- [ ] Sidebar visible en todas las rutas de `church_admin/`, `church_pastor/`, `church_member_portal/`
- [ ] Ítem activo correcto al navegar
- [ ] Ítems condicionales aparecen/ocultan según permiso del usuario
- [ ] Badge de solicitudes se actualiza con el conteo real
- [ ] Sin sidebar en páginas fuera de contexto de iglesia
- [ ] En mobile: drawer funcional con Stimulus
- [ ] Sin regresión visual en páginas existentes (dashboard, miembros, ministerios, etc.)
