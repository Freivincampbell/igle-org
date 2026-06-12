# Asistencia: ocurrencias, walk-ins y validación de cruce (PR 3 de 3) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development o superpowers:executing-plans. Steps usan checkbox (`- [ ]`).

**Goal:** Que la asistencia se pueda registrar por fecha de ocurrencia (arreglando eventos recurrentes), contar visitantes sin RSVP (walk-ins), sin borrado físico y con auditoría; y que el admin vea la **validación de cruce**: asistencia real vs confirmados, no-shows y espontáneos.

**Architecture:** Fase D del spec [2026-06-11-events-public-flow-design.md](../specs/2026-06-11-events-public-flow-design.md). Tres cambios estructurales en `event_attendances` (`occurrence_date`, `member_id` nullable + `guest_name`, soft-delete) + paper_trail, una acción `update_attendance` que deja de hacer `destroy`, un campo de fecha y de walk-in en la vista existente, y un panel de cruce en el show admin. Branch `feature/events-attendance-checkin`, apilada sobre `feature/events-guest-rsvp` (PR #34).

**Decisión de alcance (YAGNI):** se **mantiene el formulario bulk** de asistencia (checkboxes + un submit), mejorado con selector de fecha y alta de walk-in. El "modo check-in Turbo por persona" del spec se **difiere** como polish de UX: el formulario actual ya registra asistencia y reescribirlo a Turbo Streams es el pedazo de mayor riesgo sin aportar a la pregunta central (contar y validar). Se documenta como follow-up.

**Tech Stack:** Rails 8.1, PostgreSQL, ERB + Tailwind, RSpec. `bundle` SIEMPRE vía `~/.local/share/mise/installs/ruby/3.4.9/bin/bundle exec ...` (abreviado `bundle exec`). Migraciones en test: `RAILS_ENV=test bundle exec rails db:migrate`.

**Reglas del proyecto:** `church_id` + `public_id`; sin `destroy` en operativos (desmarcar = `attended: false`); aislamiento con dos iglesias; paper_trail en acción auditable; UI en español.

---

### Task 1: Migración `occurrence_date` + walk-ins + modelo (TDD)

**Files:**
- Create: `db/migrate/<ts>_add_occurrence_and_walkin_to_event_attendances.rb`
- Modify: `app/models/event_attendance.rb`
- Modify: `spec/factories/events.rb` (factory `event_attendance`)
- Create: `spec/models/event_attendance_spec.rb`

- [ ] **Step 1: Spec del modelo que falla** — crear `spec/models/event_attendance_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe EventAttendance do
  it "es válida con miembro" do
    expect(build(:event_attendance)).to be_valid
  end

  it "es válida como walk-in (sin miembro, con guest_name)" do
    attendance = build(:event_attendance, :walk_in)

    expect(attendance.member).to be_nil
    expect(attendance).to be_valid
  end

  it "requiere miembro o guest_name" do
    expect(build(:event_attendance, member: nil, guest_name: nil)).not_to be_valid
  end

  it "asigna occurrence_date al guardar si viene en blanco (fecha del evento)" do
    event = create(:event, starts_at: Time.zone.parse("2026-07-05 10:00"))
    attendance = create(:event_attendance, event:, church: event.church, occurrence_date: nil)

    expect(attendance.occurrence_date).to eq(Date.new(2026, 7, 5))
  end

  it "permite asistencia del mismo miembro en dos fechas de ocurrencia distintas" do
    event = create(:event, recurring: true, recurrence_frequency: "weekly")
    member = create(:member, church: event.church)
    create(:event_attendance, event:, church: event.church, member:, occurrence_date: Date.new(2026, 7, 5))

    second = build(:event_attendance, event:, church: event.church, member:, occurrence_date: Date.new(2026, 7, 12))

    expect(second).to be_valid
  end

  it "rechaza duplicado del mismo miembro en la misma fecha de ocurrencia" do
    event = create(:event)
    member = create(:member, church: event.church)
    create(:event_attendance, event:, church: event.church, member:, occurrence_date: Date.new(2026, 7, 5))

    dup = build(:event_attendance, event:, church: event.church, member:, occurrence_date: Date.new(2026, 7, 5))

    expect { dup.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "registra versiones con paper_trail" do
    attendance = create(:event_attendance)

    expect(attendance.versions.count).to eq(1)
  end
end
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `bundle exec rspec spec/models/event_attendance_spec.rb`
Expected: FAIL (columnas/validaciones/traits no existen).

- [ ] **Step 3: Migración**

```ruby
class AddOccurrenceAndWalkinToEventAttendances < ActiveRecord::Migration[8.1]
  def up
    add_column :event_attendances, :occurrence_date, :date
    add_column :event_attendances, :guest_name, :string
    change_column_null :event_attendances, :member_id, true

    # Backfill: la fecha de la (única) ocurrencia de cada evento existente.
    execute <<~SQL
      UPDATE event_attendances ea
      SET occurrence_date = (e.starts_at AT TIME ZONE 'UTC')::date
      FROM events e
      WHERE ea.event_id = e.id AND ea.occurrence_date IS NULL
    SQL

    change_column_null :event_attendances, :occurrence_date, false

    remove_index :event_attendances, column: [ :event_id, :member_id ],
      name: "index_event_attendances_on_event_id_and_member_id"
    add_index :event_attendances, [ :event_id, :member_id, :occurrence_date ], unique: true,
      where: "member_id IS NOT NULL",
      name: "index_event_attendances_on_event_member_occurrence"
  end

  def down
    remove_index :event_attendances, name: "index_event_attendances_on_event_member_occurrence"
    add_index :event_attendances, [ :event_id, :member_id ], unique: true,
      name: "index_event_attendances_on_event_id_and_member_id"
    change_column_null :event_attendances, :member_id, false
    remove_column :event_attendances, :occurrence_date
    remove_column :event_attendances, :guest_name
  end
end
```

Run: `RAILS_ENV=test bundle exec rails db:migrate` y confirmar que `db/schema.rb` se actualizó.

- [ ] **Step 4: Modelo** — `app/models/event_attendance.rb` queda:

```ruby
class EventAttendance < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  has_paper_trail skip: %i[updated_at]

  belongs_to :event
  belongs_to :member, optional: true
  belongs_to :checked_in_by, class_name: "User", optional: true

  normalizes :guest_name, with: ->(value) { value.to_s.strip.presence }

  before_validation :assign_occurrence_date, on: :create

  validate :member_or_guest_present
  validate :event_in_same_church
  validate :member_in_same_church

  scope :present, -> { where(attended: true) }

  def attendee_name
    member&.full_name || guest_name
  end

  private

  def assign_occurrence_date
    self.occurrence_date ||= event&.starts_at&.to_date
  end

  def member_or_guest_present
    return if member.present? || guest_name.present?

    errors.add(:base, :attendee_required)
  end

  def event_in_same_church
    return if event.blank? || church.blank?
    return if event.church_id == church_id

    errors.add(:event, :must_belong_to_church)
  end

  def member_in_same_church
    return if member.blank? || church.blank?
    return if member.church_id == church_id

    errors.add(:member, :must_belong_to_church)
  end
end
```

- [ ] **Step 5: Factory** — en `spec/factories/events.rb`, reemplazar la factory `event_attendance` por:

```ruby
  factory :event_attendance do
    association :church
    association :event
    association :member
    attended { true }
    checked_in_at { Time.current }
    occurrence_date { nil }

    after(:build) do |att|
      att.church ||= att.event&.church
      att.event&.update_columns(church_id: att.church_id) if att.event && att.event.church_id != att.church_id
      att.member&.update_columns(church_id: att.church_id) if att.member && att.member.church_id != att.church_id
    end

    trait :walk_in do
      member { nil }
      guest_name { "Visitante" }
    end
  end
```

- [ ] **Step 6: i18n** — en `config/locales/es.yml`, junto a `contact_required` (bajo `activerecord.errors.messages`):

```yaml
        attendee_required: "Indica un miembro o el nombre del visitante"
```

- [ ] **Step 7: Correr y verificar que pasan**

Run: `bundle exec rspec spec/models/event_attendance_spec.rb`
Expected: 7 examples, 0 failures

- [ ] **Step 8: Rubocop + commit**

```bash
bundle exec rubocop app/models/event_attendance.rb db/migrate spec/models/event_attendance_spec.rb spec/factories/events.rb
git add db/ app/models/event_attendance.rb spec/factories/events.rb spec/models/event_attendance_spec.rb config/locales/es.yml
git commit -m "feat: asistencia por fecha de ocurrencia, walk-ins y auditoría"
```

---

### Task 2: `update_attendance` con soft-delete, occurrence_date y walk-in (TDD)

El controlador actual hace `attendance.destroy!` al desmarcar (viola la regla de no borrado) y no maneja fechas ni walk-ins.

**Files:**
- Modify: `spec/requests/church_admin/events_spec.rb` (actualizar el spec de update_attendance + agregar casos)
- Modify: `app/controllers/church_admin/events_controller.rb` (`attendance`, `update_attendance`)

- [ ] **Step 1: Actualizar y agregar specs** — reemplazar el `describe "PATCH update_attendance"` existente por:

```ruby
  describe "PATCH update_attendance" do
    it "marca presentes por public_id y desmarca con soft-delete (sin destroy)" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      event = create(:event, church:)
      member_a = create(:member, church:)
      member_b = create(:member, church:)
      sign_in membership.user

      patch attendance_church_admin_event_path(church, event), params: {
        attendance: { member_ids: [ member_a.public_id ] }
      }
      expect(event.event_attendances.present.pluck(:member_id)).to contain_exactly(member_a.id)

      patch attendance_church_admin_event_path(church, event), params: {
        attendance: { member_ids: [ member_b.public_id ] }
      }
      # member_a queda registrado pero ausente (soft-delete), no se destruye
      expect(event.reload.event_attendances.present.pluck(:member_id)).to contain_exactly(member_b.id)
      expect(event.event_attendances.where(member: member_a).first.attended).to be(false)
      expect(event.event_attendances.count).to eq(2)
    end

    it "registra un walk-in con nombre" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      event = create(:event, church:)
      sign_in membership.user

      patch attendance_church_admin_event_path(church, event), params: {
        attendance: { member_ids: [], walk_in_name: "Ana Visitante" }
      }

      walk_in = event.event_attendances.where(member_id: nil).first
      expect(walk_in.guest_name).to eq("Ana Visitante")
      expect(walk_in.attended).to be(true)
      expect(walk_in.checked_in_by).to eq(membership.user)
    end

    it "usa la fecha de ocurrencia indicada" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      event = create(:event, church:, recurring: true, recurrence_frequency: "weekly")
      member = create(:member, church:)
      sign_in membership.user

      patch attendance_church_admin_event_path(church, event), params: {
        attendance: { member_ids: [ member.public_id ], occurrence_date: "2026-07-12" }
      }

      expect(event.event_attendances.first.occurrence_date).to eq(Date.new(2026, 7, 12))
    end
  end
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `bundle exec rspec spec/requests/church_admin/events_spec.rb -e update_attendance`
Expected: FAIL.

- [ ] **Step 3: Reescribir las acciones** en `app/controllers/church_admin/events_controller.rb`:

```ruby
    def attendance
      authorize @event, :update?
      @occurrence_date = parse_occurrence_date
      @members = @church.members.active.ordered
      @attendances_by_member = @event.event_attendances.where(occurrence_date: @occurrence_date)
        .includes(:member).index_by(&:member_id)
      @confirmed_member_ids = @event.event_rsvps.where(status: "attending").pluck(:member_id).to_set
    end

    def update_attendance
      authorize @event, :update?

      occurrence_date = parse_occurrence_date
      attended_public_ids = Array(params.dig(:attendance, :member_ids)).map(&:to_s)

      Event.transaction do
        @church.members.active.find_each do |member|
          attendance = @event.event_attendances.find_or_initialize_by(member:, church: @church, occurrence_date:)
          if attended_public_ids.include?(member.public_id)
            attendance.attended = true
            attendance.checked_in_at ||= Time.current
            attendance.checked_in_by ||= current_user
          else
            next unless attendance.persisted?

            attendance.attended = false
          end
          attendance.save!
        end

        walk_in_name = params.dig(:attendance, :walk_in_name).to_s.strip
        if walk_in_name.present?
          @event.event_attendances.create!(church: @church, occurrence_date:, guest_name: walk_in_name,
            attended: true, checked_in_at: Time.current, checked_in_by: current_user)
        end
      end

      redirect_to attendance_church_admin_event_path(@church, @event, occurrence_date:),
        notice: t("church_admin.events.attendance_updated")
    end

    private

    def parse_occurrence_date
      Date.parse(params.dig(:attendance, :occurrence_date).to_s)
    rescue ArgumentError, TypeError
      @event.starts_at.to_date
    end
```

(Insertar `parse_occurrence_date` dentro de la sección `private` existente, no duplicar `private`.)

- [ ] **Step 4: Correr y verificar que pasan**

Run: `bundle exec rspec spec/requests/church_admin/events_spec.rb`
Expected: todos verdes.

- [ ] **Step 5: Rubocop + commit**

```bash
bundle exec rubocop app/controllers/church_admin/events_controller.rb spec/requests/church_admin/events_spec.rb
git add app/controllers/church_admin/events_controller.rb spec/requests/church_admin/events_spec.rb
git commit -m "feat: registro de asistencia con soft-delete, fecha de ocurrencia y walk-ins"
```

---

### Task 3: Vista de asistencia — selector de fecha + alta de walk-in

**Files:**
- Modify: `app/views/church_admin/events/attendance.html.erb`

- [ ] **Step 1: Selector de fecha (solo recurrentes) y campo de walk-in**

En `app/views/church_admin/events/attendance.html.erb`, dentro del `form_with`, agregar al inicio (antes del filtro por nombre) un hidden/visible date input según recurrencia:

```erb
    <% if @event.recurring? %>
      <div class="mb-4">
        <label for="attendance_occurrence_date" class="text-xs font-medium uppercase tracking-wide text-slate-500">Fecha de la reunión</label>
        <input type="date" name="attendance[occurrence_date]" id="attendance_occurrence_date"
               value="<%= @occurrence_date.iso8601 %>"
               class="mt-1 block rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-500/20">
      </div>
    <% else %>
      <input type="hidden" name="attendance[occurrence_date]" value="<%= @occurrence_date.iso8601 %>">
    <% end %>
```

Y antes de los botones finales (`mt-6 flex justify-end`), un campo para registrar un visitante:

```erb
    <div class="mt-6 rounded-xl border border-dashed border-slate-300 p-4">
      <label for="attendance_walk_in_name" class="text-xs font-medium uppercase tracking-wide text-slate-500">Agregar visitante (sin cuenta)</label>
      <div class="mt-1 flex gap-2">
        <input type="text" name="attendance[walk_in_name]" id="attendance_walk_in_name" placeholder="Nombre del visitante"
               class="w-full max-w-sm rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-500/20">
      </div>
      <p class="mt-1 text-xs text-slate-400">Se contará como presente al guardar. Para varios, guarda y repite.</p>
    </div>
```

- [ ] **Step 2: Verificación de regresión**

Run: `bundle exec rspec spec/requests/church_admin/events_spec.rb`
Expected: verdes (la vista renderiza para recurrentes y no recurrentes).

- [ ] **Step 3: Commit**

```bash
git add app/views/church_admin/events/attendance.html.erb
git commit -m "feat: selector de fecha y alta de visitante en la vista de asistencia"
```

---

### Task 4: Panel de validación de cruce en el show admin (TDD)

**Files:**
- Modify: `spec/requests/church_admin/events_spec.rb`
- Modify: `app/models/event.rb` (métodos de cruce)
- Modify: `app/controllers/church_admin/events_controller.rb` (`show`)
- Modify: `app/views/church_admin/events/show.html.erb` (reemplazar el card "Asistencia real")

- [ ] **Step 1: Specs del modelo de cruce** — agregar a `spec/models/event_spec.rb` (dentro del describe "conteo de confirmados" o un describe nuevo "validación de asistencia"):

```ruby
  describe "validación de asistencia" do
    it "calcula presentes, no-shows y espontáneos" do
      church = create(:church)
      event = create(:event, church:)
      confirmed_present = create(:member, church:)
      confirmed_absent = create(:member, church:)
      spontaneous = create(:member, church:)

      create(:event_rsvp, church:, event:, member: confirmed_present, status: "attending")
      create(:event_rsvp, church:, event:, member: confirmed_absent, status: "attending")
      create(:event_attendance, church:, event:, member: confirmed_present)
      create(:event_attendance, church:, event:, member: spontaneous)
      create(:event_attendance, :walk_in, church:, event:)

      expect(event.attended_count).to eq(3)            # 2 miembros presentes + 1 walk-in
      expect(event.no_show_member_ids).to contain_exactly(confirmed_absent.id)
      expect(event.spontaneous_count).to eq(2)         # 1 miembro sin RSVP + 1 walk-in
    end
  end
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `bundle exec rspec spec/models/event_spec.rb -e "validación de asistencia"`
Expected: FAIL.

- [ ] **Step 3: Métodos en `app/models/event.rb`** — reemplazar `attended_count` y agregar:

```ruby
  def attended_count
    event_attendances.where(attended: true).count
  end

  def present_member_ids
    @present_member_ids ||= event_attendances.where(attended: true).where.not(member_id: nil).distinct.pluck(:member_id).to_set
  end

  def confirmed_member_ids
    @confirmed_member_ids ||= event_rsvps.where(status: "attending").pluck(:member_id).to_set
  end

  def no_show_member_ids
    confirmed_member_ids - present_member_ids
  end

  def spontaneous_count
    member_spontaneous = (present_member_ids - confirmed_member_ids).size
    walk_in_count = event_attendances.where(attended: true, member_id: nil).count
    member_spontaneous + walk_in_count
  end

  def no_show_rate
    return 0 if confirmed_member_ids.empty?

    (no_show_member_ids.size * 100.0 / confirmed_member_ids.size).round
  end
```

(`attended_count` ya existía con el mismo cuerpo; mantener una sola definición.)

- [ ] **Step 4: Controller `show`** — agregar la carga de no-shows con nombres:

```ruby
    def show
      authorize @event
      @rsvps = @event.event_rsvps.includes(:member)
      @attendances = @event.event_attendances.includes(:member)
      @guest_rsvps = @event.event_guest_rsvps.where(status: "attending").order(:name)
      @no_show_members = @church.members.where(id: @event.no_show_member_ids).ordered
    end
```

- [ ] **Step 5: Vista — reemplazar el card "Asistencia real"** en `app/views/church_admin/events/show.html.erb`:

```erb
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-card">
      <h2 class="text-base font-semibold text-slate-900">Asistencia</h2>
      <p class="mt-2 text-3xl font-bold text-slate-900"><%= @event.attended_count %></p>
      <p class="text-xs text-slate-500">Presentes reales (de <%= @event.confirmed_attendees_count %> confirmados)</p>

      <div class="mt-4 grid grid-cols-2 gap-3 text-sm">
        <div class="rounded-lg bg-amber-50 px-3 py-2 ring-1 ring-amber-100">
          <p class="text-xs font-medium uppercase tracking-wide text-amber-600">No-shows</p>
          <p class="text-lg font-bold text-amber-700"><%= @event.no_show_member_ids.size %></p>
          <p class="text-xs text-amber-600"><%= @event.no_show_rate %>% de los confirmados</p>
        </div>
        <div class="rounded-lg bg-sky-50 px-3 py-2 ring-1 ring-sky-100">
          <p class="text-xs font-medium uppercase tracking-wide text-sky-600">Espontáneos</p>
          <p class="text-lg font-bold text-sky-700"><%= @event.spontaneous_count %></p>
          <p class="text-xs text-sky-600">Presentes sin confirmar</p>
        </div>
      </div>

      <% if @no_show_members.any? %>
        <h3 class="mt-5 text-xs font-medium uppercase tracking-wide text-slate-500">No asistieron (confirmados)</h3>
        <ul class="mt-2 space-y-1 text-sm text-slate-600">
          <% @no_show_members.each do |member| %>
            <li><%= member.full_name %></li>
          <% end %>
        </ul>
      <% end %>
    </div>
```

- [ ] **Step 6: Correr specs + verificar**

Run: `bundle exec rspec spec/models/event_spec.rb spec/requests/church_admin/events_spec.rb`
Expected: verdes.

- [ ] **Step 7: Rubocop + commit**

```bash
bundle exec rubocop app/models/event.rb app/controllers/church_admin/events_controller.rb spec/models/event_spec.rb
git add app/models/event.rb app/controllers/church_admin/events_controller.rb app/views/church_admin/events/show.html.erb spec/models/event_spec.rb
git commit -m "feat: validación de asistencia con no-shows, espontáneos y tasa de no-show"
```

---

### Task 5: Verificación final

- [ ] **Step 1:** `bundle exec rspec` → 0 failures
- [ ] **Step 2:** `bundle exec rubocop` → no offenses
- [ ] **Step 3:** `bundle exec brakeman --no-pager` → 0 warnings
- [ ] **Step 4: Reglas:** sin `destroy` en `event_attendances` (grep el controlador); `occurrence_date` siempre presente; walk-ins sin `member_id` no rompen aislamiento (siguen con `church_id`).
- [ ] **Step 5: Manual (`bin/dev`):** registrar asistencia en un evento recurrente con fecha; agregar un walk-in; ver el panel de cruce (no-shows + espontáneos) en el show.

## Follow-ups (fuera de este PR)

- Modo check-in Turbo por persona (marcar de a uno sin submit; diferido por riesgo/alcance).
- Reporte de cruce por ocurrencia específica en eventos recurrentes (hoy el panel agrega a nivel evento).
- Zona horaria por iglesia en `occurrence_date`/horas (tarea transversal ya anotada).
- Spec del límite de 6 eventos del listado público (heredado del review de Fase A).
