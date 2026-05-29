# Etapa 14 — Reportes y Exportaciones Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar 11 reportes administrativos por iglesia (miembros, cumpleaños, ministerios, laborales, eventos/asistencia), cada uno con vista en pantalla y exportación a CSV y XLSX, controlados por permisos `reports/read` (ver) y `reports/manage` (exportar).

**Architecture:** Cada reporte es un objeto en `app/services/reports/` que hereda de `Reports::BaseReport` y expone `columns`/`rows`/`filename`/`title`, siempre scopeado por `church`. Un `Reports::Exporter` reutilizable genera CSV/XLSX desde cualquier reporte. Un `Reports::REGISTRY` mapea claves a clases; `ChurchAdmin::ReportsController#show` despacha genéricamente. La autorización pasa por `ReportPolicy` que delega en `Permissions::PermissionChecker`.

**Tech Stack:** Ruby on Rails 8, Pundit, `caxlsx` (XLSX), librería estándar `csv`, `paper_trail` (auditoría de exportación), RSpec, FactoryBot.

---

## Notas de implementación (leer antes de empezar)

- **Ruby/entorno:** este proyecto usa Ruby 3.4.9 vía mise. Si `bundle exec rspec` falla con `Bundler::RubyVersionMismatch` (toma 3.2.3), prefija el PATH:
  `export PATH="/Users/freivincampbell-qubika/.local/share/mise/installs/ruby/3.4.9/bin:$PATH"`
  antes de cada comando `bundle exec`.
- **Paginación:** `pagy` está en el Gemfile pero **no está integrado** en `ApplicationController` (no hay `include Pagy::Backend`). Para no introducir infraestructura de paginación en esta etapa, la **vista HTML de cada reporte renderiza todas las filas** (los reportes están acotados por iglesia). La exportación es el entregable principal. Esto es una simplificación intencional respecto al spec.
- **Auditoría:** `paper_trail` está migrado (existe la tabla `versions`) pero ningún modelo usa `has_paper_trail`. La auditoría de exportación crea un `PaperTrail::Version` manual. La tabla `versions` tiene columnas `event`, `item_type`, `item_id` (bigint NOT NULL), `whodunnit`, `object` (text). Se usa `item_id: church.id`, `item_type: "Report"`.
- **Scoping multi-tenant:** `Church` tiene `has_many :members, :ministries, :events, :event_rsvps, :event_attendances, :member_occupations, :member_skills, :occupations, :skills`. **No** tiene `ministry_memberships` y la tabla `ministry_memberships` **no** tiene `church_id`; para el reporte de ministerios se scopea vía `MinistryMembership.joins(:ministry).where(ministries: { church_id: church.id })`.
- **Member:** `Member#full_name` ya existe. Enums: `gender`, `marital_status`, `member_status` (active/inactive). Scope `Member.ordered`.

---

## Mapa de archivos

| Archivo | Acción |
|---|---|
| `app/models/permission.rb` | Modificar — agregar `"reports"` a `ASSIGNABLE_MODULE_KEYS` |
| `db/seeds.rb` | Modificar — etiqueta `"reports" => "Reportes"` |
| `app/services/reports/base_report.rb` | Crear — clase base |
| `app/services/reports/exporter.rb` | Crear — CSV/XLSX |
| `app/services/reports/members_report.rb` | Crear |
| `app/services/reports/new_members_report.rb` | Crear |
| `app/services/reports/birthdays_report.rb` | Crear |
| `app/services/reports/members_by_ministry_report.rb` | Crear |
| `app/services/reports/members_by_occupation_report.rb` | Crear |
| `app/services/reports/members_by_skill_report.rb` | Crear |
| `app/services/reports/job_seekers_report.rb` | Crear |
| `app/services/reports/service_providers_report.rb` | Crear |
| `app/services/reports/upcoming_events_report.rb` | Crear |
| `app/services/reports/event_rsvps_report.rb` | Crear |
| `app/services/reports/event_attendance_report.rb` | Crear |
| `app/services/reports/registry.rb` | Crear — `Reports::REGISTRY` |
| `app/policies/report_policy.rb` | Crear |
| `app/controllers/church_admin/reports_controller.rb` | Crear |
| `config/routes.rb` | Modificar — rutas de reportes |
| `app/views/church_admin/reports/index.html.erb` | Crear |
| `app/views/church_admin/reports/show.html.erb` | Crear |
| `app/views/shared/_app_navigation.html.erb` | Modificar — link "Reportes" |
| `config/locales/es.yml` | Modificar — textos de reportes |
| `spec/services/reports/*_spec.rb` | Crear — un spec por servicio |
| `spec/policies/report_policy_spec.rb` | Crear |
| `spec/requests/church_admin/reports_spec.rb` | Crear |

---

## Task 1: Activar el módulo de permisos `reports`

**Files:**
- Modify: `app/models/permission.rb`
- Modify: `db/seeds.rb`
- Test: `spec/models/permission_spec.rb` (crear si no existe)

- [ ] **Step 1: Escribir el test**

Crear o agregar a `spec/models/permission_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Permission do
  it "includes reports as an assignable module" do
    expect(described_class::ASSIGNABLE_MODULE_KEYS).to include("reports")
  end

  it "reports is a valid module key" do
    permission = described_class.new(module_key: "reports", action_key: "read", name: "Reportes - Leer")
    expect(permission).to be_valid
  end
end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/models/permission_spec.rb
```
Expected: FAIL — `ASSIGNABLE_MODULE_KEYS` no incluye "reports".

- [ ] **Step 3: Agregar `"reports"` a `ASSIGNABLE_MODULE_KEYS`**

En `app/models/permission.rb`, dentro del array `ASSIGNABLE_MODULE_KEYS`, agregar `reports` después de `profile_change_requests` y antes de `pastoral_notes`:

```ruby
  ASSIGNABLE_MODULE_KEYS = %w[
    church_memberships
    roles
    members
    ministries
    families
    boards
    events
    church_settings
    occupations
    skills
    service_directory
    profile_change_requests
    reports
    pastoral_notes
  ].freeze
```

- [ ] **Step 4: Agregar la etiqueta en seeds**

En `db/seeds.rb`, dentro del hash `permission_labels`, agregar la línea (después de `"profile_change_requests"`):

```ruby
  "reports" => "Reportes",
```

- [ ] **Step 5: Ejecutar test y re-sembrar**

```bash
bundle exec rspec spec/models/permission_spec.rb
bundle exec rails db:seed
```
Expected: test PASS; seed corre sin error.

- [ ] **Step 6: Commit**

```bash
git add app/models/permission.rb db/seeds.rb spec/models/permission_spec.rb
git commit -m "feat: activar módulo de permisos reports"
```

---

## Task 2: `Reports::BaseReport` y `Reports::Exporter`

**Files:**
- Create: `app/services/reports/base_report.rb`
- Create: `app/services/reports/exporter.rb`
- Test: `spec/services/reports/exporter_spec.rb`

- [ ] **Step 1: Crear la clase base**

Crear `app/services/reports/base_report.rb`:

```ruby
module Reports
  class BaseReport
    attr_reader :church, :filters

    def initialize(church:, filters: {})
      @church = church
      @filters = (filters || {}).to_h.with_indifferent_access
    end

    # [{ key: :symbol, label: "Encabezado" }, ...]
    def columns
      raise NotImplementedError, "#{self.class} debe implementar #columns"
    end

    # Enumerable de hashes { key => valor }, ya scopeado por church
    def rows
      raise NotImplementedError, "#{self.class} debe implementar #rows"
    end

    # Base del nombre de archivo, sin extensión ni fecha
    def filename
      raise NotImplementedError, "#{self.class} debe implementar #filename"
    end

    def title
      raise NotImplementedError, "#{self.class} debe implementar #title"
    end
  end
end
```

- [ ] **Step 2: Escribir el test del exporter**

Crear `spec/services/reports/exporter_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Reports::Exporter do
  # Reporte fake para probar el exporter de forma aislada
  let(:report) do
    instance_double(
      Reports::BaseReport,
      title: "Reporte demo",
      filename: "demo",
      columns: [ { key: :name, label: "Nombre" }, { key: :age, label: "Edad" } ],
      rows: [ { name: "Ana", age: 30 }, { name: "Luis", age: 25 } ]
    )
  end

  describe "#to_csv" do
    it "genera encabezados y filas" do
      csv = described_class.new(report).to_csv

      expect(csv).to include("Nombre,Edad")
      expect(csv).to include("Ana,30")
      expect(csv).to include("Luis,25")
    end
  end

  describe "#to_xlsx" do
    it "genera un binario xlsx no vacío" do
      data = described_class.new(report).to_xlsx

      expect(data).to be_a(String)
      expect(data.bytesize).to be > 0
      # Un xlsx es un zip: empieza con la firma PK\x03\x04
      expect(data[0, 2]).to eq("PK")
    end
  end
end
```

- [ ] **Step 3: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/services/reports/exporter_spec.rb
```
Expected: FAIL — `Reports::Exporter` no existe.

- [ ] **Step 4: Crear el exporter**

Crear `app/services/reports/exporter.rb`:

```ruby
require "csv"

module Reports
  class Exporter
    def initialize(report)
      @report = report
    end

    def to_csv
      CSV.generate do |csv|
        csv << @report.columns.map { |col| col[:label] }
        @report.rows.each do |row|
          csv << @report.columns.map { |col| row[col[:key]] }
        end
      end
    end

    def to_xlsx
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: sheet_name) do |sheet|
        sheet.add_row(@report.columns.map { |col| col[:label] })
        @report.rows.each do |row|
          sheet.add_row(@report.columns.map { |col| row[col[:key]] })
        end
      end
      package.to_stream.read
    end

    private

    def sheet_name
      @report.title.to_s.first(31).presence || "Reporte"
    end
  end
end
```

- [ ] **Step 5: Ejecutar test y verificar que pasa**

```bash
bundle exec rspec spec/services/reports/exporter_spec.rb
```
Expected: PASS (2 examples).

- [ ] **Step 6: Commit**

```bash
git add app/services/reports/base_report.rb app/services/reports/exporter.rb spec/services/reports/exporter_spec.rb
git commit -m "feat: base de reportes y exportador CSV/XLSX"
```

---

## Task 3: `ReportPolicy`

**Files:**
- Create: `app/policies/report_policy.rb`
- Test: `spec/policies/report_policy_spec.rb`

- [ ] **Step 1: Escribir el spec**

Crear `spec/policies/report_policy_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe ReportPolicy do
  let(:church) { create(:church) }

  def setup_role(action_key)
    membership = create(:church_membership, church:)
    role = create(:role, church:)
    perm = Permission.find_by(module_key: "reports", action_key:) ||
           create(:permission, module_key: "reports", action_key:, name: "Reportes - #{action_key}")
    create(:role_permission, role:, permission: perm)
    create(:membership_role, church_membership: membership, role:)
    membership
  end

  describe "#index? / #show?" do
    it "permite con reports/read" do
      membership = setup_role("read")
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).index?).to be(true)
        expect(described_class.new(membership.user, nil).show?).to be(true)
      end
    end

    it "deniega sin permiso" do
      membership = create(:church_membership, church:)
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).index?).to be(false)
      end
    end

    it "permite al owner" do
      membership = create(:church_membership, :owner, church:)
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).index?).to be(true)
      end
    end
  end

  describe "#export?" do
    it "permite con reports/manage" do
      membership = setup_role("manage")
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).export?).to be(true)
      end
    end

    it "deniega con solo reports/read" do
      membership = setup_role("read")
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).export?).to be(false)
      end
    end
  end
end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/policies/report_policy_spec.rb
```
Expected: FAIL — `ReportPolicy` no existe.

- [ ] **Step 3: Crear la policy**

Crear `app/policies/report_policy.rb`:

```ruby
class ReportPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("reports", "read")
  end

  def show?
    index?
  end

  def export?
    super_admin? || permission?("reports", "manage")
  end
end
```

- [ ] **Step 4: Ejecutar test y verificar que pasa**

```bash
bundle exec rspec spec/policies/report_policy_spec.rb
```
Expected: PASS (5 examples).

- [ ] **Step 5: Commit**

```bash
git add app/policies/report_policy.rb spec/policies/report_policy_spec.rb
git commit -m "feat: ReportPolicy (read=ver, manage=exportar)"
```

---

## Task 4: Reportes de miembros

**Files:**
- Create: `app/services/reports/members_report.rb`
- Create: `app/services/reports/new_members_report.rb`
- Test: `spec/services/reports/members_report_spec.rb`
- Test: `spec/services/reports/new_members_report_spec.rb`

- [ ] **Step 1: Escribir el spec de MembersReport**

Crear `spec/services/reports/members_report_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Reports::MembersReport do
  let(:church) { create(:church) }

  it "expone columnas con encabezados en español" do
    report = described_class.new(church:)
    labels = report.columns.map { |c| c[:label] }
    expect(labels).to include("Nombre completo", "Teléfono", "Estado")
  end

  it "incluye solo miembros de la iglesia actual (aislamiento)" do
    mine = create(:member, church:, first_name: "Ana")
    other = create(:member, first_name: "Otra")

    names = described_class.new(church:).rows.map { |r| r[:full_name] }

    expect(names).to include(mine.full_name)
    expect(names).not_to include(other.full_name)
  end

  it "filtra por estado activo" do
    active = create(:member, church:, member_status: "active", first_name: "Activo")
    inactive = create(:member, church:, member_status: "inactive", first_name: "Inactivo")

    rows = described_class.new(church:, filters: { status: "active" }).rows
    names = rows.map { |r| r[:full_name] }

    expect(names).to include(active.full_name)
    expect(names).not_to include(inactive.full_name)
  end

  it "filtra por estado inactivo" do
    create(:member, church:, member_status: "active", first_name: "Activo")
    inactive = create(:member, church:, member_status: "inactive", first_name: "Inactivo")

    rows = described_class.new(church:, filters: { status: "inactive" }).rows

    expect(rows.map { |r| r[:full_name] }).to contain_exactly(inactive.full_name)
  end
end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/services/reports/members_report_spec.rb
```
Expected: FAIL — clase no existe.

- [ ] **Step 3: Crear MembersReport**

Crear `app/services/reports/members_report.rb`:

```ruby
module Reports
  class MembersReport < BaseReport
    def title = "Reporte de miembros"
    def filename = "miembros"

    def columns
      [
        { key: :full_name, label: "Nombre completo" },
        { key: :gender, label: "Género" },
        { key: :marital_status, label: "Estado civil" },
        { key: :phone, label: "Teléfono" },
        { key: :email, label: "Email" },
        { key: :baptized_on, label: "Fecha de bautismo" },
        { key: :official_membership_on, label: "Fecha de membresía" },
        { key: :status, label: "Estado" }
      ]
    end

    def rows
      scope.map do |member|
        {
          full_name: member.full_name,
          gender: I18n.t("activerecord.attributes.member.genders.#{member.gender}", default: member.gender),
          marital_status: I18n.t("activerecord.attributes.member.marital_statuses.#{member.marital_status}", default: member.marital_status),
          phone: member.phone,
          email: member.email,
          baptized_on: member.baptized_on,
          official_membership_on: member.official_membership_on,
          status: member.active? ? "Activo" : "Inactivo"
        }
      end
    end

    private

    def scope
      relation = church.members.ordered
      case filters[:status]
      when "active" then relation.where(member_status: "active")
      when "inactive" then relation.where(member_status: "inactive")
      else relation
      end
    end
  end
end
```

Nota: `member.active?` viene del enum `member_status`. Si I18n no tiene las claves de género/estado civil, el `default:` deja el valor crudo — no falla.

- [ ] **Step 4: Ejecutar y verificar que pasa**

```bash
bundle exec rspec spec/services/reports/members_report_spec.rb
```
Expected: PASS.

- [ ] **Step 5: Escribir el spec de NewMembersReport**

Crear `spec/services/reports/new_members_report_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Reports::NewMembersReport do
  let(:church) { create(:church) }

  it "filtra por mes de membresía (YYYY-MM)" do
    in_month = create(:member, church:, official_membership_on: Date.new(2026, 3, 10), first_name: "Marzo")
    out_month = create(:member, church:, official_membership_on: Date.new(2026, 4, 10), first_name: "Abril")

    rows = described_class.new(church:, filters: { month: "2026-03" }).rows
    names = rows.map { |r| r[:full_name] }

    expect(names).to include(in_month.full_name)
    expect(names).not_to include(out_month.full_name)
  end

  it "aísla por iglesia" do
    create(:member, official_membership_on: Date.new(2026, 3, 10), first_name: "Otra")
    rows = described_class.new(church:, filters: { month: "2026-03" }).rows
    expect(rows).to be_empty
  end
end
```

- [ ] **Step 6: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/services/reports/new_members_report_spec.rb
```
Expected: FAIL.

- [ ] **Step 7: Crear NewMembersReport**

Crear `app/services/reports/new_members_report.rb`:

```ruby
module Reports
  class NewMembersReport < BaseReport
    def title = "Miembros nuevos por mes"
    def filename = "miembros-nuevos"

    def columns
      [
        { key: :full_name, label: "Nombre completo" },
        { key: :official_membership_on, label: "Fecha de membresía" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |member|
        {
          full_name: member.full_name,
          official_membership_on: member.official_membership_on,
          phone: member.phone
        }
      end
    end

    private

    def scope
      relation = church.members.where.not(official_membership_on: nil).ordered
      month = parse_month
      return relation unless month

      relation.where(official_membership_on: month.all_month)
    end

    def parse_month
      value = filters[:month].to_s
      return nil if value.blank?

      Date.strptime(value, "%Y-%m")
    rescue ArgumentError
      nil
    end
  end
end
```

- [ ] **Step 8: Ejecutar y verificar que pasa**

```bash
bundle exec rspec spec/services/reports/new_members_report_spec.rb
```
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add app/services/reports/members_report.rb app/services/reports/new_members_report.rb spec/services/reports/members_report_spec.rb spec/services/reports/new_members_report_spec.rb
git commit -m "feat: reportes de miembros (general y nuevos por mes)"
```

---

## Task 5: Reporte de cumpleaños

**Files:**
- Create: `app/services/reports/birthdays_report.rb`
- Test: `spec/services/reports/birthdays_report_spec.rb`

- [ ] **Step 1: Escribir el spec**

Crear `spec/services/reports/birthdays_report_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Reports::BirthdaysReport do
  let(:church) { create(:church) }

  it "filtra por mes de nacimiento y ordena por día" do
    early = create(:member, church:, birth_date: Date.new(1990, 5, 3), first_name: "Tres")
    late = create(:member, church:, birth_date: Date.new(1985, 5, 20), first_name: "Veinte")
    create(:member, church:, birth_date: Date.new(1990, 6, 1), first_name: "Junio")

    rows = described_class.new(church:, filters: { month: "5" }).rows

    expect(rows.map { |r| r[:full_name] }).to eq([ early.full_name, late.full_name ])
    expect(rows.first[:day]).to eq(3)
  end

  it "aísla por iglesia" do
    create(:member, birth_date: Date.new(1990, 5, 3), first_name: "Otra")
    rows = described_class.new(church:, filters: { month: "5" }).rows
    expect(rows).to be_empty
  end
end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/services/reports/birthdays_report_spec.rb
```
Expected: FAIL.

- [ ] **Step 3: Crear BirthdaysReport**

Crear `app/services/reports/birthdays_report.rb`:

```ruby
module Reports
  class BirthdaysReport < BaseReport
    def title = "Cumpleaños por mes"
    def filename = "cumpleanos"

    def columns
      [
        { key: :full_name, label: "Nombre completo" },
        { key: :day, label: "Día" },
        { key: :month, label: "Mes" },
        { key: :turning_age, label: "Edad que cumple" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |member|
        {
          full_name: member.full_name,
          day: member.birth_date.day,
          month: member.birth_date.month,
          turning_age: turning_age(member.birth_date),
          phone: member.phone
        }
      end
    end

    private

    def scope
      relation = church.members
      month = filters[:month].to_i
      relation = relation.where("EXTRACT(MONTH FROM birth_date) = ?", month) if month.between?(1, 12)
      relation.order(Arel.sql("EXTRACT(DAY FROM birth_date)"))
    end

    def turning_age(birth_date)
      Date.current.year - birth_date.year
    end
  end
end
```

- [ ] **Step 4: Ejecutar y verificar que pasa**

```bash
bundle exec rspec spec/services/reports/birthdays_report_spec.rb
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/services/reports/birthdays_report.rb spec/services/reports/birthdays_report_spec.rb
git commit -m "feat: reporte de cumpleaños por mes"
```

---

## Task 6: Reporte de miembros por ministerio

**Files:**
- Create: `app/services/reports/members_by_ministry_report.rb`
- Test: `spec/services/reports/members_by_ministry_report_spec.rb`

- [ ] **Step 1: Escribir el spec**

Crear `spec/services/reports/members_by_ministry_report_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Reports::MembersByMinistryReport do
  let(:church) { create(:church) }

  it "lista membresías activas de ministerio scopeadas por iglesia" do
    ministry = create(:ministry, church:, name: "Alabanza")
    member = create(:member, church:, first_name: "Juan")
    create(:ministry_membership, ministry:, member:, ministry_role: :leader, status: :active)

    other_ministry = create(:ministry, name: "Otra")
    other_member = create(:member, church: other_ministry.church)
    create(:ministry_membership, ministry: other_ministry, member: other_member, status: :active)

    rows = described_class.new(church:).rows

    expect(rows.size).to eq(1)
    expect(rows.first[:ministry]).to eq("Alabanza")
    expect(rows.first[:member]).to eq(member.full_name)
    expect(rows.first[:ministry_role]).to eq("Líder")
  end

  it "filtra por ministry_id" do
    a = create(:ministry, church:, name: "A")
    b = create(:ministry, church:, name: "B")
    ma = create(:member, church:)
    mb = create(:member, church:)
    create(:ministry_membership, ministry: a, member: ma, status: :active)
    create(:ministry_membership, ministry: b, member: mb, status: :active)

    rows = described_class.new(church:, filters: { ministry_id: a.id }).rows

    expect(rows.map { |r| r[:ministry] }).to contain_exactly("A")
  end
end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/services/reports/members_by_ministry_report_spec.rb
```
Expected: FAIL.

- [ ] **Step 3: Crear MembersByMinistryReport**

Crear `app/services/reports/members_by_ministry_report.rb`:

```ruby
module Reports
  class MembersByMinistryReport < BaseReport
    ROLE_LABELS = { "member" => "Miembro", "leader" => "Líder", "co_leader" => "Co-líder" }.freeze

    def title = "Miembros por ministerio"
    def filename = "miembros-por-ministerio"

    def columns
      [
        { key: :ministry, label: "Ministerio" },
        { key: :member, label: "Miembro" },
        { key: :ministry_role, label: "Rol en ministerio" },
        { key: :status, label: "Estado" }
      ]
    end

    def rows
      scope.map do |mm|
        {
          ministry: mm.ministry.name,
          member: mm.member.full_name,
          ministry_role: ROLE_LABELS.fetch(mm.ministry_role, mm.ministry_role),
          status: mm.active? ? "Activo" : "Inactivo"
        }
      end
    end

    private

    def scope
      relation = MinistryMembership
        .joins(:ministry, :member)
        .where(ministries: { church_id: church.id })
        .where(status: "active")
        .includes(:ministry, :member)
        .order("ministries.name", "members.last_name")

      ministry_id = filters[:ministry_id].presence
      ministry_id ? relation.where(ministry_id:) : relation
    end
  end
end
```

- [ ] **Step 4: Ejecutar y verificar que pasa**

```bash
bundle exec rspec spec/services/reports/members_by_ministry_report_spec.rb
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/services/reports/members_by_ministry_report.rb spec/services/reports/members_by_ministry_report_spec.rb
git commit -m "feat: reporte de miembros por ministerio"
```

---

## Task 7: Reportes laborales

**Files:**
- Create: `app/services/reports/members_by_occupation_report.rb`
- Create: `app/services/reports/members_by_skill_report.rb`
- Create: `app/services/reports/job_seekers_report.rb`
- Create: `app/services/reports/service_providers_report.rb`
- Test: `spec/services/reports/labor_reports_spec.rb`

- [ ] **Step 1: Escribir el spec combinado**

Crear `spec/services/reports/labor_reports_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Reportes laborales" do
  let(:church) { create(:church) }

  describe Reports::MembersByOccupationReport do
    it "lista ocupaciones de miembros scopeadas por iglesia y filtra por occupation_id" do
      occ = create(:occupation, church:, name: "Carpintero")
      member = create(:member, church:, first_name: "Pedro")
      create(:member_occupation, church:, member:, occupation: occ, job_title: "Maestro")

      other = create(:member_occupation)

      rows = described_class.new(church:, filters: { occupation_id: occ.id }).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:occupation]).to eq("Carpintero")
      expect(rows.first[:member]).to eq(member.full_name)
      expect(rows.map { |r| r[:member] }).not_to include(other.member.full_name)
    end
  end

  describe Reports::MembersBySkillReport do
    it "lista habilidades de miembros con nivel, scopeadas por iglesia" do
      skill = create(:skill, church:, name: "Sonido")
      member = create(:member, church:, first_name: "Lucas")
      create(:member_skill, church:, member:, skill:, level: "advanced")

      rows = described_class.new(church:, filters: { skill_id: skill.id }).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:skill]).to eq("Sonido")
      expect(rows.first[:member]).to eq(member.full_name)
    end
  end

  describe Reports::JobSeekersReport do
    it "lista solo quienes buscan trabajo" do
      seeker_member = create(:member, church:, first_name: "Busca")
      create(:member_occupation, church:, member: seeker_member, looking_for_work: true)
      other_member = create(:member, church:, first_name: "NoBusca")
      create(:member_occupation, church:, member: other_member, looking_for_work: false)

      rows = described_class.new(church:).rows

      expect(rows.map { |r| r[:member] }).to contain_exactly(seeker_member.full_name)
    end
  end

  describe Reports::ServiceProvidersReport do
    it "lista solo quienes ofrecen servicios" do
      provider_member = create(:member, church:, first_name: "Ofrece")
      create(:member_occupation, church:, member: provider_member, offers_services: true)
      other_member = create(:member, church:, first_name: "NoOfrece")
      create(:member_occupation, church:, member: other_member, offers_services: false)

      rows = described_class.new(church:).rows

      expect(rows.map { |r| r[:member] }).to contain_exactly(provider_member.full_name)
    end
  end
end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/services/reports/labor_reports_spec.rb
```
Expected: FAIL — clases no existen.

- [ ] **Step 3: Crear MembersByOccupationReport**

Crear `app/services/reports/members_by_occupation_report.rb`:

```ruby
module Reports
  class MembersByOccupationReport < BaseReport
    def title = "Miembros por ocupación"
    def filename = "miembros-por-ocupacion"

    def columns
      [
        { key: :occupation, label: "Ocupación" },
        { key: :member, label: "Miembro" },
        { key: :job_title, label: "Cargo" },
        { key: :employment_status, label: "Estado de empleo" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |mo|
        {
          occupation: mo.occupation&.name,
          member: mo.member.full_name,
          job_title: mo.job_title,
          employment_status: mo.employment_status,
          phone: mo.member.phone
        }
      end
    end

    private

    def scope
      relation = church.member_occupations
        .includes(:member, :occupation)
        .joins(:member)
        .order("members.last_name")
      occupation_id = filters[:occupation_id].presence
      occupation_id ? relation.where(occupation_id:) : relation
    end
  end
end
```

- [ ] **Step 4: Crear MembersBySkillReport**

Crear `app/services/reports/members_by_skill_report.rb`:

```ruby
module Reports
  class MembersBySkillReport < BaseReport
    def title = "Miembros por habilidad"
    def filename = "miembros-por-habilidad"

    def columns
      [
        { key: :skill, label: "Habilidad" },
        { key: :member, label: "Miembro" },
        { key: :level, label: "Nivel" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |ms|
        {
          skill: ms.skill.name,
          member: ms.member.full_name,
          level: ms.level,
          phone: ms.member.phone
        }
      end
    end

    private

    def scope
      relation = church.member_skills
        .includes(:member, :skill)
        .joins(:member)
        .order("members.last_name")
      skill_id = filters[:skill_id].presence
      skill_id ? relation.where(skill_id:) : relation
    end
  end
end
```

- [ ] **Step 5: Crear JobSeekersReport**

Crear `app/services/reports/job_seekers_report.rb`:

```ruby
module Reports
  class JobSeekersReport < BaseReport
    def title = "Miembros buscando trabajo"
    def filename = "buscando-trabajo"

    def columns
      [
        { key: :member, label: "Miembro" },
        { key: :occupation, label: "Ocupación" },
        { key: :professional_contact, label: "Contacto profesional" },
        { key: :phone, label: "Teléfono" },
        { key: :email, label: "Email" }
      ]
    end

    def rows
      scope.map do |mo|
        {
          member: mo.member.full_name,
          occupation: mo.occupation&.name,
          professional_contact: mo.professional_contact,
          phone: mo.member.phone,
          email: mo.member.email
        }
      end
    end

    private

    def scope
      church.member_occupations
        .where(looking_for_work: true)
        .includes(:member, :occupation)
        .joins(:member)
        .order("members.last_name")
    end
  end
end
```

- [ ] **Step 6: Crear ServiceProvidersReport**

Crear `app/services/reports/service_providers_report.rb`:

```ruby
module Reports
  class ServiceProvidersReport < BaseReport
    def title = "Miembros que ofrecen servicios"
    def filename = "ofrecen-servicios"

    def columns
      [
        { key: :member, label: "Miembro" },
        { key: :occupation, label: "Ocupación" },
        { key: :job_title, label: "Cargo" },
        { key: :professional_contact, label: "Contacto profesional" },
        { key: :phone, label: "Teléfono" }
      ]
    end

    def rows
      scope.map do |mo|
        {
          member: mo.member.full_name,
          occupation: mo.occupation&.name,
          job_title: mo.job_title,
          professional_contact: mo.professional_contact,
          phone: mo.member.phone
        }
      end
    end

    private

    def scope
      church.member_occupations
        .where(offers_services: true)
        .includes(:member, :occupation)
        .joins(:member)
        .order("members.last_name")
    end
  end
end
```

- [ ] **Step 7: Ejecutar y verificar que pasa**

```bash
bundle exec rspec spec/services/reports/labor_reports_spec.rb
```
Expected: PASS (4 examples). Si una factory no existe (`:member_occupation`, `:member_skill`, `:occupation`, `:skill`), revisa `spec/factories/` y ajusta los nombres de los traits/atributos a los reales del proyecto.

- [ ] **Step 8: Commit**

```bash
git add app/services/reports/members_by_occupation_report.rb app/services/reports/members_by_skill_report.rb app/services/reports/job_seekers_report.rb app/services/reports/service_providers_report.rb spec/services/reports/labor_reports_spec.rb
git commit -m "feat: reportes laborales (ocupación, habilidad, buscando trabajo, ofrecen servicios)"
```

---

## Task 8: Reportes de eventos y asistencia

**Files:**
- Create: `app/services/reports/upcoming_events_report.rb`
- Create: `app/services/reports/event_rsvps_report.rb`
- Create: `app/services/reports/event_attendance_report.rb`
- Test: `spec/services/reports/event_reports_spec.rb`

- [ ] **Step 1: Escribir el spec combinado**

Crear `spec/services/reports/event_reports_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Reportes de eventos" do
  let(:church) { create(:church) }

  describe Reports::UpcomingEventsReport do
    it "lista solo eventos futuros de la iglesia" do
      future = create(:event, church:, title: "Futuro", starts_at: 2.days.from_now)
      create(:event, church:, title: "Pasado", starts_at: 2.days.ago)
      create(:event, title: "OtraIglesia", starts_at: 2.days.from_now)

      rows = described_class.new(church:).rows

      expect(rows.map { |r| r[:title] }).to contain_exactly(future.title)
    end
  end

  describe Reports::EventRsvpsReport do
    it "lista RSVPs de un evento" do
      event = create(:event, church:, title: "Culto")
      member = create(:member, church:, first_name: "Confirma")
      create(:event_rsvp, church:, event:, member:, status: "attending", guests_count: 2)

      rows = described_class.new(church:, filters: { event_id: event.id }).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:member]).to eq(member.full_name)
      expect(rows.first[:guests_count]).to eq(2)
    end
  end

  describe Reports::EventAttendanceReport do
    it "lista asistencia real de un evento" do
      event = create(:event, church:, title: "Culto")
      member = create(:member, church:, first_name: "Asiste")
      create(:event_attendance, church:, event:, member:, attended: true)

      rows = described_class.new(church:, filters: { event_id: event.id }).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:member]).to eq(member.full_name)
      expect(rows.first[:attended]).to eq("Sí")
    end
  end
end
```

- [ ] **Step 2: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/services/reports/event_reports_spec.rb
```
Expected: FAIL.

- [ ] **Step 3: Crear UpcomingEventsReport**

Crear `app/services/reports/upcoming_events_report.rb`:

```ruby
module Reports
  class UpcomingEventsReport < BaseReport
    def title = "Eventos próximos"
    def filename = "eventos-proximos"

    def columns
      [
        { key: :title, label: "Título" },
        { key: :starts_at, label: "Fecha" },
        { key: :event_type, label: "Tipo" },
        { key: :ministry, label: "Ministerio" },
        { key: :location, label: "Lugar" },
        { key: :confirmed, label: "Confirmados" }
      ]
    end

    def rows
      scope.map do |event|
        {
          title: event.title,
          starts_at: event.starts_at,
          event_type: event.event_type,
          ministry: event.ministry&.name,
          location: event.location,
          confirmed: event.confirmed_attendees_count
        }
      end
    end

    private

    def scope
      church.events.includes(:ministry).upcoming
    end
  end
end
```

Nota: `Event#confirmed_attendees_count` y el scope `upcoming` ya existen en el modelo.

- [ ] **Step 4: Crear EventRsvpsReport**

Crear `app/services/reports/event_rsvps_report.rb`:

```ruby
module Reports
  class EventRsvpsReport < BaseReport
    STATUS_LABELS = { "attending" => "Asistirá", "not_attending" => "No asistirá", "maybe" => "Tal vez" }.freeze

    def title = "Confirmaciones de asistencia"
    def filename = "confirmaciones"

    def columns
      [
        { key: :event, label: "Evento" },
        { key: :member, label: "Miembro" },
        { key: :status, label: "Estado RSVP" },
        { key: :guests_count, label: "Invitados" },
        { key: :notes, label: "Notas" }
      ]
    end

    def rows
      scope.map do |rsvp|
        {
          event: rsvp.event.title,
          member: rsvp.member.full_name,
          status: STATUS_LABELS.fetch(rsvp.status, rsvp.status),
          guests_count: rsvp.guests_count,
          notes: rsvp.notes
        }
      end
    end

    private

    def scope
      relation = church.event_rsvps.includes(:event, :member).joins(:member).order("members.last_name")
      event_id = filters[:event_id].presence
      event_id ? relation.where(event_id:) : relation
    end
  end
end
```

- [ ] **Step 5: Crear EventAttendanceReport**

Crear `app/services/reports/event_attendance_report.rb`:

```ruby
module Reports
  class EventAttendanceReport < BaseReport
    def title = "Asistencia real por evento"
    def filename = "asistencia"

    def columns
      [
        { key: :event, label: "Evento" },
        { key: :member, label: "Miembro" },
        { key: :attended, label: "¿Asistió?" },
        { key: :checked_in_at, label: "Hora de check-in" }
      ]
    end

    def rows
      scope.map do |attendance|
        {
          event: attendance.event.title,
          member: attendance.member.full_name,
          attended: attendance.attended? ? "Sí" : "No",
          checked_in_at: attendance.checked_in_at
        }
      end
    end

    private

    def scope
      relation = church.event_attendances.includes(:event, :member).joins(:member).order("members.last_name")
      event_id = filters[:event_id].presence
      event_id ? relation.where(event_id:) : relation
    end
  end
end
```

- [ ] **Step 6: Ejecutar y verificar que pasa**

```bash
bundle exec rspec spec/services/reports/event_reports_spec.rb
```
Expected: PASS (3 examples). Si falta la factory `:event_rsvp` o `:event_attendance`, revisa `spec/factories/` y ajusta atributos.

- [ ] **Step 7: Commit**

```bash
git add app/services/reports/upcoming_events_report.rb app/services/reports/event_rsvps_report.rb app/services/reports/event_attendance_report.rb spec/services/reports/event_reports_spec.rb
git commit -m "feat: reportes de eventos (próximos, RSVPs, asistencia)"
```

---

## Task 9: Registro, controlador, rutas y auditoría

**Files:**
- Create: `app/services/reports/registry.rb`
- Create: `app/controllers/church_admin/reports_controller.rb`
- Modify: `config/routes.rb`
- Test: `spec/requests/church_admin/reports_spec.rb`

- [ ] **Step 1: Crear el registro**

Crear `app/services/reports/registry.rb`:

```ruby
module Reports
  REGISTRY = {
    "members"               => { class: Reports::MembersReport,             category: :members,    label: "Miembros" },
    "new_members"           => { class: Reports::NewMembersReport,          category: :members,    label: "Miembros nuevos por mes" },
    "birthdays"             => { class: Reports::BirthdaysReport,           category: :birthdays,  label: "Cumpleaños por mes" },
    "members_by_ministry"   => { class: Reports::MembersByMinistryReport,   category: :ministries, label: "Miembros por ministerio" },
    "members_by_occupation" => { class: Reports::MembersByOccupationReport, category: :labor,      label: "Miembros por ocupación" },
    "members_by_skill"      => { class: Reports::MembersBySkillReport,      category: :labor,      label: "Miembros por habilidad" },
    "job_seekers"           => { class: Reports::JobSeekersReport,          category: :labor,      label: "Miembros buscando trabajo" },
    "service_providers"     => { class: Reports::ServiceProvidersReport,    category: :labor,      label: "Miembros que ofrecen servicios" },
    "upcoming_events"       => { class: Reports::UpcomingEventsReport,      category: :events,     label: "Eventos próximos" },
    "event_rsvps"           => { class: Reports::EventRsvpsReport,          category: :events,     label: "Confirmaciones de asistencia" },
    "event_attendance"      => { class: Reports::EventAttendanceReport,     category: :events,     label: "Asistencia real por evento" }
  }.freeze

  CATEGORY_LABELS = {
    members: "Miembros",
    birthdays: "Cumpleaños",
    ministries: "Ministerios",
    labor: "Laborales",
    events: "Eventos y asistencia"
  }.freeze
end
```

- [ ] **Step 2: Agregar las rutas**

En `config/routes.rb`, dentro del bloque `namespace :admin, module: :church_admin, as: :admin do` (el que está anidado en `resources :churches`), agregar:

```ruby
      get "reports", to: "reports#index", as: :reports
      get "reports/:report", to: "reports#show", as: :report
```

Verifica el nombre de helper resultante corriendo:
```bash
bundle exec rails routes -g reports
```
Expected: helpers `church_admin_reports_path` y `church_admin_report_path`.

- [ ] **Step 3: Escribir el spec de request**

Crear `spec/requests/church_admin/reports_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Church admin reports" do
  def member_with_reports(church, action_key)
    membership = create(:church_membership, church:)
    role = create(:role, church:)
    perm = Permission.find_by(module_key: "reports", action_key:) ||
           create(:permission, module_key: "reports", action_key:, name: "Reportes - #{action_key}")
    create(:role_permission, role:, permission: perm)
    create(:membership_role, church_membership: membership, role:)
    membership
  end

  describe "access control" do
    it "requiere autenticación" do
      church = create(:church)
      get church_admin_reports_path(church)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET index" do
    it "muestra el índice con permiso reports/read" do
      church = create(:church)
      membership = member_with_reports(church, "read")
      sign_in membership.user

      get church_admin_reports_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Reportes")
    end
  end

  describe "GET show (HTML)" do
    it "renderiza un reporte con datos de la iglesia actual" do
      church = create(:church)
      membership = member_with_reports(church, "read")
      member = create(:member, church:, first_name: "Visible")
      sign_in membership.user

      get church_admin_report_path(church, "members")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member.full_name)
    end

    it "404 para un reporte inexistente" do
      church = create(:church)
      membership = member_with_reports(church, "read")
      sign_in membership.user

      get church_admin_report_path(church, "no_existe")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET show (CSV)" do
    it "permite exportar con reports/manage" do
      church = create(:church)
      membership = member_with_reports(church, "manage")
      create(:member, church:, first_name: "Exportable")
      sign_in membership.user

      get church_admin_report_path(church, "members", format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      expect(response.body).to include("Nombre completo")
    end

    it "deniega exportar con solo reports/read" do
      church = create(:church)
      membership = member_with_reports(church, "read")
      sign_in membership.user

      get church_admin_report_path(church, "members", format: :csv)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET show (XLSX)" do
    it "permite exportar xlsx con reports/manage" do
      church = create(:church)
      membership = member_with_reports(church, "manage")
      create(:member, church:)
      sign_in membership.user

      get church_admin_report_path(church, "members", format: :xlsx)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("spreadsheetml")
    end
  end

  describe "auditoría de exportación" do
    it "registra una versión de exportación" do
      church = create(:church)
      membership = member_with_reports(church, "manage")
      create(:member, church:)
      sign_in membership.user

      expect {
        get church_admin_report_path(church, "members", format: :csv)
      }.to change { PaperTrail::Version.where(item_type: "Report", event: "export").count }.by(1)
    end
  end
end
```

- [ ] **Step 4: Ejecutar y verificar que falla**

```bash
bundle exec rspec spec/requests/church_admin/reports_spec.rb
```
Expected: FAIL — controlador/rutas no existen.

- [ ] **Step 5: Crear el controlador**

Crear `app/controllers/church_admin/reports_controller.rb`:

```ruby
module ChurchAdmin
  class ReportsController < BaseController
    def index
      authorize ReportPolicy, :index?, policy_class: ReportPolicy
      @registry = Reports::REGISTRY
      @category_labels = Reports::CATEGORY_LABELS
    end

    def show
      authorize ReportPolicy, :show?, policy_class: ReportPolicy

      entry = Reports::REGISTRY[params[:report]]
      raise ActiveRecord::RecordNotFound if entry.nil?

      @report = entry[:class].new(church: @church, filters: report_filters)

      respond_to do |format|
        format.html { @rows = @report.rows }
        format.csv  { export(:to_csv, "text/csv") }
        format.xlsx { export(:to_xlsx, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet") }
      end
    end

    private

    def export(method, content_type)
      authorize ReportPolicy, :export?, policy_class: ReportPolicy

      data = Reports::Exporter.new(@report).public_send(method)
      audit_export(method)

      extension = method == :to_csv ? "csv" : "xlsx"
      send_data data,
        type: content_type,
        filename: "#{@report.filename}-#{Date.current.iso8601}.#{extension}",
        disposition: "attachment"
    end

    def audit_export(method)
      PaperTrail::Version.create!(
        event: "export",
        item_type: "Report",
        item_id: @church.id,
        whodunnit: current_user.id.to_s,
        object: {
          report: params[:report],
          format: method == :to_csv ? "csv" : "xlsx",
          filters: report_filters,
          church_id: @church.id
        }.to_json
      )
      Rails.logger.info(
        "[report_export] church=#{@church.id} user=#{current_user.id} report=#{params[:report]} format=#{method}"
      )
    end

    def report_filters
      params.permit(:status, :month, :ministry_id, :occupation_id, :skill_id, :event_id).to_h
    end
  end
end
```

- [ ] **Step 6: Registrar el MIME type de XLSX (si no existe)**

Verifica si el proyecto ya registra `:xlsx`:
```bash
grep -rn "Mime::Type.register\|:xlsx" config/initializers/
```
Si no aparece `:xlsx`, crear `config/initializers/mime_types.rb` con:

```ruby
Mime::Type.register "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", :xlsx unless Mime::Type.lookup_by_extension(:xlsx)
```

(`:csv` ya viene registrado por Rails.)

- [ ] **Step 7: Crear vistas mínimas para que el HTML responda**

Crear `app/views/church_admin/reports/index.html.erb`:

```erb
<div class="mx-auto w-full max-w-6xl px-6 py-8">
  <h1 class="text-2xl font-semibold text-slate-950">Reportes</h1>

  <% @category_labels.each do |category, category_label| %>
    <% entries = @registry.select { |_key, meta| meta[:category] == category } %>
    <% next if entries.empty? %>

    <section class="mt-8">
      <h2 class="text-lg font-medium text-slate-800"><%= category_label %></h2>
      <div class="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <% entries.each do |key, meta| %>
          <%= link_to church_admin_report_path(current_church, key),
                class: "rounded-lg border border-slate-200 p-4 hover:border-slate-400 hover:bg-slate-50" do %>
            <span class="font-medium text-slate-900"><%= meta[:label] %></span>
          <% end %>
        <% end %>
      </div>
    </section>
  <% end %>
</div>
```

Crear `app/views/church_admin/reports/show.html.erb`:

```erb
<div class="mx-auto w-full max-w-6xl px-6 py-8">
  <div class="flex items-center justify-between">
    <h1 class="text-2xl font-semibold text-slate-950"><%= @report.title %></h1>
    <% if policy(ReportPolicy).export? rescue false %>
      <div class="flex gap-2">
        <%= link_to "CSV", church_admin_report_path(current_church, params[:report], format: :csv, **request.query_parameters),
              class: "rounded-md bg-slate-900 px-3 py-2 text-sm font-medium text-white hover:bg-slate-700" %>
        <%= link_to "Excel", church_admin_report_path(current_church, params[:report], format: :xlsx, **request.query_parameters),
              class: "rounded-md bg-emerald-700 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-600" %>
      </div>
    <% end %>
  </div>

  <div class="mt-6 overflow-x-auto rounded-lg border border-slate-200">
    <table class="min-w-full divide-y divide-slate-200 text-sm">
      <thead class="bg-slate-50">
        <tr>
          <% @report.columns.each do |col| %>
            <th class="px-4 py-2 text-left font-medium text-slate-600"><%= col[:label] %></th>
          <% end %>
        </tr>
      </thead>
      <tbody class="divide-y divide-slate-100">
        <% @rows.each do |row| %>
          <tr>
            <% @report.columns.each do |col| %>
              <td class="px-4 py-2 text-slate-800"><%= row[col[:key]] %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    <% if @rows.empty? %>
      <p class="px-4 py-6 text-center text-slate-500">Sin datos para los filtros seleccionados.</p>
    <% end %>
  </div>
</div>
```

Nota sobre `policy(ReportPolicy).export?`: `policy()` espera una instancia o clase con policy asociada. Para evitar problemas, en la vista se usa el patrón `ReportPolicy.new(current_user, nil).export?`. Reemplaza la condición del bloque de exportación por:

```erb
    <% if ReportPolicy.new(current_user, nil).export? %>
```

- [ ] **Step 8: Ejecutar el spec de request y verificar que pasa**

```bash
bundle exec rspec spec/requests/church_admin/reports_spec.rb
```
Expected: PASS (todos los examples). Depura cualquier fallo (content-type, 404, auditoría) hasta verde.

- [ ] **Step 9: Commit**

```bash
git add app/services/reports/registry.rb app/controllers/church_admin/reports_controller.rb config/routes.rb config/initializers/mime_types.rb app/views/church_admin/reports/ spec/requests/church_admin/reports_spec.rb
git commit -m "feat: controlador de reportes, registro, rutas, exportación y auditoría"
```

---

## Task 10: Navegación e i18n

**Files:**
- Modify: `app/views/shared/_app_navigation.html.erb`
- Modify: `config/locales/es.yml`

- [ ] **Step 1: Agregar el link de navegación**

En `app/views/shared/_app_navigation.html.erb`, después del bloque de "Solicitudes" (`ProfileChangeRequest`) y antes de "Mi perfil", agregar:

```erb
          <% if ReportPolicy.new(current_user, nil).index? %>
            <%= link_to "Reportes", church_admin_reports_path(current_church), class: "rounded-md px-3 py-2 font-medium text-slate-600 hover:bg-slate-100 hover:text-slate-950" %>
          <% end %>
```

- [ ] **Step 2: Verificar manualmente que la app arranca y el link aparece**

```bash
bin/rails runner "puts ReportPolicy.instance_methods(false).inspect"
```
Expected: `[:index?, :show?, :export?]`

- [ ] **Step 3: Agregar textos i18n (opcional pero recomendado)**

En `config/locales/es.yml`, bajo `church_admin:`, agregar una sección `reports:` con títulos si se desea centralizar textos. Como las vistas usan `@report.title` directamente, este paso es opcional; si se agrega, mantener el formato YAML existente. Omitir si no se necesita.

- [ ] **Step 4: Commit**

```bash
git add app/views/shared/_app_navigation.html.erb config/locales/es.yml
git commit -m "feat: link de Reportes en navegación de iglesia"
```

---

## Task 11: Verificación final

- [ ] **Step 1: Suite completa**

```bash
bundle exec rspec --format progress 2>&1 | tail -15
```
Expected: 0 failures.

- [ ] **Step 2: RuboCop**

```bash
bundle exec rubocop app/services/reports/ app/policies/report_policy.rb app/controllers/church_admin/reports_controller.rb app/models/permission.rb
```
Expected: no offenses (corregir con `bundle exec rubocop -a` los de estilo y volver a correr).

- [ ] **Step 3: Brakeman (seguridad)**

```bash
bundle exec brakeman -q 2>&1 | tail -20
```
Expected: sin advertencias nuevas. Revisar especialmente que `send_data` y los filtros de params no introduzcan warnings.

- [ ] **Step 4: Commit de correcciones de estilo (si aplica)**

```bash
git add -A
git commit -m "style: rubocop fixes en módulo de reportes"
```
