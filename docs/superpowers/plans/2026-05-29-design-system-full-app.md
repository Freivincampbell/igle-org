# Design System — Full App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the igle·org Soft UI Evolution design system to all remaining ~70 ERB view files.

**Architecture:** Systematic transformation of Tailwind classes across all views: violet-600 primary, Plus Jakarta Sans font (already loaded), rounded-xl cards with shadow-card, violet focus states on inputs, consistent page header pattern, polished empty states and action buttons.

**Tech Stack:** Rails 8, Tailwind CSS v4, Hotwire/Turbo, ERB templates.

---

## Design System Token Reference

These are the EXACT transformations to apply in every file:

### Input fields (ALL text/email/password/select/date/number/tel/url/textarea fields)
```
OLD focus: focus:border-slate-500 focus:outline-none focus:ring-1 focus:ring-slate-500
NEW focus: focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-500/20
OLD border: border border-slate-300
NEW border: border border-slate-300  (keep same)
```

### Submit / Primary buttons
```
OLD: rounded-md bg-slate-950 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800
NEW: rounded-lg bg-violet-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-violet-700 transition-colors cursor-pointer
```

### Cancel / Secondary link buttons
```
OLD: rounded-md border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50
NEW: rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors
```

### "Nuevo X" primary link buttons
```
OLD: rounded-md bg-slate-950 px-4 py-2 text-sm font-medium text-white hover:bg-slate-800
NEW: inline-flex items-center gap-1.5 rounded-lg bg-violet-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-violet-700 transition-colors
```

### Cards / sections
```
OLD: rounded-lg border border-slate-200 bg-white p-6
NEW: rounded-xl border border-slate-200 bg-white p-6 shadow-card
OLD: overflow-hidden rounded-lg border border-slate-200 bg-white
NEW: overflow-hidden rounded-xl border border-slate-200 bg-white shadow-card
```

### Page header subtitle (context label above title)
```
OLD: text-sm font-medium text-slate-500  (or similar)
NEW: text-xs font-semibold uppercase tracking-widest text-violet-500
```

### Page main title
```
OLD: text-3xl font-semibold text-slate-950  (or text-2xl)
NEW: text-2xl font-bold text-slate-900
```

### Section card titles (h2 inside cards)
```
OLD: text-lg font-semibold text-slate-950
NEW: text-base font-semibold text-slate-900
```

### Avatar fallback circles
```
OLD: bg-slate-100 text-slate-400
NEW: bg-violet-100 text-violet-700
```

### Error blocks (keep red but modernize)
```
OLD: rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800
NEW: rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800
```

### Table containers
```
OLD: overflow-hidden rounded-lg border border-slate-200 bg-white
NEW: overflow-hidden rounded-xl border border-slate-200 bg-white shadow-card
```

### Table row action links (Ver / Editar)
```
OLD: font-medium text-slate-600 hover:text-slate-950
NEW: rounded-md bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700 hover:bg-violet-50 hover:text-violet-700 transition-colors
```

### File upload buttons
```
OLD: file:bg-slate-950 ... hover:file:bg-slate-800
NEW: file:bg-violet-600 file:text-white file:rounded-md file:border-0 file:px-3 file:py-1.5 file:text-sm file:font-medium hover:file:bg-violet-700 file:cursor-pointer file:transition-colors
```

---

## Files to Update (grouped by task)

### Task 1: Devise Auth Pages
- `app/views/devise/passwords/new.html.erb`
- `app/views/devise/passwords/edit.html.erb`

### Task 2: Churches Show + Platform views
- `app/views/churches/show.html.erb`
- `app/views/platform/churches/index.html.erb`
- `app/views/platform/churches/show.html.erb`
- `app/views/platform/churches/new.html.erb`
- `app/views/platform/churches/edit.html.erb`
- `app/views/platform/churches/_form.html.erb`
- `app/views/platform/church_memberships/new.html.erb`

### Task 3: ChurchAdmin Members (show, new, edit, _form)
- `app/views/church_admin/members/show.html.erb`
- `app/views/church_admin/members/new.html.erb`
- `app/views/church_admin/members/edit.html.erb`
- `app/views/church_admin/members/_form.html.erb`

### Task 4: ChurchAdmin Ministries
- `app/views/church_admin/ministries/index.html.erb`
- `app/views/church_admin/ministries/show.html.erb`
- `app/views/church_admin/ministries/new.html.erb`
- `app/views/church_admin/ministries/edit.html.erb`
- `app/views/church_admin/ministries/_form.html.erb`

### Task 5: ChurchAdmin Events
- `app/views/church_admin/events/index.html.erb`
- `app/views/church_admin/events/show.html.erb`
- `app/views/church_admin/events/new.html.erb`
- `app/views/church_admin/events/edit.html.erb`
- `app/views/church_admin/events/_form.html.erb`
- `app/views/church_admin/events/attendance.html.erb`
- `app/views/church_admin/events/_attendance_row.html.erb`

### Task 6: ChurchAdmin Families + Boards
- `app/views/church_admin/families/index.html.erb`
- `app/views/church_admin/families/show.html.erb`
- `app/views/church_admin/families/new.html.erb`
- `app/views/church_admin/families/edit.html.erb`
- `app/views/church_admin/families/_form.html.erb`
- `app/views/church_admin/boards/index.html.erb`
- `app/views/church_admin/boards/show.html.erb`
- `app/views/church_admin/boards/new.html.erb`
- `app/views/church_admin/boards/edit.html.erb`
- `app/views/church_admin/boards/_form.html.erb`

### Task 7: ChurchAdmin Roles + ChurchMemberships
- `app/views/church_admin/roles/index.html.erb`
- `app/views/church_admin/roles/show.html.erb`
- `app/views/church_admin/roles/new.html.erb`
- `app/views/church_admin/roles/edit.html.erb`
- `app/views/church_admin/roles/_form.html.erb`
- `app/views/church_admin/roles/_permission_matrix.html.erb`
- `app/views/church_admin/church_memberships/index.html.erb`
- `app/views/church_admin/church_memberships/new.html.erb`
- `app/views/church_admin/church_memberships/edit.html.erb`

### Task 8: ChurchAdmin Catalogs (service_times, skills, occupations, member_skills, member_occupations)
- `app/views/church_admin/service_times/index.html.erb`
- `app/views/church_admin/service_times/new.html.erb`
- `app/views/church_admin/service_times/edit.html.erb`
- `app/views/church_admin/service_times/_form.html.erb`
- `app/views/church_admin/skills/index.html.erb`
- `app/views/church_admin/skills/new.html.erb`
- `app/views/church_admin/skills/edit.html.erb`
- `app/views/church_admin/skills/_form.html.erb`
- `app/views/church_admin/occupations/index.html.erb`
- `app/views/church_admin/occupations/new.html.erb`
- `app/views/church_admin/occupations/edit.html.erb`
- `app/views/church_admin/occupations/_form.html.erb`
- `app/views/church_admin/member_skills/new.html.erb`
- `app/views/church_admin/member_skills/edit.html.erb`
- `app/views/church_admin/member_skills/_form.html.erb`
- `app/views/church_admin/member_occupations/new.html.erb`
- `app/views/church_admin/member_occupations/edit.html.erb`
- `app/views/church_admin/member_occupations/_form.html.erb`

### Task 9: ChurchAdmin Operations (service_directory, reports, settings, profile_change_requests)
- `app/views/church_admin/service_directory/index.html.erb`
- `app/views/church_admin/reports/index.html.erb`
- `app/views/church_admin/reports/show.html.erb`
- `app/views/church_admin/settings/show.html.erb`
- `app/views/church_admin/profile_change_requests/index.html.erb`
- `app/views/church_admin/profile_change_requests/show.html.erb`

### Task 10: Pastor + MinistryLeader + MemberPortal + Public + Shared
- `app/views/pastor/pastoral_notes/index.html.erb`
- `app/views/pastor/pastoral_notes/show.html.erb`
- `app/views/pastor/pastoral_notes/new.html.erb`
- `app/views/pastor/pastoral_notes/edit.html.erb`
- `app/views/pastor/pastoral_notes/_form.html.erb`
- `app/views/pastor/members/index.html.erb`
- `app/views/pastor/members/show.html.erb`
- `app/views/ministry_leader/events/index.html.erb`
- `app/views/ministry_leader/events/show.html.erb`
- `app/views/ministry_leader/ministries/index.html.erb`
- `app/views/ministry_leader/ministries/show.html.erb`
- `app/views/member_portal/profiles/show.html.erb`
- `app/views/member_portal/events/index.html.erb`
- `app/views/member_portal/events/show.html.erb`
- `app/views/member_portal/profile_change_requests/new.html.erb`
- `app/views/public/churches/show.html.erb`
- `app/views/shared/_member_tag.html.erb`

---

## Execution Steps

- [ ] **Step 1:** Execute Tasks 1-10 via parallel workflow agents, each reading the files in its group and rewriting them with the design system tokens above.
- [ ] **Step 2:** Compile Tailwind CSS to verify no class errors: `docker compose exec web bin/rails tailwindcss:build`
- [ ] **Step 3:** Smoke-test key pages with curl to verify no render errors.
- [ ] **Step 4:** Commit all changes.
