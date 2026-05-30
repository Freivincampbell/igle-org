# Sidebar Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el doble topbar horizontal por un sidebar lateral elegante con 4 secciones funcionales, conservando el sistema de permisos dinámicos y el diseño Soft UI Evolution existente.

**Architecture:** El topbar se reduce a logo + chip de iglesia + usuario. El sidebar (`_app_sidebar.html.erb`) se renderiza solo dentro del contexto de iglesia. El `application.html.erb` envuelve el contenido en un flex container cuando hay iglesia activa. Un Stimulus controller (`sidebar`) maneja el drawer mobile. El `data-controller="sidebar"` vive en `<body>` para que el hamburger del topbar y los targets del sidebar compartan scope.

**Tech Stack:** Rails 8 ERB, Tailwind CSS v4, Hotwire Stimulus, Heroicons inline SVG, RSpec request specs.

---

## File Map

| Archivo | Acción |
|---------|--------|
| `spec/requests/navigation_spec.rb` | MODIFY — actualizar assertions al nuevo DOM del sidebar |
| `app/helpers/application_helper.rb` | MODIFY — agregar `sidebar_item_class` helper |
| `app/views/shared/_app_navigation.html.erb` | REWRITE — topbar mínimo con hamburger mobile |
| `app/views/shared/_app_sidebar.html.erb` | CREATE — nav con 4 secciones + condicionales + badges |
| `app/views/layouts/application.html.erb` | MODIFY — flex layout sidebar+main cuando hay iglesia activa |
| `app/javascript/controllers/sidebar_controller.js` | CREATE — toggle mobile drawer |

---

## Task 1: Actualizar navigation_spec.rb (TDD — specs primero)

**Files:**
- Modify: `spec/requests/navigation_spec.rb`

Antes de tocar ningún partial, actualiza los specs para que describan el comportamiento esperado del nuevo sidebar. Estos tests fallarán hasta completar los Tasks 2–5.

- [ ] **Step 1.1: Leer el archivo actual**

```bash
cat spec/requests/navigation_spec.rb
```

- [ ] **Step 1.2: Reemplazar el contenido del archivo**

```ruby
require "rails_helper"

RSpec.describe "Navigation" do
  it "muestra link a Plataforma y Salir al super admin" do
    user = create(:user, :super_admin)

    sign_in user

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Plataforma")
    expect(response.body).to include("Salir")
  end

  it "no muestra el chip de iglesia cuando el usuario no está en una iglesia" do
    user = create(:user)

    sign_in user

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("data-sidebar-target=\"nav\"")
  end

  it "muestra el sidebar con las 4 secciones a un owner de iglesia" do
    church = create(:church)
    membership = create(:church_membership, :owner, church:)

    sign_in membership.user

    get church_admin_members_path(church)

    expect(response).to have_http_status(:ok)
    # sidebar present
    expect(response.body).to include("data-sidebar-target=\"nav\"")
    # section labels
    expect(response.body).to include("Congregación")
    expect(response.body).to include("Actividades")
    expect(response.body).to include("Herramientas")
    expect(response.body).to include("Administración")
    # items
    expect(response.body).to include("Resumen")
    expect(response.body).to include("Miembros")
    expect(response.body).to include("Ministerios")
    expect(response.body).to include("Eventos")
    expect(response.body).to include("Roles")
    expect(response.body).to include("Salir")
  end

  it "muestra el chip de iglesia en el topbar cuando hay iglesia activa" do
    church = create(:church)
    membership = create(:church_membership, :owner, church:)

    sign_in membership.user

    get church_admin_members_path(church)

    expect(response.body).to include(church.name)
    expect(response.body).to include("sidebar-chip-church")
  end

  it "no muestra Notas pastorales a un owner sin rol pastoral" do
    church = create(:church)
    membership = create(:church_membership, :owner, church:)

    sign_in membership.user

    get church_admin_members_path(church)

    expect(response.body).not_to include("Notas pastorales")
  end

  it "no muestra el sidebar fuera del contexto de iglesia" do
    user = create(:user)

    sign_in user

    get churches_path

    expect(response.body).not_to include("data-sidebar-target=\"nav\"")
  end

  it "no muestra Salir a visitantes" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Salir")
  end

  it "cierra sesión desde el topbar" do
    user = create(:user)

    sign_in user

    delete destroy_user_session_path

    expect(response).to redirect_to(root_path)
  end
end
```

- [ ] **Step 1.3: Verificar que los tests nuevos fallan**

```bash
bundle exec rspec spec/requests/navigation_spec.rb --format documentation
```

Expected: varios failures (los assertions del sidebar aún no existen en el DOM). Confirmar que el test de "cierra sesión" sigue pasando.

- [ ] **Step 1.4: Commit spec**

```bash
git add spec/requests/navigation_spec.rb
git commit -m "test: actualizar navigation_spec para sidebar (TDD — rojo)"
```

---

## Task 2: Agregar helper `sidebar_item_class` a ApplicationHelper

**Files:**
- Modify: `app/helpers/application_helper.rb`

- [ ] **Step 2.1: Agregar el método al final del módulo, antes del `end` final**

Abrir `app/helpers/application_helper.rb` y agregar justo antes del `end` final del módulo:

```ruby
  def sidebar_item_class(active)
    base = "flex items-center gap-2.5 px-4 py-[7px] text-sm border-r-2 transition-colors w-full"
    if active
      "#{base} font-semibold text-violet-700 bg-violet-50 border-violet-600"
    else
      "#{base} font-medium text-slate-600 border-transparent hover:bg-slate-50 hover:text-slate-900"
    end
  end
```

- [ ] **Step 2.2: Verificar que el helper no rompe los tests existentes**

```bash
bundle exec rspec spec/requests/ --format progress
```

Expected: solo fallan los specs del Task 1 (los nuevos). El resto verde.

- [ ] **Step 2.3: Commit**

```bash
git add app/helpers/application_helper.rb
git commit -m "feat: agregar sidebar_item_class helper"
```

---

## Task 3: Crear `_app_sidebar.html.erb`

**Files:**
- Create: `app/views/shared/_app_sidebar.html.erb`

- [ ] **Step 3.1: Crear el archivo con el siguiente contenido completo**

```erb
<%# ── Mobile backdrop ── %>
<div class="fixed inset-0 z-30 bg-black/20 hidden"
     data-sidebar-target="backdrop"
     data-action="click->sidebar#close"></div>

<%# ── Sidebar nav ── %>
<nav class="fixed top-14 bottom-0 left-0 z-40 w-56 flex-shrink-0 flex flex-col
            bg-white border-r border-slate-100 overflow-y-auto
            -translate-x-full transition-transform duration-200 ease-in-out
            md:static md:top-auto md:bottom-auto md:h-full md:translate-x-0"
     data-sidebar-target="nav">

  <%# ── Resumen ── %>
  <div class="pt-3 pb-1">
    <%= link_to church_path(current_church),
          class: sidebar_item_class(current_page?(church_path(current_church))) do %>
      <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z"/>
      </svg>
      Resumen
    <% end %>
  </div>

  <div class="h-px bg-slate-100 mx-3 my-0.5"></div>

  <%# ── Congregación ── %>
  <div>
    <p class="px-4 pt-3 pb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400">Congregación</p>

    <% if policy(Member).index? %>
      <%= link_to church_admin_members_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_members_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"/>
        </svg>
        Miembros
      <% end %>
    <% end %>

    <% if policy(Family).index? %>
      <%= link_to church_admin_families_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_families_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
        </svg>
        Familias
      <% end %>
    <% end %>

    <% if policy(Ministry).index? %>
      <%= link_to church_admin_ministries_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_ministries_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Z"/>
        </svg>
        Ministerios
      <% end %>
    <% end %>

    <% if policy(Board).index? %>
      <%= link_to church_admin_boards_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_boards_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M18 18.72a9.094 9.094 0 0 0 3.741-.479 3 3 0 0 0-4.682-2.72m.94 3.198.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0 1 12 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 0 1 6 18.719m12 0a5.971 5.971 0 0 0-.941-3.197m0 0A5.995 5.995 0 0 0 12 12.75a5.995 5.995 0 0 0-5.058 2.772m0 0a3 3 0 0 0-4.681 2.72 8.986 8.986 0 0 0 3.74.477m.94-3.197a5.971 5.971 0 0 0-.94 3.197M15 6.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm6 3a2.25 2.25 0 1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Zm-13.5 0a2.25 2.25 0 1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Z"/>
        </svg>
        Junta directiva
      <% end %>
    <% end %>
  </div>

  <%# ── Actividades ── %>
  <div>
    <p class="px-4 pt-3 pb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400">Actividades</p>

    <% if policy(Event).index? %>
      <%= link_to church_admin_events_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_events_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/>
        </svg>
        Eventos
      <% end %>
    <% end %>

    <% if policy(ChurchServiceTime).index? %>
      <%= link_to church_admin_service_times_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_service_times_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
        </svg>
        Horarios de servicio
      <% end %>
    <% end %>
  </div>

  <%# ── Herramientas ── %>
  <div>
    <p class="px-4 pt-3 pb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400">Herramientas</p>

    <% if ServiceDirectoryPolicy.new(current_user, nil).index? %>
      <%= link_to church_admin_service_directory_path(current_church),
            class: sidebar_item_class(current_page?(church_admin_service_directory_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 0 0 2.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 0 0-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 0 0 .75-.75 2.25 2.25 0 0 0-.1-.664m-5.8 0A2.251 2.251 0 0 1 13.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25ZM6.75 12h.008v.008H6.75V12Zm0 3h.008v.008H6.75V15Zm0 3h.008v.008H6.75V18Z"/>
        </svg>
        Directorio
      <% end %>
    <% end %>

    <% if policy(ProfileChangeRequest).index? %>
      <% pending_count = ProfileChangeRequest.where(church: current_church, status: :pending).count %>
      <%= link_to church_admin_profile_change_requests_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_profile_change_requests_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 13.5h3.86a2.25 2.25 0 0 1 2.012 1.244l.256.512a2.25 2.25 0 0 0 2.013 1.244h3.218a2.25 2.25 0 0 0 2.013-1.244l.256-.512a2.25 2.25 0 0 1 2.013-1.244h3.859m-19.5.338V18a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18v-4.162c0-.224-.034-.447-.1-.661L19.24 5.338a2.25 2.25 0 0 0-2.15-1.588H6.911a2.25 2.25 0 0 0-2.15 1.588L2.35 13.177a2.25 2.25 0 0 0-.1.661Z"/>
        </svg>
        Solicitudes
        <% if pending_count > 0 %>
          <span class="ml-auto rounded-full bg-amber-100 px-1.5 py-0.5 text-[9px] font-bold text-amber-700"><%= pending_count %></span>
        <% end %>
      <% end %>
    <% end %>

    <% if ReportPolicy.new(current_user, nil).index? %>
      <%= link_to church_admin_reports_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_reports_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z"/>
        </svg>
        Reportes
      <% end %>
    <% end %>

    <% if policy(PastoralNote).index? %>
      <%= link_to church_pastor_pastoral_notes_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_pastor_pastoral_notes_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10"/>
        </svg>
        Notas pastorales
        <span class="ml-auto rounded-full bg-fuchsia-100 px-1.5 py-0.5 text-[9px] font-bold text-fuchsia-700">Pastoral</span>
      <% end %>
    <% end %>
  </div>

  <%# ── Administración ── %>
  <div>
    <p class="px-4 pt-3 pb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400">Administración</p>

    <% if policy(Role).index? %>
      <%= link_to church_admin_roles_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_roles_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z"/>
        </svg>
        Roles y permisos
      <% end %>
    <% end %>

    <% if policy(ChurchMembership).index? %>
      <%= link_to church_admin_memberships_path(current_church),
            class: sidebar_item_class(request.path.start_with?(church_admin_memberships_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
        </svg>
        Usuarios
      <% end %>
    <% end %>

    <% if policy(Occupation).index? || policy(Skill).index? %>
      <% catalogs_path = policy(Occupation).index? ? church_admin_occupations_path(current_church) : church_admin_skills_path(current_church) %>
      <% catalogs_active = request.path.start_with?(church_admin_occupations_path(current_church)) || request.path.start_with?(church_admin_skills_path(current_church)) %>
      <%= link_to catalogs_path,
            class: sidebar_item_class(catalogs_active) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 5.625c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125"/>
        </svg>
        Catálogos
        <span class="ml-auto rounded-full bg-violet-100 px-1.5 py-0.5 text-[9px] font-bold text-violet-600">2</span>
      <% end %>
    <% end %>
  </div>

  <%# ── Bottom: Mi perfil + Configuración ── %>
  <div class="mt-auto border-t border-slate-100 pt-1 pb-2">
    <%= link_to church_member_portal_profile_path(current_church),
          class: sidebar_item_class(current_page?(church_member_portal_profile_path(current_church))) do %>
      <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/>
      </svg>
      Mi perfil
    <% end %>

    <% if church_setting_visible?(current_church) %>
      <%= link_to church_admin_settings_path(current_church),
            class: sidebar_item_class(current_page?(church_admin_settings_path(current_church))) do %>
        <svg class="h-[15px] w-[15px] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z"/><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
        </svg>
        Configuración
      <% end %>
    <% end %>
  </div>

</nav>
```

- [ ] **Step 3.2: Commit**

```bash
git add app/views/shared/_app_sidebar.html.erb
git commit -m "feat: crear partial _app_sidebar con 4 secciones"
```

---

## Task 4: Reescribir `_app_navigation.html.erb` (topbar)

**Files:**
- Modify: `app/views/shared/_app_navigation.html.erb`

- [ ] **Step 4.1: Reemplazar el contenido completo del partial**

```erb
<% if user_signed_in? %>
<header class="sticky top-0 z-50 h-14 bg-white/95 backdrop-blur-sm border-b border-slate-200">
  <div class="flex h-full items-center gap-3 px-4 sm:px-6">

    <%# Logo %>
    <%= link_to root_path, class: "flex items-center gap-2 group shrink-0" do %>
      <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-600 text-white shadow-sm group-hover:bg-violet-700 transition-colors">
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12 11.204 3.045c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75"/>
        </svg>
      </div>
      <span class="hidden sm:block text-sm font-bold tracking-tight text-slate-900">igle<span class="text-violet-600">·org</span></span>
    <% end %>

    <%# Plataforma (solo super admin) %>
    <% if current_user.super_admin? %>
      <div class="h-5 w-px bg-slate-200 shrink-0"></div>
      <%= link_to platform_root_path,
            class: "hidden sm:flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs font-semibold transition-colors #{current_page?(platform_root_path) ? 'bg-violet-50 text-violet-700' : 'text-slate-500 hover:bg-slate-100 hover:text-slate-800'}" do %>
        <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z"/><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/>
        </svg>
        Plataforma
      <% end %>
    <% end %>

    <%# Chip de iglesia activa %>
    <% if current_church.present? && current_church_membership&.active? %>
      <%= link_to churches_path,
            id: "sidebar-chip-church",
            class: "hidden sm:flex items-center gap-1.5 rounded-full bg-violet-50 px-3 py-1 text-xs font-semibold text-violet-700 hover:bg-violet-100 transition-colors" do %>
        <span class="h-1.5 w-1.5 rounded-full bg-violet-500 shrink-0"></span>
        <span class="max-w-[160px] truncate"><%= current_church.name %></span>
        <svg class="h-3 w-3 shrink-0 opacity-50" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5"/>
        </svg>
      <% end %>
    <% end %>

    <%# Derecha: usuario + salir + hamburger %>
    <div class="ml-auto flex items-center gap-2">

      <%# Hamburger — solo mobile, solo con sidebar activo %>
      <% if current_church.present? && current_church_membership&.active? %>
        <button class="md:hidden flex items-center justify-center h-8 w-8 rounded-md text-slate-500 hover:bg-slate-100 hover:text-slate-700 transition-colors"
                aria-label="Abrir menú"
                data-action="click->sidebar#toggle">
          <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"/>
          </svg>
        </button>
      <% end %>

      <%# Avatar + email %>
      <div class="hidden sm:flex items-center gap-2">
        <div class="flex h-7 w-7 items-center justify-center rounded-full bg-violet-100 text-xs font-semibold text-violet-700 shrink-0">
          <%= current_user.email.first.upcase %>
        </div>
        <span class="hidden lg:block text-xs text-slate-400 max-w-[180px] truncate"><%= current_user.email %></span>
      </div>

      <%# Salir %>
      <%= button_to destroy_user_session_path, method: :delete,
            form_class: "inline-flex",
            class: "flex items-center gap-1.5 rounded-md border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50 hover:text-slate-900 transition-colors cursor-pointer" do %>
        <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 9V5.25A2.25 2.25 0 0 1 10.5 3h6a2.25 2.25 0 0 1 2.25 2.25v13.5A2.25 2.25 0 0 1 16.5 21h-6a2.25 2.25 0 0 1-2.25-2.25V15m-3 0-3-3m0 0 3-3m-3 3H15"/>
        </svg>
        <span class="hidden sm:block">Salir</span>
      <% end %>
    </div>

  </div>
</header>
<% end %>
```

- [ ] **Step 4.2: Commit**

```bash
git add app/views/shared/_app_navigation.html.erb
git commit -m "feat: reescribir topbar — mínimo con chip de iglesia y hamburger mobile"
```

---

## Task 5: Actualizar `application.html.erb` (layout con sidebar)

**Files:**
- Modify: `app/views/layouts/application.html.erb`

- [ ] **Step 5.1: Reemplazar el `<body>` completo**

El `<head>` no cambia. Solo reemplaza el `<body>` completo:

```erb
  <body class="min-h-screen bg-slate-50 font-sans text-slate-950 antialiased"
        data-controller="sidebar">
    <%= render "shared/app_navigation" %>

    <%# Flash messages %>
    <% if notice.present? || alert.present? %>
      <div id="flash-messages" class="fixed top-4 right-4 z-[9999] flex flex-col gap-2 w-full max-w-sm pointer-events-none">
        <% if notice.present? %>
          <div class="pointer-events-auto flex items-start gap-3 rounded-xl border border-emerald-200 bg-white px-4 py-3 shadow-card"
               data-controller="flash"
               data-flash-duration-value="4000">
            <div class="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
              <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
              </svg>
            </div>
            <p class="flex-1 text-sm font-medium text-slate-800"><%= notice %></p>
            <button class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Cerrar"
                    data-action="click->flash#dismiss">
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        <% end %>
        <% if alert.present? %>
          <div class="pointer-events-auto flex items-start gap-3 rounded-xl border border-red-200 bg-white px-4 py-3 shadow-card"
               data-controller="flash"
               data-flash-duration-value="6000">
            <div class="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-red-100 text-red-600">
              <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" />
              </svg>
            </div>
            <p class="flex-1 text-sm font-medium text-slate-800"><%= alert %></p>
            <button class="text-slate-400 hover:text-slate-600 transition-colors" aria-label="Cerrar"
                    data-action="click->flash#dismiss">
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        <% end %>
      </div>
    <% end %>

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

- [ ] **Step 5.2: Commit**

```bash
git add app/views/layouts/application.html.erb
git commit -m "feat: layout con sidebar — flex container condicional"
```

---

## Task 6: Crear `sidebar_controller.js`

**Files:**
- Create: `app/javascript/controllers/sidebar_controller.js`

- [ ] **Step 6.1: Crear el archivo**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav", "backdrop"]

  open() {
    this.navTarget.classList.remove("-translate-x-full")
    this.backdropTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.navTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  toggle() {
    const isOpen = !this.navTarget.classList.contains("-translate-x-full")
    isOpen ? this.close() : this.open()
  }

  // Cerrar cuando se navega (Turbo drive)
  connect() {
    this._boundClose = () => this.close()
    document.addEventListener("turbo:before-visit", this._boundClose)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this._boundClose)
  }
}
```

- [ ] **Step 6.2: Commit**

```bash
git add app/javascript/controllers/sidebar_controller.js
git commit -m "feat: sidebar_controller para toggle mobile drawer"
```

---

## Task 7: Correr los tests y verificar

- [ ] **Step 7.1: Correr el navigation_spec**

```bash
bundle exec rspec spec/requests/navigation_spec.rb --format documentation
```

Expected: todos los specs pasan (verde).

- [ ] **Step 7.2: Correr todos los request specs**

```bash
bundle exec rspec spec/requests/ --format progress
```

Expected: suite completa verde. Si algún spec falla por un cambio en el DOM del nav, revisarlo: el sidebar contiene todos los ítems que el nav horizontal tenía, así que los assertions de texto deberían seguir pasando.

- [ ] **Step 7.3: Correr RuboCop**

```bash
bundle exec rubocop app/helpers/application_helper.rb app/javascript/controllers/sidebar_controller.js
```

Expected: sin offenses. Si hay alguno en el JS (RuboCop no analiza JS, ignorar).

- [ ] **Step 7.4: Commit final si hay ajustes**

```bash
git add -p
git commit -m "fix: ajustes post-tests en sidebar navigation"
```

---

## Criterios de aceptación

- [ ] Sidebar visible en rutas `church_admin/`, `church_pastor/`, `church_member_portal/`
- [ ] Ítem activo correcto al navegar (borde violeta + fondo violet-50)
- [ ] Ítems condicionales aparecen/ocultan según permiso del usuario
- [ ] Badge de solicitudes muestra conteo real (solo cuando > 0)
- [ ] Sin sidebar en páginas fuera de contexto de iglesia
- [ ] En mobile: drawer funcional (hamburger → sidebar aparece → click backdrop → cierra)
- [ ] `bundle exec rspec spec/requests/` verde
- [ ] Sin regresión visual en páginas existentes
