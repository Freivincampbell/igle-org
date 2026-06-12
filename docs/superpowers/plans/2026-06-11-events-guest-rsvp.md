# RSVP de invitados + panel de conteo (PR 2 de 3) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Visitantes sin cuenta confirman asistencia a eventos públicos (con token para editar/cancelar), y el admin ve un panel de conteo con desglose e invitados.

**Architecture:** Fases B+C del spec [2026-06-11-events-public-flow-design.md](../specs/2026-06-11-events-public-flow-design.md). Tabla nueva `event_guest_rsvps` (multi-tenant, soft-cancel, `access_token` como capacidad de edición), servicio `Events::GuestRsvpRegistration` (crear/actualizar con validación de cupo), controller público con honeypot + throttle por IP, y panel de conteo en el show admin. Branch `feature/events-guest-rsvp`, apilada sobre `feature/events-public-flow` (PR #33).

**Tech Stack:** Rails 8.1, PostgreSQL, ERB + Tailwind, RSpec. `bundle` SIEMPRE vía `~/.local/share/mise/installs/ruby/3.4.9/bin/bundle exec ...` (abajo abreviado `bundle exec`).

**Reglas del proyecto:** `church_id` + `public_id` en la tabla nueva; sin borrado físico (cancelar = status); specs de aislamiento con dos iglesias; paper_trail en acciones auditables; UI en español.

---

### Task 1: Migración + modelo `EventGuestRsvp` + factory (TDD)

**Files:**
- Create: `db/migrate/<timestamp>_create_event_guest_rsvps.rb` (generar con `bin/rails g migration` o crear a mano con timestamp actual)
- Create: `app/models/event_guest_rsvp.rb`
- Create: `spec/factories/event_guest_rsvps.rb`
- Create: `spec/models/event_guest_rsvp_spec.rb`

- [ ] **Step 1: Specs del modelo que fallan**

Crear `spec/models/event_guest_rsvp_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe EventGuestRsvp do
  it "es válido con los atributos de la factory" do
    expect(build(:event_guest_rsvp)).to be_valid
  end

  it "genera public_id UUID y access_token al crear" do
    rsvp = create(:event_guest_rsvp)

    expect(rsvp.public_id).to match(PublicIdentifiable::UUID_FORMAT)
    expect(rsvp.to_param).to eq(rsvp.public_id)
    expect(rsvp.access_token).to be_present
  end

  it "requiere nombre" do
    expect(build(:event_guest_rsvp, name: nil)).not_to be_valid
  end

  it "requiere email o teléfono" do
    expect(build(:event_guest_rsvp, email: nil, phone: nil)).not_to be_valid
    expect(build(:event_guest_rsvp, email: nil, phone: "8888-8888")).to be_valid
    expect(build(:event_guest_rsvp, email: "ana@example.com", phone: nil)).to be_valid
  end

  it "normaliza el email a minúsculas" do
    rsvp = create(:event_guest_rsvp, email: " Ana@Example.COM ")

    expect(rsvp.email).to eq("ana@example.com")
  end

  it "rechaza guests_count negativo" do
    expect(build(:event_guest_rsvp, guests_count: -1)).not_to be_valid
  end

  it "rechaza un evento de otra iglesia (aislamiento)" do
    church_a = create(:church)
    church_b = create(:church)
    event_b = create(:event, church: church_b, visibility: "public")

    rsvp = build(:event_guest_rsvp, church: church_a, event: event_b)

    expect(rsvp).not_to be_valid
  end

  it "no permite dos RSVPs con el mismo email en el mismo evento" do
    existing = create(:event_guest_rsvp, email: "ana@example.com")
    duplicate = build(:event_guest_rsvp, event: existing.event, church: existing.church,
                      email: "ANA@example.com")

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "registra versiones con paper_trail", versioning: true do
    rsvp = create(:event_guest_rsvp)

    expect(rsvp.versions.count).to eq(1)
  end
end
```

Nota: si el proyecto no tiene el tag `versioning: true` configurado en `spec/support`, revisar cómo lo activan los specs de `Member` (que usa paper_trail) y replicarlo; si no existe ninguno, agregar `PaperTrail.enabled = false` global + `config.around(:each, versioning: true)` que lo habilite, en `spec/support/paper_trail.rb`.

- [ ] **Step 2: Correr y verificar que fallan**

Run: `bundle exec rspec spec/models/event_guest_rsvp_spec.rb`
Expected: FAIL (constante EventGuestRsvp no existe).

- [ ] **Step 3: Crear la migración**

```ruby
class CreateEventGuestRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :event_guest_rsvps do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true

      t.string :name, null: false
      t.string :email
      t.string :phone
      t.integer :guests_count, null: false, default: 0
      t.string :status, null: false, default: "attending"
      t.string :access_token, null: false

      t.timestamps
    end

    add_index :event_guest_rsvps, :public_id, unique: true
    add_index :event_guest_rsvps, :access_token, unique: true
    add_index :event_guest_rsvps, "event_id, lower(email)", unique: true,
      where: "email IS NOT NULL",
      name: "index_event_guest_rsvps_on_event_and_lower_email"
    add_index :event_guest_rsvps, [ :church_id, :status ]
  end
end
```

Run: `bundle exec rails db:migrate` (y verificar que `db/schema.rb` se actualizó).

- [ ] **Step 4: Crear el modelo**

`app/models/event_guest_rsvp.rb`:

```ruby
class EventGuestRsvp < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  has_paper_trail skip: %i[updated_at]

  GUEST_RSVP_STATUSES = %w[attending cancelled].freeze

  belongs_to :event

  has_secure_token :access_token

  enum :status, GUEST_RSVP_STATUSES.index_with(&:itself), validate: true

  normalizes :name, with: ->(value) { value.to_s.strip.presence }
  normalizes :email, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :phone, with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true
  validates :guests_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :email_or_phone_present
  validate :event_in_same_church

  private

  def email_or_phone_present
    return if email.present? || phone.present?

    errors.add(:base, :contact_required)
  end

  def event_in_same_church
    return if event.blank? || church.blank?
    return if event.church_id == church_id

    errors.add(:event, :must_belong_to_church)
  end
end
```

- [ ] **Step 5: Crear la factory**

`spec/factories/event_guest_rsvps.rb`:

```ruby
FactoryBot.define do
  factory :event_guest_rsvp do
    association :church
    event { association(:event, church:, visibility: "public") }
    sequence(:name) { |n| "Invitado #{n}" }
    sequence(:email) { |n| "invitado#{n}@example.com" }
    guests_count { 0 }
    status { "attending" }

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
```

- [ ] **Step 6: i18n del error de contacto**

En `config/locales/es.yml`, bajo `activerecord.errors.models` (seguir la estructura existente del archivo; si los modelos usan `errors.messages` genéricos, ubicar igual que `must_belong_to_church`):

```yaml
      event_guest_rsvp:
        attributes:
          base:
            contact_required: "Debes indicar un email o un teléfono"
```

Verificar dónde está definido `must_belong_to_church` (`grep -n "must_belong_to_church" config/locales/es.yml`) y colocar la clave nueva de forma consistente.

- [ ] **Step 7: Correr y verificar que pasan**

Run: `bundle exec rspec spec/models/event_guest_rsvp_spec.rb`
Expected: 9 examples, 0 failures

- [ ] **Step 8: Commit**

```bash
git add db/ app/models/event_guest_rsvp.rb spec/factories/event_guest_rsvps.rb spec/models/event_guest_rsvp_spec.rb config/locales/es.yml spec/support/ 2>/dev/null || true
git commit -m "feat: modelo EventGuestRsvp con access_token y soft-cancel"
```

---

### Task 2: `Event#confirmed_attendees_count` suma invitados (+ desglose y memoización)

**Files:**
- Modify: `app/models/event.rb`
- Modify: `spec/models/event_spec.rb`

- [ ] **Step 1: Specs que fallan** (agregar al final del describe en `spec/models/event_spec.rb`):

```ruby
  describe "conteo de confirmados" do
    it "suma miembros, acompañantes e invitados confirmados" do
      church = create(:church)
      event = create(:event, church:, visibility: "public")
      create(:event_rsvp, church:, event:, status: "attending", guests_count: 2)   # 3
      create(:event_rsvp, church:, event:, status: "maybe", guests_count: 5)       # 0
      create(:event_guest_rsvp, church:, event:, guests_count: 1)                  # 2
      create(:event_guest_rsvp, :cancelled, church:, event:)                       # 0

      expect(event.confirmed_attendees_count).to eq(5)
      expect(event.member_attending_count).to eq(1)
      expect(event.member_guests_count).to eq(2)
      expect(event.guest_attendees_count).to eq(2)
      expect(event.maybe_count).to eq(1)
      expect(event.not_attending_count).to eq(0)
    end
  end
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `bundle exec rspec spec/models/event_spec.rb`
Expected: FAIL (métodos no existen / conteo viejo).

- [ ] **Step 3: Implementar en `app/models/event.rb`**

Agregar `has_many :event_guest_rsvps, dependent: :destroy` junto a los otros has_many, y reemplazar `confirmed_attendees_count` por:

```ruby
  def confirmed_attendees_count
    @confirmed_attendees_count ||= member_attending_count + member_guests_count + guest_attendees_count
  end

  def member_attending_count
    event_rsvps.where(status: "attending").count
  end

  def member_guests_count
    event_rsvps.where(status: "attending").sum(:guests_count)
  end

  def guest_attendees_count
    event_guest_rsvps.where(status: "attending").sum("guests_count + 1")
  end

  def maybe_count
    event_rsvps.where(status: "maybe").count
  end

  def not_attending_count
    event_rsvps.where(status: "not_attending").count
  end
```

(La memoización resuelve el hallazgo del review del PR 1: la vista pública lo llama dos veces.)

- [ ] **Step 4: Correr specs del modelo + públicos (regresión del detalle público)**

Run: `bundle exec rspec spec/models/event_spec.rb spec/requests/public/`
Expected: todos verdes.

- [ ] **Step 5: Commit**

```bash
git add app/models/event.rb spec/models/event_spec.rb
git commit -m "feat: conteo de confirmados con invitados y desglose por tipo"
```

---

### Task 3: Servicio `Events::GuestRsvpRegistration` (TDD)

**Files:**
- Create: `app/services/events/guest_rsvp_registration.rb`
- Create: `spec/services/events/guest_rsvp_registration_spec.rb`

- [ ] **Step 1: Specs que fallan**

```ruby
require "rails_helper"

RSpec.describe Events::GuestRsvpRegistration do
  def build_event(capacity: nil)
    create(:event, visibility: "public", status: "scheduled", capacity:)
  end

  it "crea un RSVP de invitado attending" do
    event = build_event

    registration = described_class.new(event:, name: "Ana Mora", email: "ana@example.com", guests_count: 2)

    expect(registration.save).to be(true)
    rsvp = registration.guest_rsvp
    expect(rsvp).to be_persisted
    expect(rsvp.church_id).to eq(event.church_id)
    expect(rsvp).to be_attending
    expect(rsvp.guests_count).to eq(2)
  end

  it "actualiza el RSVP existente del mismo email en lugar de duplicar" do
    event = build_event
    existing = create(:event_guest_rsvp, event:, church: event.church, email: "ana@example.com", guests_count: 0)

    registration = described_class.new(event:, name: "Ana Mora", email: "ANA@example.com ", guests_count: 3)

    expect { registration.save }.not_to change(EventGuestRsvp, :count)
    expect(existing.reload.guests_count).to eq(3)
    expect(existing.reload).to be_attending
  end

  it "reactiva un RSVP cancelado validando cupo" do
    event = build_event
    cancelled = create(:event_guest_rsvp, :cancelled, event:, church: event.church, email: "ana@example.com")

    registration = described_class.new(event:, name: cancelled.name, email: "ana@example.com", guests_count: 0)

    expect(registration.save).to be(true)
    expect(cancelled.reload).to be_attending
  end

  it "rechaza cuando no hay cupo suficiente" do
    event = build_event(capacity: 3)
    create(:event_rsvp, church: event.church, event:, status: "attending", guests_count: 1) # ocupa 2

    registration = described_class.new(event:, name: "Ana", email: "ana@example.com", guests_count: 1) # pide 2

    expect(registration.save).to be(false)
    expect(registration.errors[:base]).to be_present
    expect(EventGuestRsvp.count).to eq(0)
  end

  it "permite editar un RSVP existente sin contarse a sí mismo en el cupo" do
    event = build_event(capacity: 2)
    existing = create(:event_guest_rsvp, event:, church: event.church, email: "ana@example.com", guests_count: 1) # ocupa 2

    registration = described_class.new(event:, guest_rsvp: existing, name: existing.name,
                                       email: existing.email, guests_count: 1)

    expect(registration.save).to be(true)
  end

  it "rechaza eventos no programados" do
    event = create(:event, visibility: "public", status: "cancelled")

    registration = described_class.new(event:, name: "Ana", email: "ana@example.com", guests_count: 0)

    expect(registration.save).to be(false)
  end

  it "propaga errores de validación del modelo" do
    event = build_event

    registration = described_class.new(event:, name: "", email: "ana@example.com", guests_count: 0)

    expect(registration.save).to be(false)
    expect(registration.errors[:base]).to be_present
  end
end
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `bundle exec rspec spec/services/events/guest_rsvp_registration_spec.rb`
Expected: FAIL (clase no existe).

- [ ] **Step 3: Implementar el servicio**

`app/services/events/guest_rsvp_registration.rb` (mismo estilo que `Ministries::MemberAssignment`):

```ruby
module Events
  class GuestRsvpRegistration
    include ActiveModel::Model

    attr_accessor :event, :guest_rsvp, :name, :email, :phone, :guests_count

    validates :event, presence: true
    validate :event_is_open_for_rsvp
    validate :capacity_available

    def save
      return false unless valid?

      record = guest_rsvp || existing_by_email || event.event_guest_rsvps.new(church: event.church)
      record.assign_attributes(name:, email:, phone:, guests_count: normalized_guests_count, status: "attending")

      if record.save
        @guest_rsvp = record
        true
      else
        errors.add(:base, record.errors.full_messages.to_sentence)
        false
      end
    end

    private

    def normalized_guests_count
      guests_count.to_i
    end

    def existing_by_email
      normalized_email = email.to_s.strip.downcase
      return if normalized_email.blank?

      event.event_guest_rsvps.find_by(email: normalized_email)
    end

    def event_is_open_for_rsvp
      return if event.blank?
      return if event.scheduled? && event.visibility_public?

      errors.add(:base, :event_not_open)
    end

    def capacity_available
      return if event.blank? || event.capacity.blank?

      record = guest_rsvp || existing_by_email
      already_counted = record&.attending? ? record.guests_count + 1 : 0
      requested = normalized_guests_count + 1

      return if event.confirmed_attendees_count - already_counted + requested <= event.capacity

      errors.add(:base, :no_capacity)
    end
  end
end
```

- [ ] **Step 4: i18n de los errores del servicio**

En `config/locales/es.yml` (buscar dónde viven los mensajes de otros servicios/modelos con `errors.add(:base, :symbol)`; si usan `activemodel.errors`, agregar ahí):

```yaml
  activemodel:
    errors:
      models:
        events/guest_rsvp_registration:
          attributes:
            base:
              event_not_open: "Este evento no acepta confirmaciones."
              no_capacity: "No hay cupos suficientes para esa cantidad de personas."
```

(Si ya existe un bloque `activemodel:`, fusionar dentro del existente.)

- [ ] **Step 5: Correr y verificar que pasan**

Run: `bundle exec rspec spec/services/events/guest_rsvp_registration_spec.rb`
Expected: 7 examples, 0 failures

- [ ] **Step 6: Commit**

```bash
git add app/services/events/ spec/services/events/ config/locales/es.yml
git commit -m "feat: servicio de registro de RSVP de invitado con validación de cupo"
```

---

### Task 4: Rutas + `Public::GuestRsvpsController#create` + formulario público (TDD)

**Files:**
- Create: `spec/requests/public/guest_rsvps_spec.rb`
- Create: `app/controllers/public/guest_rsvps_controller.rb`
- Modify: `config/routes.rb` (dentro del scope `/c/:slug` existente)
- Modify: `app/views/public/events/show.html.erb` (formulario)

- [ ] **Step 1: Request specs que fallan**

Crear `spec/requests/public/guest_rsvps_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Public guest RSVPs" do
  def public_church(slug: "central")
    create(:church, slug:, public_page_enabled: true, status: "active")
  end

  def valid_params(overrides = {})
    { guest_rsvp: { name: "Ana Mora", email: "ana@example.com", phone: "", guests_count: 1 }.merge(overrides) }
  end

  describe "POST /c/:slug/eventos/:public_id/rsvp" do
    it "crea el RSVP y redirige a la página del token" do
      church = public_church
      event = create(:event, church:, visibility: "public")

      expect {
        post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp", params: valid_params
      }.to change(EventGuestRsvp, :count).by(1)

      rsvp = EventGuestRsvp.last
      expect(rsvp.church).to eq(church)
      expect(response).to redirect_to("/c/#{church.slug}/rsvp/#{rsvp.access_token}")
    end

    it "descarta silenciosamente cuando el honeypot viene lleno" do
      church = public_church
      event = create(:event, church:, visibility: "public")

      expect {
        post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp",
             params: valid_params.merge(website: "spam")
      }.not_to change(EventGuestRsvp, :count)

      expect(response).to redirect_to("/c/#{church.slug}/eventos/#{event.public_id}")
    end

    it "404 en eventos members_only" do
      church = public_church
      event = create(:event, church:, visibility: "members_only")

      post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp", params: valid_params

      expect(response).to have_http_status(:not_found)
    end

    it "404 en eventos cancelados" do
      church = public_church
      event = create(:event, church:, visibility: "public", status: "cancelled")

      post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp", params: valid_params

      expect(response).to have_http_status(:not_found)
    end

    it "rechaza cuando no hay cupo y re-renderiza con el error" do
      church = public_church
      event = create(:event, church:, visibility: "public", capacity: 1)

      post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp", params: valid_params(guests_count: 5)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("No hay cupos suficientes")
      expect(EventGuestRsvp.count).to eq(0)
    end

    it "404 con evento de otra iglesia bajo el slug (aislamiento)" do
      church_a = public_church(slug: "iglesia-a")
      church_b = public_church(slug: "iglesia-b")
      event_b = create(:event, church: church_b, visibility: "public")

      post "/c/#{church_a.slug}/eventos/#{event_b.public_id}/rsvp", params: valid_params

      expect(response).to have_http_status(:not_found)
      expect(EventGuestRsvp.count).to eq(0)
    end

    it "aplica throttle por IP cuando se excede el límite" do
      church = public_church
      event = create(:event, church:, visibility: "public")
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)

      6.times do |i|
        post "/c/#{church.slug}/eventos/#{event.public_id}/rsvp",
             params: valid_params(email: "ana#{i}@example.com")
      end

      expect(EventGuestRsvp.count).to eq(5)
      expect(response).to redirect_to("/c/#{church.slug}/eventos/#{event.public_id}")
      follow_redirect!
      expect(response.body).to include("Demasiados intentos")
    end
  end
end
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `bundle exec rspec spec/requests/public/guest_rsvps_spec.rb`
Expected: FAIL (ruta no existe).

- [ ] **Step 3: Rutas** — en `config/routes.rb`, el scope público queda:

```ruby
scope "/c/:slug", module: :public, as: :public_church do
  resources :events, path: "eventos", param: :public_id, only: :show do
    resource :guest_rsvp, path: "rsvp", only: :create
  end
  resources :guest_rsvps, path: "rsvp", param: :access_token, only: %i[show update]
end
```

(El `resources :guest_rsvps` de la segunda línea se usa en Task 5; agregarlo ya para no tocar rutas dos veces.)

- [ ] **Step 4: Controller** — `app/controllers/public/guest_rsvps_controller.rb`:

```ruby
module Public
  class GuestRsvpsController < BaseController
    THROTTLE_LIMIT = 5
    THROTTLE_PERIOD = 10.minutes

    def create
      resolve_public_church!
      @event = @church.events.visibility_public.where(status: "scheduled")
        .find_by_public_id!(params[:event_public_id])

      return redirect_to event_path_for(@event), notice: t("public.guest_rsvps.received") if honeypot_triggered?
      return redirect_to event_path_for(@event), alert: t("public.guest_rsvps.throttled") if throttled?

      registration = Events::GuestRsvpRegistration.new(event: @event, **guest_rsvp_params.to_h.symbolize_keys)

      if registration.save
        redirect_to public_church_guest_rsvp_path(@church.slug, registration.guest_rsvp.access_token),
                    notice: t("public.guest_rsvps.created")
      else
        @guest_rsvp_errors = registration.errors.full_messages
        render "public/events/show", status: :unprocessable_content
      end
    end

    private

    def guest_rsvp_params
      params.fetch(:guest_rsvp, {}).permit(:name, :email, :phone, :guests_count)
    end

    def event_path_for(event)
      public_church_event_path(@church.slug, event)
    end

    # Campo oculto para humanos; si viene lleno es un bot. Se responde como
    # éxito para no darle señal.
    def honeypot_triggered?
      params[:website].present?
    end

    def throttled?
      key = "guest_rsvp_throttle:#{@church.id}:#{request.remote_ip}"
      count = Rails.cache.increment(key, 1, expires_in: THROTTLE_PERIOD)
      count.present? && count > THROTTLE_LIMIT
    end
  end
end
```

- [ ] **Step 5: Formulario en la vista pública del evento**

En `app/views/public/events/show.html.erb`, después del cierre del card de detalles (`</div>` del card) y antes de `</section>`:

```erb
  <% if @event.scheduled? %>
    <div class="mt-8 rounded-xl border border-slate-200 bg-white p-6 shadow-card" id="rsvp">
      <h2 class="text-base font-semibold text-slate-900">Confirma tu asistencia</h2>
      <p class="mt-1 text-sm text-slate-500">No necesitas cuenta. Te daremos un enlace para editar o cancelar tu confirmación.</p>

      <% if defined?(@guest_rsvp_errors) && @guest_rsvp_errors.present? %>
        <div class="mt-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800">
          <ul class="list-disc pl-5">
            <% @guest_rsvp_errors.each do |message| %>
              <li><%= message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <%= form_with url: public_church_event_guest_rsvp_path(@church.slug, @event), method: :post, class: "mt-4 grid gap-4 sm:grid-cols-2" do %>
        <div class="hidden" aria-hidden="true">
          <label for="website">No llenar este campo</label>
          <input type="text" name="website" id="website" tabindex="-1" autocomplete="off">
        </div>

        <div>
          <label for="guest_rsvp_name" class="text-xs font-medium uppercase tracking-wide text-slate-500">Nombre *</label>
          <input type="text" name="guest_rsvp[name]" id="guest_rsvp_name" required
                 value="<%= params.dig(:guest_rsvp, :name) %>"
                 class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-200">
        </div>
        <div>
          <label for="guest_rsvp_guests_count" class="text-xs font-medium uppercase tracking-wide text-slate-500">Acompañantes</label>
          <input type="number" name="guest_rsvp[guests_count]" id="guest_rsvp_guests_count" min="0" value="<%= params.dig(:guest_rsvp, :guests_count) || 0 %>"
                 class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-200">
        </div>
        <div>
          <label for="guest_rsvp_email" class="text-xs font-medium uppercase tracking-wide text-slate-500">Email</label>
          <input type="email" name="guest_rsvp[email]" id="guest_rsvp_email" value="<%= params.dig(:guest_rsvp, :email) %>"
                 class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-200">
        </div>
        <div>
          <label for="guest_rsvp_phone" class="text-xs font-medium uppercase tracking-wide text-slate-500">Teléfono</label>
          <input type="tel" name="guest_rsvp[phone]" id="guest_rsvp_phone" value="<%= params.dig(:guest_rsvp, :phone) %>"
                 class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-200">
        </div>
        <p class="text-xs text-slate-400 sm:col-span-2">* Indica al menos un email o un teléfono.</p>
        <div class="sm:col-span-2">
          <button type="submit" class="rounded-lg bg-violet-600 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-violet-700 transition-colors cursor-pointer">
            Confirmar asistencia
          </button>
        </div>
      <% end %>
    </div>
  <% end %>
```

Además, la página pública necesita mostrar flashes: revisar `app/views/layouts/public.html.erb`; si no renderiza `flash`, agregar al inicio del body:

```erb
    <% flash.each do |type, message| %>
      <div class="mx-auto mt-4 w-full max-w-3xl px-6">
        <div class="rounded-lg border <%= type.to_s == "alert" ? "border-amber-200 bg-amber-50 text-amber-800" : "border-emerald-200 bg-emerald-50 text-emerald-800" %> p-3 text-sm">
          <%= message %>
        </div>
      </div>
    <% end %>
```

- [ ] **Step 6: i18n de mensajes del controller** — en `config/locales/es.yml`, dentro del bloque raíz `es:` (ubicar alfabéticamente junto a otros bloques de primer nivel):

```yaml
  public:
    guest_rsvps:
      created: "¡Asistencia confirmada! Guarda esta página para editar o cancelar."
      received: "Recibido."
      throttled: "Demasiados intentos. Probá de nuevo en unos minutos."
      updated: "Tu confirmación fue actualizada."
      cancelled: "Tu confirmación fue cancelada."
```

- [ ] **Step 7: Correr y verificar que pasan**

Run: `bundle exec rspec spec/requests/public/`
Expected: todos verdes (los 7 nuevos + los existentes).

- [ ] **Step 8: Commit**

```bash
git add config/routes.rb app/controllers/public/guest_rsvps_controller.rb app/views/public/events/show.html.erb app/views/layouts/public.html.erb config/locales/es.yml spec/requests/public/guest_rsvps_spec.rb
git commit -m "feat: RSVP público de invitados con honeypot y throttle por IP"
```

---

### Task 5: Página del token — ver, editar y cancelar la confirmación (TDD)

**Files:**
- Modify: `spec/requests/public/guest_rsvps_spec.rb`
- Modify: `app/controllers/public/guest_rsvps_controller.rb`
- Create: `app/views/public/guest_rsvps/show.html.erb`

- [ ] **Step 1: Specs que fallan** (agregar al describe existente):

```ruby
  describe "GET /c/:slug/rsvp/:access_token" do
    it "muestra la confirmación del invitado" do
      church = public_church
      rsvp = create(:event_guest_rsvp, church:, event: create(:event, church:, visibility: "public"))

      get "/c/#{church.slug}/rsvp/#{rsvp.access_token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(rsvp.name)
      expect(response.body).to include(rsvp.event.title)
    end

    it "404 con token inexistente" do
      church = public_church

      get "/c/#{church.slug}/rsvp/no-existe"

      expect(response).to have_http_status(:not_found)
    end

    it "404 con token de otra iglesia (aislamiento)" do
      church_a = public_church(slug: "iglesia-a")
      church_b = public_church(slug: "iglesia-b")
      rsvp_b = create(:event_guest_rsvp, church: church_b,
                      event: create(:event, church: church_b, visibility: "public"))

      get "/c/#{church_a.slug}/rsvp/#{rsvp_b.access_token}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /c/:slug/rsvp/:access_token" do
    it "actualiza los acompañantes" do
      church = public_church
      rsvp = create(:event_guest_rsvp, church:, event: create(:event, church:, visibility: "public"), guests_count: 0)

      patch "/c/#{church.slug}/rsvp/#{rsvp.access_token}", params: valid_params(name: rsvp.name, email: rsvp.email, guests_count: 4)

      expect(response).to redirect_to("/c/#{church.slug}/rsvp/#{rsvp.access_token}")
      expect(rsvp.reload.guests_count).to eq(4)
    end

    it "cancela la confirmación (soft-cancel, sin destroy)" do
      church = public_church
      rsvp = create(:event_guest_rsvp, church:, event: create(:event, church:, visibility: "public"))

      patch "/c/#{church.slug}/rsvp/#{rsvp.access_token}", params: { cancel: "1" }

      expect(rsvp.reload).to be_cancelled
      expect(EventGuestRsvp.count).to eq(1)
    end

    it "rechaza la edición que excede el cupo" do
      church = public_church
      event = create(:event, church:, visibility: "public", capacity: 2)
      rsvp = create(:event_guest_rsvp, church:, event:, guests_count: 1)

      patch "/c/#{church.slug}/rsvp/#{rsvp.access_token}", params: valid_params(name: rsvp.name, email: rsvp.email, guests_count: 5)

      expect(response).to have_http_status(:unprocessable_content)
      expect(rsvp.reload.guests_count).to eq(1)
    end
  end
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `bundle exec rspec spec/requests/public/guest_rsvps_spec.rb`
Expected: FAIL los nuevos (acciones no existen).

- [ ] **Step 3: Acciones en el controller** (agregar a `Public::GuestRsvpsController`):

```ruby
    def show
      resolve_public_church!
      resolve_guest_rsvp!
    end

    def update
      resolve_public_church!
      resolve_guest_rsvp!

      if params[:cancel].present?
        @guest_rsvp.update!(status: "cancelled")
        return redirect_to public_church_guest_rsvp_path(@church.slug, @guest_rsvp.access_token),
                           notice: t("public.guest_rsvps.cancelled")
      end

      registration = Events::GuestRsvpRegistration.new(
        event: @guest_rsvp.event, guest_rsvp: @guest_rsvp, **guest_rsvp_params.to_h.symbolize_keys
      )

      if registration.save
        redirect_to public_church_guest_rsvp_path(@church.slug, @guest_rsvp.access_token),
                    notice: t("public.guest_rsvps.updated")
      else
        @guest_rsvp_errors = registration.errors.full_messages
        render :show, status: :unprocessable_content
      end
    end
```

Y el resolutor privado:

```ruby
    def resolve_guest_rsvp!
      @guest_rsvp = EventGuestRsvp.for_church(@church).find_by!(access_token: params[:access_token].to_s)
      @event = @guest_rsvp.event
    end
```

- [ ] **Step 4: Vista** — `app/views/public/guest_rsvps/show.html.erb`:

```erb
<% content_for :title, "Tu confirmación — #{@event.title}" %>

<section class="mx-auto w-full max-w-3xl px-6 py-12">
  <p class="text-xs font-semibold uppercase tracking-widest" style="color: <%= church_accent_color(@church) %>;">
    <%= link_to @church.name, public_church_path(@church.slug), class: "hover:underline" %>
  </p>
  <h1 class="mt-2 text-3xl font-bold text-slate-900">Tu confirmación</h1>
  <p class="mt-1 text-sm text-slate-500">
    <%= link_to @event.title, public_church_event_path(@church.slug, @event), class: "font-medium text-violet-600 hover:underline" %>
    — <%= l(@event.starts_at, format: :default) %>
  </p>

  <div class="mt-8 rounded-xl border border-slate-200 bg-white p-6 shadow-card">
    <div class="flex items-center justify-between">
      <p class="text-sm font-semibold text-slate-900"><%= @guest_rsvp.name %></p>
      <% if @guest_rsvp.attending? %>
        <span class="inline-flex rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 ring-1 ring-emerald-200">Confirmado</span>
      <% else %>
        <span class="inline-flex rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-semibold text-slate-600 ring-1 ring-slate-200">Cancelado</span>
      <% end %>
    </div>

    <% if defined?(@guest_rsvp_errors) && @guest_rsvp_errors.present? %>
      <div class="mt-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800">
        <ul class="list-disc pl-5">
          <% @guest_rsvp_errors.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <% if @event.scheduled? %>
      <%= form_with url: public_church_guest_rsvp_path(@church.slug, @guest_rsvp.access_token), method: :patch, class: "mt-6 grid gap-4 sm:grid-cols-2" do %>
        <div>
          <label for="guest_rsvp_name" class="text-xs font-medium uppercase tracking-wide text-slate-500">Nombre *</label>
          <input type="text" name="guest_rsvp[name]" id="guest_rsvp_name" required value="<%= @guest_rsvp.name %>"
                 class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-200">
        </div>
        <div>
          <label for="guest_rsvp_guests_count" class="text-xs font-medium uppercase tracking-wide text-slate-500">Acompañantes</label>
          <input type="number" name="guest_rsvp[guests_count]" id="guest_rsvp_guests_count" min="0" value="<%= @guest_rsvp.guests_count %>"
                 class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-200">
        </div>
        <div>
          <label for="guest_rsvp_email" class="text-xs font-medium uppercase tracking-wide text-slate-500">Email</label>
          <input type="email" name="guest_rsvp[email]" id="guest_rsvp_email" value="<%= @guest_rsvp.email %>"
                 class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-200">
        </div>
        <div>
          <label for="guest_rsvp_phone" class="text-xs font-medium uppercase tracking-wide text-slate-500">Teléfono</label>
          <input type="tel" name="guest_rsvp[phone]" id="guest_rsvp_phone" value="<%= @guest_rsvp.phone %>"
                 class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-200">
        </div>
        <div class="sm:col-span-2">
          <button type="submit" class="rounded-lg bg-violet-600 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-violet-700 transition-colors cursor-pointer">
            <%= @guest_rsvp.attending? ? "Actualizar confirmación" : "Volver a confirmar" %>
          </button>
        </div>
      <% end %>

      <% if @guest_rsvp.attending? %>
        <%= form_with url: public_church_guest_rsvp_path(@church.slug, @guest_rsvp.access_token), method: :patch, class: "mt-3" do %>
          <input type="hidden" name="cancel" value="1">
          <button type="submit" class="text-sm font-medium text-red-600 hover:underline cursor-pointer">Cancelar mi asistencia</button>
        <% end %>
      <% end %>
    <% end %>
  </div>

  <p class="mt-4 text-xs text-slate-400">Guarda el enlace de esta página: es tu acceso para editar o cancelar.</p>
</section>
```

- [ ] **Step 5: Correr y verificar que pasan**

Run: `bundle exec rspec spec/requests/public/guest_rsvps_spec.rb`
Expected: 14 examples, 0 failures

- [ ] **Step 6: Commit**

```bash
git add app/controllers/public/guest_rsvps_controller.rb app/views/public/guest_rsvps/ spec/requests/public/guest_rsvps_spec.rb
git commit -m "feat: página del token para ver, editar y cancelar el RSVP de invitado"
```

---

### Task 6: Panel de conteo en el show admin (Fase C, TDD)

**Files:**
- Modify: `spec/requests/church_admin/events_spec.rb` (agregar specs; si el archivo no existe, crearlo con `require "rails_helper"` y el describe)
- Modify: `app/controllers/church_admin/events_controller.rb` (acción `show`: cargar invitados)
- Modify: `app/views/church_admin/events/show.html.erb`

- [ ] **Step 1: Specs que fallan** (en el describe de show de eventos admin; usar el patrón de sign-in de los specs admin existentes — revisar `spec/requests/church_admin/ministries_spec.rb` para el patrón `create(:church_membership, :owner, church:)` + `sign_in membership.user`):

```ruby
  describe "GET show — panel de conteo" do
    it "muestra el desglose de confirmados, tal vez, no asisten y la lista de invitados" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      event = create(:event, church:, visibility: "public", capacity: 20)
      create(:event_rsvp, church:, event:, status: "attending", guests_count: 2)
      create(:event_rsvp, church:, event:, status: "maybe")
      create(:event_rsvp, church:, event:, status: "not_attending")
      create(:event_guest_rsvp, church:, event:, name: "Ana Invitada", guests_count: 1)
      create(:event_guest_rsvp, :cancelled, church:, event:, name: "Pedro Cancelado")

      sign_in membership.user

      get church_admin_event_path(church, event)

      expect(response.body).to match(%r{Confirmados</p>\s*<p[^>]*>\s*5\s*</p>}m)
      expect(response.body).to include("Ana Invitada")
      expect(response.body).not_to include("Pedro Cancelado")
      expect(response.body).to include("Tal vez")
      expect(response.body).to include("No asisten")
    end
  end
```

Ajustar el regex de "Confirmados" a la estructura real del markup del Step 3 (mantenerlo anclado a la etiqueta, no un `include("5")` suelto).

- [ ] **Step 2: Correr y verificar que falla**

Run: `bundle exec rspec spec/requests/church_admin/events_spec.rb`
Expected: FAIL el nuevo.

- [ ] **Step 3: Controller + vista**

En `ChurchAdmin::EventsController#show`, junto a la carga existente de `@rsvps` (leer la acción primero), agregar:

```ruby
@guest_rsvps = @event.event_guest_rsvps.where(status: "attending").order(:name)
```

En `app/views/church_admin/events/show.html.erb`, reemplazar el card "Confirmaciones" (líneas 38-50) por:

```erb
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-card">
      <h2 class="text-base font-semibold text-slate-900">Confirmaciones</h2>

      <p class="mt-2 text-xs font-medium uppercase tracking-wide text-slate-500">Confirmados</p>
      <p class="text-3xl font-bold text-slate-900"><%= @event.confirmed_attendees_count %></p>
      <p class="text-xs text-slate-500">
        <%= @event.member_attending_count %> miembro<%= "s" if @event.member_attending_count != 1 %>
        · <%= @event.member_guests_count %> acompañante<%= "s" if @event.member_guests_count != 1 %>
        · <%= @event.guest_attendees_count %> invitado<%= "s" if @event.guest_attendees_count != 1 %>
      </p>

      <div class="mt-3 flex gap-4 text-sm">
        <span class="text-slate-600">Tal vez: <span class="font-semibold"><%= @event.maybe_count %></span></span>
        <span class="text-slate-600">No asisten: <span class="font-semibold"><%= @event.not_attending_count %></span></span>
      </div>

      <% if @event.capacity.present? %>
        <% occupancy = [ @event.confirmed_attendees_count * 100 / @event.capacity, 100 ].min %>
        <div class="mt-4">
          <div class="flex justify-between text-xs text-slate-500">
            <span>Ocupación</span>
            <span><%= @event.confirmed_attendees_count %> / <%= @event.capacity %></span>
          </div>
          <div class="mt-1 h-2 w-full rounded-full bg-slate-100">
            <div class="h-2 rounded-full <%= occupancy >= 100 ? "bg-red-500" : "bg-violet-600" %>" style="width: <%= occupancy %>%"></div>
          </div>
        </div>
      <% end %>

      <ul class="mt-4 space-y-1 text-sm text-slate-600">
        <% @rsvps.each do |rsvp| %>
          <li class="flex items-center gap-2">
            <span class="inline-flex rounded-full bg-sky-50 px-2.5 py-0.5 text-xs font-semibold text-sky-700 ring-1 ring-sky-200"><%= rsvp.status %></span>
            <%= rsvp.member.full_name %>
          </li>
        <% end %>
      </ul>

      <% if @guest_rsvps.any? %>
        <h3 class="mt-5 text-xs font-medium uppercase tracking-wide text-slate-500">Invitados confirmados</h3>
        <ul class="mt-2 space-y-1 text-sm text-slate-600">
          <% @guest_rsvps.each do |guest| %>
            <li class="flex flex-wrap items-baseline justify-between gap-2">
              <span class="font-medium text-slate-900"><%= guest.name %><% if guest.guests_count.positive? %> <span class="font-normal text-slate-500">+<%= guest.guests_count %></span><% end %></span>
              <span class="text-xs text-slate-500"><%= [ guest.email, guest.phone ].compact_blank.join(" · ") %></span>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
```

- [ ] **Step 4: Correr y verificar que pasan**

Run: `bundle exec rspec spec/requests/church_admin/`
Expected: todos verdes.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/church_admin/events_controller.rb app/views/church_admin/events/show.html.erb spec/requests/church_admin/
git commit -m "feat: panel de conteo con desglose, ocupación e invitados en el show admin"
```

---

### Task 7: Verificación final del PR

- [ ] **Step 1: Suite completa + estilo + seguridad**

Run: `bundle exec rspec` → 0 failures
Run: `bundle exec rubocop` → no offenses
Run: `bundle exec brakeman --no-pager` → 0 warnings

- [ ] **Step 2: Revisión de reglas del proyecto**

- `event_guest_rsvps` tiene `church_id` y todo query pasa por `@church` / `for_church` / `event.event_guest_rsvps`.
- Cancelar nunca hace `destroy`.
- El `access_token` jamás aparece en logs visibles ni en la página pública del evento (solo en la redirección post-create y la página del token).

- [ ] **Step 3: Verificación manual (con `bin/dev`)**

- Confirmar como invitado desde `/c/<slug>/eventos/<id>`, editar y cancelar desde la página del token.
- Ver el panel admin con desglose y ocupación.

## Fuera de este PR

- PR 3 (Fase D): `occurrence_date` + walk-ins en `event_attendances`, modo check-in Turbo, reporte de cruce RSVP vs asistencia.
- Expiración de tokens, notificaciones por email, spec del límite de 6 eventos del listado público (anotado del review del PR 1 — puede colarse aquí si sobra tiempo, como step opcional).
