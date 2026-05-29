# Etapa 9 — Alcance `assigned_ministry` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que líderes y co-líderes de ministerio administren solo su ministerio y vean únicamente los eventos de ese ministerio, derivando el alcance implícitamente desde `MinistryMembership.ministry_role`.

**Architecture:** Se agregan helpers privados `ministry_leader_of?(ministry)` y `user_led_ministries` a `ApplicationPolicy` y a `ApplicationPolicy::Scope`. `MinistryPolicy` y `EventPolicy` los usan para ampliar sus chequeos de acción y sus Scopes. Sin migraciones ni cambios al `PermissionChecker`.

**Tech Stack:** Ruby on Rails 8, Pundit, RSpec, FactoryBot.

---

## Mapa de archivos

| Archivo | Acción |
|---|---|
| `app/policies/application_policy.rb` | Modificar — agregar helpers privados en la clase principal y en `Scope` |
| `app/policies/ministry_policy.rb` | Modificar — acciones + Scope |
| `app/policies/event_policy.rb` | Modificar — acciones + Scope |
| `spec/policies/ministry_policy_spec.rb` | Modificar — agregar casos de líder |
| `spec/policies/event_policy_spec.rb` | Crear — tests de Scope y acciones para líderes |

---

## Task 1: Helpers de liderazgo en `ApplicationPolicy`

**Files:**
- Modify: `app/policies/application_policy.rb`
- Test: `spec/policies/ministry_policy_spec.rb` (los helpers se prueban indirectamente en Task 2)

- [ ] **Step 1: Agregar `ministry_leader_of?` y `user_led_ministries` a `ApplicationPolicy`**

En `app/policies/application_policy.rb`, dentro del bloque `private` de la clase principal (después de `same_church?`), agregar:

```ruby
def ministry_leader_of?(ministry)
  return false unless active_church_member?

  current_member = Member.find_by(user:, church: current_church)
  return false unless current_member

  MinistryMembership.exists?(
    ministry: ministry,
    member: current_member,
    ministry_role: %w[leader co_leader],
    status: "active"
  )
end

def user_led_ministries
  current_member = Member.find_by(user:, church: current_church)
  return Ministry.none unless current_member

  Ministry.joins(:ministry_memberships)
    .where(
      ministry_memberships: {
        member: current_member,
        ministry_role: %w[leader co_leader],
        status: "active"
      }
    )
end
```

- [ ] **Step 2: Agregar los mismos helpers al `ApplicationPolicy::Scope`**

Dentro de `class Scope`, en el bloque `private` (después de `current_membership`), agregar:

```ruby
def owner?
  current_membership&.owner?
end

def permission?(module_key, action_key)
  return false unless current_membership&.active?

  Permissions::PermissionChecker.allow?(
    user_context: Permissions::UserContext.new(
      user:,
      current_church:,
      church_membership: current_membership
    ),
    module_key:,
    action: action_key
  )
end

def ministry_leader_of?(ministry)
  return false unless current_membership&.active?

  current_member = Member.find_by(user:, church: current_church)
  return false unless current_member

  MinistryMembership.exists?(
    ministry: ministry,
    member: current_member,
    ministry_role: %w[leader co_leader],
    status: "active"
  )
end

def user_led_ministries
  current_member = Member.find_by(user:, church: current_church)
  return Ministry.none unless current_member

  Ministry.joins(:ministry_memberships)
    .where(
      ministry_memberships: {
        member: current_member,
        ministry_role: %w[leader co_leader],
        status: "active"
      }
    )
end
```

- [ ] **Step 3: Verificar que la app arranca sin errores**

```bash
bin/rails runner "puts 'OK'"
```
Expected: `OK`

---

## Task 2: Actualizar `MinistryPolicy`

**Files:**
- Modify: `app/policies/ministry_policy.rb`
- Modify: `spec/policies/ministry_policy_spec.rb`

- [ ] **Step 1: Escribir los tests que deben fallar**

Agregar al final de `spec/policies/ministry_policy_spec.rb`, antes del último `end`:

```ruby
describe "ministry leader implicit scope" do
  let(:church) { create(:church) }
  let(:user) { create(:user) }
  let(:membership) { create(:church_membership, user:, church:) }
  let(:member) { create(:member, user:, church:) }
  let(:ministry) { create(:ministry, church:) }
  let(:other_ministry) { create(:ministry, church:) }

  before do
    Current.set(user:, church:, church_membership: membership) do
      # se ejecuta dentro del bloque
    end
  end

  it "allows show? when user is leader of that ministry" do
    create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

    Current.set(user:, church:, church_membership: membership) do
      expect(described_class.new(user, ministry).show?).to be(true)
    end
  end

  it "allows show? when user is co_leader of that ministry" do
    create(:ministry_membership, member:, ministry:, ministry_role: :co_leader, status: :active)

    Current.set(user:, church:, church_membership: membership) do
      expect(described_class.new(user, ministry).show?).to be(true)
    end
  end

  it "denies show? when user is only member (not leader) of the ministry" do
    create(:ministry_membership, member:, ministry:, ministry_role: :member, status: :active)

    Current.set(user:, church:, church_membership: membership) do
      expect(described_class.new(user, ministry).show?).to be(false)
    end
  end

  it "denies show? for a ministry where the user is not a leader" do
    create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

    Current.set(user:, church:, church_membership: membership) do
      expect(described_class.new(user, other_ministry).show?).to be(false)
    end
  end

  it "allows update? when user is leader of that ministry" do
    create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

    Current.set(user:, church:, church_membership: membership) do
      expect(described_class.new(user, ministry).update?).to be(true)
    end
  end

  describe "Scope" do
    it "returns only led ministries when user has no church-wide permission" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Ministry).resolve
        expect(resolved).to contain_exactly(ministry)
      end
    end

    it "returns no ministries when user is not a leader anywhere" do
      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Ministry).resolve
        expect(resolved).to be_empty
      end
    end

    it "returns all church ministries when user has church-wide permission" do
      role = create(:role, church:)
      perm = Permission.find_by(module_key: "ministries", action_key: "read") ||
             create(:permission, module_key: "ministries", action_key: "read", name: "Ministerios - Leer")
      create(:role_permission, role:, permission: perm)
      create(:membership_role, church_membership: membership, role:)

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Ministry).resolve
        expect(resolved).to contain_exactly(ministry, other_ministry)
      end
    end
  end
end
```

- [ ] **Step 2: Ejecutar los tests nuevos y verificar que fallan**

```bash
bundle exec rspec spec/policies/ministry_policy_spec.rb --format documentation 2>&1 | tail -30
```
Expected: varios failures con "expected true got false" o similar.

- [ ] **Step 3: Actualizar `MinistryPolicy` — acciones individuales**

Reemplazar el contenido de `app/policies/ministry_policy.rb` con:

```ruby
class MinistryPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("ministries", "read") || user_led_ministries.any?
  end

  def show?
    super_admin? || (same_church? && (permission?("ministries", "read") || ministry_leader_of?(record)))
  end

  def create?
    super_admin? || permission?("ministries", "create")
  end

  def update?
    super_admin? || (same_church? && (permission?("ministries", "update") || ministry_leader_of?(record)))
  end

  def activate?
    super_admin? || (same_church? && (permission?("ministries", "activate") || ministry_leader_of?(record)))
  end

  def deactivate?
    super_admin? || (same_church? && (permission?("ministries", "deactivate") || ministry_leader_of?(record)))
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      return scope.where(church: current_church) if owner? || permission?("ministries", "read")

      led = user_led_ministries
      led.any? ? led : scope.none
    end
  end
end
```

- [ ] **Step 4: Ejecutar todos los tests de MinistryPolicy**

```bash
bundle exec rspec spec/policies/ministry_policy_spec.rb --format documentation
```
Expected: todos en verde.

- [ ] **Step 5: Commit**

```bash
git add app/policies/application_policy.rb app/policies/ministry_policy.rb spec/policies/ministry_policy_spec.rb
git commit -m "feat: alcance assigned_ministry en MinistryPolicy para líderes de ministerio"
```

---

## Task 3: Actualizar `EventPolicy`

**Files:**
- Modify: `app/policies/event_policy.rb`
- Create: `spec/policies/event_policy_spec.rb`

- [ ] **Step 1: Crear el archivo de specs**

Crear `spec/policies/event_policy_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe EventPolicy do
  let(:church) { create(:church) }
  let(:user) { create(:user) }
  let(:membership) { create(:church_membership, user:, church:) }
  let(:member) { create(:member, user:, church:) }
  let(:ministry) { create(:ministry, church:) }
  let(:other_ministry) { create(:ministry, church:) }
  let(:event_in_ministry) { create(:event, church:, ministry:) }
  let(:event_in_other_ministry) { create(:event, church:, ministry: other_ministry) }
  let(:event_no_ministry) { create(:event, church:, ministry: nil) }

  describe "show? for ministry leader" do
    it "allows show? when user is leader of the event's ministry" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, event_in_ministry).show?).to be(true)
      end
    end

    it "denies show? for event in a ministry where user is not leader" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, event_in_other_ministry).show?).to be(false)
      end
    end

    it "denies show? for event with no ministry when user is only a leader" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, event_no_ministry).show?).to be(false)
      end
    end
  end

  describe "Scope" do
    it "returns only events of led ministries when user has no church-wide permission" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)
      event_in_ministry
      event_in_other_ministry
      event_no_ministry

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Event).resolve
        expect(resolved).to contain_exactly(event_in_ministry)
      end
    end

    it "returns no events when user is not a leader anywhere and has no permission" do
      event_in_ministry
      event_no_ministry

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Event).resolve
        expect(resolved).to be_empty
      end
    end

    it "returns all church events when user has church-wide events permission" do
      role = create(:role, church:)
      perm = Permission.find_by(module_key: "events", action_key: "read") ||
             create(:permission, module_key: "events", action_key: "read", name: "Eventos - Leer")
      create(:role_permission, role:, permission: perm)
      create(:membership_role, church_membership: membership, role:)
      event_in_ministry
      event_in_other_ministry
      event_no_ministry

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Event).resolve
        expect(resolved).to contain_exactly(event_in_ministry, event_in_other_ministry, event_no_ministry)
      end
    end

    it "does not return events from another church" do
      other_church = create(:church)
      other_event = create(:event, church: other_church)
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Event).resolve
        expect(resolved).not_to include(other_event)
      end
    end

    it "returns all events for owner" do
      owner_membership = create(:church_membership, :owner, church:)
      event_in_ministry
      event_no_ministry

      Current.set(user: owner_membership.user, church:, church_membership: owner_membership) do
        resolved = described_class::Scope.new(owner_membership.user, Event).resolve
        expect(resolved).to contain_exactly(event_in_ministry, event_no_ministry)
      end
    end
  end
end
```

- [ ] **Step 2: Ejecutar los tests y verificar que fallan**

```bash
bundle exec rspec spec/policies/event_policy_spec.rb --format documentation 2>&1 | tail -30
```
Expected: múltiples failures (Scope devuelve todos los eventos de la iglesia en vez de filtrar).

- [ ] **Step 3: Actualizar `EventPolicy`**

Reemplazar el contenido de `app/policies/event_policy.rb` con:

```ruby
class EventPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("events", "read") || user_led_ministries.any?
  end

  def show?
    super_admin? || (same_church? && (permission?("events", "read") || leader_of_event_ministry?))
  end

  def create?
    super_admin? || permission?("events", "create")
  end

  def update?
    super_admin? || (same_church? && (permission?("events", "update") || leader_of_event_ministry?))
  end

  def activate?
    super_admin? || (same_church? && (permission?("events", "activate") || leader_of_event_ministry?))
  end

  def deactivate?
    super_admin? || (same_church? && (permission?("events", "deactivate") || leader_of_event_ministry?))
  end

  def attendance?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      return scope.where(church: current_church) if owner? || permission?("events", "read")

      led_ids = user_led_ministries.ids
      return scope.none if led_ids.empty?

      scope.where(church: current_church, ministry_id: led_ids)
    end
  end

  private

  def leader_of_event_ministry?
    record.ministry.present? && ministry_leader_of?(record.ministry)
  end
end
```

- [ ] **Step 4: Ejecutar todos los tests de EventPolicy**

```bash
bundle exec rspec spec/policies/event_policy_spec.rb --format documentation
```
Expected: todos en verde.

- [ ] **Step 5: Ejecutar la suite completa para detectar regresiones**

```bash
bundle exec rspec --format progress 2>&1 | tail -20
```
Expected: 0 failures.

- [ ] **Step 6: Commit final**

```bash
git add app/policies/event_policy.rb spec/policies/event_policy_spec.rb
git commit -m "feat: alcance assigned_ministry en EventPolicy — líderes ven solo eventos de su ministerio"
```

---

## Verificación final

- [ ] Correr RuboCop sobre los archivos tocados:

```bash
bundle exec rubocop app/policies/application_policy.rb app/policies/ministry_policy.rb app/policies/event_policy.rb
```
Expected: no offenses (o corregir con `rubocop -a` si hay offenses de estilo).

- [ ] Commit de correcciones de estilo si aplica:

```bash
git add app/policies/
git commit -m "style: rubocop fixes en policies de etapa 9"
```
