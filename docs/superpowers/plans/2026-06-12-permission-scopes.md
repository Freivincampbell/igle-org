# Alcances de permisos configurables — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development o executing-plans. Steps con checkbox.

**Goal:** Hacer configurable el alcance (`own`/`assigned_ministry`/`church`) de cada permiso por rol, evaluado de forma centralizada en `PermissionChecker`, con UI en la matriz — sin romper el acceso actual de líderes.

**Architecture:** Spec [2026-06-12-permission-scopes-design.md](../specs/2026-06-12-permission-scopes-design.md). Columna `scope` en `role_permissions`; `UserContext` con `assigned_ministry_ids`; `PermissionChecker` con `allow?(record:)`/`scope_for`/`filter`; policies de members/events/ministries leyendo el alcance; selector de alcance en la matriz. Branch `feature/permission-scopes` (desde develop).

**Tech Stack:** Rails 8.1, PostgreSQL, RSpec. `bundle` SIEMPRE `~/.local/share/mise/installs/ruby/3.4.9/bin/bundle exec ...`. Migraciones test: `RAILS_ENV=test bundle exec rails db:migrate`.

**Módulos con alcance configurable:** `members`, `events`, `ministries`. El resto → solo `church`.

---

### Task 1: Migración + `RolePermission` enum `scope` (TDD)

**Files:**
- Create: `db/migrate/<ts>_add_scope_to_role_permissions.rb`
- Modify: `app/models/role_permission.rb`
- Modify: `spec/models/role_permission_spec.rb` (si no existe, crearlo)

- [ ] **Step 1: Spec que falla** — agregar a `spec/models/role_permission_spec.rb`:

```ruby
  describe "scope" do
    it "por defecto es church" do
      rp = create(:role_permission)
      expect(rp.scope).to eq("church")
    end

    it "acepta own y assigned_ministry" do
      expect(build(:role_permission, scope: "own")).to be_valid
      expect(build(:role_permission, scope: "assigned_ministry")).to be_valid
    end

    it "rechaza un scope inválido" do
      expect { build(:role_permission, scope: "galaxy") }.to raise_error(ArgumentError)
    end
  end
```

(Si el archivo no tiene `require "rails_helper"` + describe, crearlo con la estructura estándar y un `let`/factory. Revisar `spec/factories/role_permissions.rb` para la factory.)

- [ ] **Step 2: Verificar que falla** — `bundle exec rspec spec/models/role_permission_spec.rb` → FAIL.

- [ ] **Step 3: Migración**

```ruby
class AddScopeToRolePermissions < ActiveRecord::Migration[8.1]
  def change
    add_column :role_permissions, :scope, :string, null: false, default: "church"
  end
end
```

Run: `RAILS_ENV=test bundle exec rails db:migrate`; confirmar `db/schema.rb`.

- [ ] **Step 4: Modelo** — en `app/models/role_permission.rb`, tras los `belongs_to`:

```ruby
  SCOPES = %w[own assigned_ministry church].freeze
  enum :scope, SCOPES.index_with(&:itself), default: "church", validate: true
```

- [ ] **Step 5: Verificar** — `bundle exec rspec spec/models/role_permission_spec.rb` → PASS.

- [ ] **Step 6: Rubocop + commit**

```bash
bundle exec rubocop app/models/role_permission.rb db/migrate spec/models/role_permission_spec.rb
git add db/ app/models/role_permission.rb spec/models/role_permission_spec.rb
git commit -m "feat: columna scope en role_permissions (own/assigned_ministry/church)"
```

---

### Task 2: `UserContext` con `assigned_ministry_ids` y `membership_roles` (TDD)

**Files:**
- Modify: `app/services/permissions/user_context.rb`
- Create: `spec/services/permissions/user_context_spec.rb`

- [ ] **Step 1: Spec que falla**

```ruby
require "rails_helper"

RSpec.describe Permissions::UserContext do
  it "expone los ids de ministerios liderados en la iglesia actual" do
    church = create(:church)
    membership = create(:church_membership, church:)
    member = create(:member, church:, user: membership.user)
    led = create(:ministry, church:)
    other = create(:ministry, church:)
    create(:ministry_membership, ministry: led, member:, ministry_role: "leader", status: "active")
    create(:ministry_membership, ministry: other, member:, ministry_role: "member", status: "active")

    context = described_class.new(user: membership.user, current_church: church, church_membership: membership)

    expect(context.assigned_ministry_ids).to contain_exactly(led.id)
  end

  it "devuelve vacío si el usuario no tiene member en la iglesia" do
    church = create(:church)
    membership = create(:church_membership, church:)

    context = described_class.new(user: membership.user, current_church: church, church_membership: membership)

    expect(context.assigned_ministry_ids).to eq([])
  end
end
```

- [ ] **Step 2: Verificar que falla** — `bundle exec rspec spec/services/permissions/user_context_spec.rb` → FAIL.

- [ ] **Step 3: Implementar** — `app/services/permissions/user_context.rb`:

```ruby
module Permissions
  UserContext = Data.define(:user, :current_church, :church_membership) do
    def self.build(user:, current_church:)
      new(
        user:,
        current_church:,
        church_membership: user&.active_membership_for(current_church)
      )
    end

    def membership_roles
      church_membership&.roles&.active || Role.none
    end

    def assigned_ministry_ids
      return [] if user.blank? || current_church.blank?

      member = Member.find_by(user:, church: current_church)
      return [] unless member

      Ministry.joins(:ministry_memberships)
        .where(ministry_memberships: { member:, ministry_role: %w[leader co_leader], status: "active" })
        .ids
    end
  end
end
```

- [ ] **Step 4: Verificar** — PASS.

- [ ] **Step 5: Rubocop + commit**

```bash
bundle exec rubocop app/services/permissions/user_context.rb spec/services/permissions/user_context_spec.rb
git add app/services/permissions/user_context.rb spec/services/permissions/user_context_spec.rb
git commit -m "feat: UserContext expone assigned_ministry_ids y membership_roles"
```

---

### Task 3: `PermissionChecker` con scope (`allow?(record:)`, `scope_for`, `filter`) (TDD)

**Files:**
- Modify: `app/services/permissions/permission_checker.rb`
- Modify: `spec/services/permissions/permission_checker_spec.rb`

- [ ] **Step 1: Specs que fallan** — agregar a `permission_checker_spec.rb`:

```ruby
  describe "alcances" do
    def context_for(membership)
      Permissions::UserContext.new(user: membership.user, current_church: membership.church, church_membership: membership)
    end

    def grant(role:, module_key:, action:, scope:)
      perm = Permission.find_by(module_key:, action_key: action) ||
             create(:permission, module_key:, action_key: action, name: "#{module_key} #{action}")
      create(:role_permission, role:, permission: perm, scope:)
    end

    it "scope_for devuelve el alcance configurado" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      grant(role:, module_key: "members", action: "read", scope: "assigned_ministry")

      result = described_class.scope_for(user_context: context_for(membership), module_key: "members", action: "read")

      expect(result).to eq(:assigned_ministry)
    end

    it "devuelve el alcance más amplio entre roles (church gana)" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role_a = create(:role, church:)
      role_b = create(:role, church:)
      create(:membership_role, church_membership: membership, role: role_a)
      create(:membership_role, church_membership: membership, role: role_b)
      grant(role: role_a, module_key: "members", action: "read", scope: "own")
      grant(role: role_b, module_key: "members", action: "read", scope: "church")

      result = described_class.scope_for(user_context: context_for(membership), module_key: "members", action: "read")

      expect(result).to eq(:church)
    end

    it "filter por own devuelve solo el member del usuario" do
      church = create(:church)
      membership = create(:church_membership, church:)
      own_member = create(:member, church:, user: membership.user)
      _other = create(:member, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      grant(role:, module_key: "members", action: "read", scope: "own")

      relation = described_class.filter(user_context: context_for(membership), module_key: "members", action: "read", relation: church.members)

      expect(relation).to contain_exactly(own_member)
    end

    it "filter por assigned_ministry devuelve solo miembros de ministerios liderados" do
      church = create(:church)
      membership = create(:church_membership, church:)
      leader_member = create(:member, church:, user: membership.user)
      led = create(:ministry, church:)
      create(:ministry_membership, ministry: led, member: leader_member, ministry_role: "leader", status: "active")
      teammate = create(:member, church:)
      create(:ministry_membership, ministry: led, member: teammate, ministry_role: "member", status: "active")
      outsider = create(:member, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      grant(role:, module_key: "members", action: "read", scope: "assigned_ministry")

      relation = described_class.filter(user_context: context_for(membership), module_key: "members", action: "read", relation: church.members)

      expect(relation).to include(teammate)
      expect(relation).not_to include(outsider)
    end

    it "allow? con record fuera del alcance own devuelve false" do
      church = create(:church)
      membership = create(:church_membership, church:)
      create(:member, church:, user: membership.user)
      other = create(:member, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      grant(role:, module_key: "members", action: "read", scope: "own")

      allowed = described_class.allow?(user_context: context_for(membership), module_key: "members", action: "read", record: other)

      expect(allowed).to be(false)
    end

    it "owner siempre tiene alcance church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      result = described_class.scope_for(user_context: context_for(membership), module_key: "members", action: "read")

      expect(result).to eq(:church)
    end
  end
```

- [ ] **Step 2: Verificar que falla** — `bundle exec rspec spec/services/permissions/permission_checker_spec.rb` → FAIL.

- [ ] **Step 3: Reescribir `PermissionChecker`** — `app/services/permissions/permission_checker.rb`:

```ruby
module Permissions
  class PermissionChecker
    ADMIN_BOOTSTRAP_EXCLUDED_MODULES = %w[pastoral_notes].freeze
    ACTION_PERMISSION_KEYS = {
      "read" => %w[read create manage],
      "create" => %w[create manage],
      "update" => %w[create manage],
      "activate" => %w[manage],
      "deactivate" => %w[manage],
      "export" => %w[manage],
      "manage" => %w[manage]
    }.freeze

    SCOPE_RANK = { "own" => 0, "assigned_ministry" => 1, "church" => 2 }.freeze

    # Filtros por módulo: cómo se acota una relación según el alcance.
    # church se maneja aparte (where church:). Módulo sin entrada + scope
    # no-church => relación vacía (deny seguro).
    SCOPE_FILTERS = {
      "members" => {
        own: ->(relation, ctx) { relation.where(user_id: ctx.user.id) },
        assigned_ministry: lambda do |relation, ctx|
          relation.where(id: Member.joins(:ministry_memberships)
            .where(ministry_memberships: { ministry_id: ctx.assigned_ministry_ids, status: "active" }))
        end
      },
      "events" => {
        assigned_ministry: ->(relation, ctx) { relation.where(ministry_id: ctx.assigned_ministry_ids) }
      },
      "ministries" => {
        assigned_ministry: ->(relation, ctx) { relation.where(id: ctx.assigned_ministry_ids) }
      }
    }.freeze

    def self.allow?(...)
      new.allow?(...)
    end

    def self.scope_for(...)
      new.scope_for(...)
    end

    def self.filter(...)
      new.filter(...)
    end

    def self.permission_action_keys_for(action)
      ACTION_PERMISSION_KEYS.fetch(action.to_s, [ action.to_s ])
    end

    def allow?(user_context:, module_key:, action:, record: nil)
      scope = scope_for(user_context:, module_key:, action:)
      return false if scope.nil?
      return true if record.nil? || scope == :church

      record_in_scope?(scope, module_key, record, user_context)
    end

    def scope_for(user_context:, module_key:, action:)
      return nil unless valid_context?(user_context)

      membership = user_context.church_membership
      return :church if membership.owner? && owner_allowed?(module_key)

      scopes = membership.roles.active
        .joins(role_permissions: :permission)
        .where(permissions: permission_filter(module_key, action))
        .pluck("role_permissions.scope")
      return nil if scopes.empty?

      scopes.max_by { |s| SCOPE_RANK.fetch(s, -1) }.to_sym
    end

    def filter(user_context:, module_key:, action:, relation:)
      scope = scope_for(user_context:, module_key:, action:)
      return relation.none if scope.nil?
      return relation if scope == :church

      filters = SCOPE_FILTERS.fetch(module_key.to_s, {})
      fn = filters[scope]
      return relation.none if fn.nil?

      fn.call(relation, user_context)
    end

    private

    def valid_context?(user_context)
      return false unless user_context&.user
      return false unless user_context.current_church

      user_context.church_membership&.active?
    end

    def record_in_scope?(scope, module_key, record, user_context)
      filters = SCOPE_FILTERS.fetch(module_key.to_s, {})
      fn = filters[scope]
      return false if fn.nil?

      fn.call(record.class.where(id: record.id), user_context).exists?
    end

    def owner_allowed?(module_key)
      ADMIN_BOOTSTRAP_EXCLUDED_MODULES.exclude?(module_key.to_s)
    end

    def permission_filter(module_key, action)
      {
        module_key: module_key.to_s,
        action_key: self.class.permission_action_keys_for(action)
      }
    end
  end
end
```

Nota: el `allow?(user_context:, module_key:, action:)` sin `record` mantiene compatibilidad (las policies existentes lo llaman así) — devuelve `true` si hay algún alcance.

- [ ] **Step 4: Verificar** — `bundle exec rspec spec/services/permissions/permission_checker_spec.rb` → PASS (nuevos + existentes).

- [ ] **Step 5: Rubocop + commit**

```bash
bundle exec rubocop app/services/permissions/permission_checker.rb spec/services/permissions/permission_checker_spec.rb
git add app/services/permissions/permission_checker.rb spec/services/permissions/permission_checker_spec.rb
git commit -m "feat: PermissionChecker evalúa alcance (scope_for, filter, allow? por record)"
```

---

### Task 4: Policies de members/events/ministries leen el alcance (TDD)

**Files:**
- Modify: `app/policies/member_policy.rb`
- Modify: `app/policies/event_policy.rb`
- Modify: `app/policies/ministry_policy.rb`
- Modify: `app/policies/application_policy.rb` (helper)
- Modify: `spec/policies/member_policy_spec.rb`, `event_policy_spec.rb`, `ministry_policy_spec.rb`

- [ ] **Step 1: Specs que fallan** — en `spec/policies/member_policy_spec.rb`, agregar al `describe "scope"`:

```ruby
    it "con scope own devuelve solo el member del usuario" do
      church = create(:church)
      membership = create(:church_membership, church:)
      own = create(:member, church:, user: membership.user)
      create(:member, church:)
      role = create(:role, church:)
      create(:membership_role, church_membership: membership, role:)
      perm = Permission.find_by(module_key: "members", action_key: "read") ||
             create(:permission, module_key: "members", action_key: "read", name: "Miembros leer")
      create(:role_permission, role:, permission: perm, scope: "own")

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Member).resolve
        expect(resolved).to contain_exactly(own)
      end
    end
```

(Análogo: para `assigned_ministry` en member/event/ministry, comprobar que `Scope.resolve` filtra; reutilizar el patrón de `ministry_policy_spec` existente que ya prueba led-ministries.)

- [ ] **Step 2: Verificar que falla** — FAIL.

- [ ] **Step 3: Helper en `ApplicationPolicy`** (sección `Scope`) y refactor de los `resolve`. En `ApplicationPolicy::Scope`, agregar:

```ruby
      def permission_filter(module_key, action_key, relation)
        Permissions::PermissionChecker.filter(
          user_context: Permissions::UserContext.new(user:, current_church:, church_membership: current_membership),
          module_key:, action: action_key, relation:
        )
      end
```

`MemberPolicy::Scope#resolve`:

```ruby
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      permission_filter("members", "read", scope.where(church: current_church))
    end
```

`MinistryPolicy::Scope#resolve` y `EventPolicy::Scope#resolve`: reemplazar la
lógica hardcodeada por la **unión** del filtro configurado y los ministerios
liderados (preservar acceso de líder):

```ruby
    # MinistryPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      configured = permission_filter("ministries", "read", scope.where(church: current_church))
      led = user_led_ministries
      scope.where(id: configured.select(:id)).or(scope.where(id: led.select(:id)))
    end
```

```ruby
    # EventPolicy::Scope
    def resolve
      return scope.all if super_admin?
      return scope.none if current_church.blank?
      return scope.none unless current_membership&.active?

      configured = permission_filter("events", "read", scope.where(church: current_church))
      led_ids = user_led_ministries.ids
      scope.where(id: configured.select(:id)).or(scope.where(church: current_church, ministry_id: led_ids))
    end
```

(Los `show?`/`update?` por record mantienen su `permission?(...) || ministry_leader_of?(...)` actual — no se tocan, el fallback de líder sigue.)

- [ ] **Step 4: Verificar** — `bundle exec rspec spec/policies/` → PASS.

- [ ] **Step 5: Rubocop + commit**

```bash
bundle exec rubocop app/policies spec/policies
git add app/policies spec/policies
git commit -m "feat: policies de members/events/ministries respetan el alcance configurado"
```

---

### Task 5: `RoleMatrixAssignment` guarda alcance por módulo (TDD)

**Files:**
- Modify: `app/services/permissions/role_matrix_assignment.rb`
- Modify: `spec/services/permissions/role_matrix_assignment_spec.rb`

- [ ] **Step 1: Specs que fallan**

```ruby
  it "guarda el scope indicado por módulo" do
    church = create(:church)
    role = create(:role, church:)
    perm = Permission.find_by(module_key: "members", action_key: "read") ||
           create(:permission, module_key: "members", action_key: "read", name: "Miembros leer")

    assignment = described_class.new(role:, permission_public_ids: [ perm.public_id ],
                                     module_scopes: { "members" => "assigned_ministry" })
    expect(assignment.save).to be(true)
    expect(role.role_permissions.find_by(permission: perm).scope).to eq("assigned_ministry")
  end

  it "fuerza church en módulos no configurables" do
    church = create(:church)
    role = create(:role, church:)
    perm = Permission.find_by(module_key: "roles", action_key: "read") ||
           create(:permission, module_key: "roles", action_key: "read", name: "Roles leer")

    assignment = described_class.new(role:, permission_public_ids: [ perm.public_id ],
                                     module_scopes: { "roles" => "own" })
    assignment.save
    expect(role.role_permissions.find_by(permission: perm).scope).to eq("church")
  end
```

- [ ] **Step 2: Verificar que falla** — FAIL.

- [ ] **Step 3: Implementar** — `role_matrix_assignment.rb`:

```ruby
module Permissions
  class RoleMatrixAssignment
    include ActiveModel::Model

    SCOPE_CONFIGURABLE_MODULES = %w[members events ministries].freeze

    attr_accessor :role, :permission_public_ids, :module_scopes

    validates :role, presence: true
    validate :selected_permissions_exist

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        role.role_permissions.where.not(permission_id: selected_permissions.map(&:id)).delete_all
        selected_permissions.each do |permission|
          rp = role.role_permissions.find_or_initialize_by(permission:)
          rp.scope = scope_for(permission)
          rp.save!
        end
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      errors.add(:base, error.record.errors.full_messages.to_sentence)
      false
    end

    private

    def scope_for(permission)
      return "church" unless SCOPE_CONFIGURABLE_MODULES.include?(permission.module_key)

      requested = normalized_module_scopes[permission.module_key].to_s
      RolePermission::SCOPES.include?(requested) ? requested : "church"
    end

    def normalized_module_scopes
      hash = module_scopes
      if hash.respond_to?(:to_unsafe_h)
        hash.to_unsafe_h
      elsif hash.respond_to?(:to_h)
        hash.to_h
      else
        {}
      end
    end

    def selected_permissions
      @selected_permissions ||= Permission.assignable.where(public_id: normalized_permission_public_ids).to_a
    end

    def normalized_permission_public_ids
      Array(permission_public_ids).compact_blank.uniq
    end

    def selected_permissions_exist
      return if normalized_permission_public_ids.size == selected_permissions.size

      errors.add(:base, :invalid)
    end
  end
end
```

- [ ] **Step 4: Verificar** — `bundle exec rspec spec/services/permissions/role_matrix_assignment_spec.rb` → PASS.

- [ ] **Step 5: Rubocop + commit**

```bash
bundle exec rubocop app/services/permissions/role_matrix_assignment.rb spec/services/permissions/role_matrix_assignment_spec.rb
git add app/services/permissions/role_matrix_assignment.rb spec/services/permissions/role_matrix_assignment_spec.rb
git commit -m "feat: RoleMatrixAssignment persiste alcance por módulo configurable"
```

---

### Task 6: UI de la matriz con selector de alcance (TDD)

**Files:**
- Modify: `app/controllers/church_admin/roles_controller.rb` (`update_permissions` pasa `module_scopes`)
- Modify: `app/views/church_admin/roles/_permission_matrix.html.erb`
- Modify: `spec/requests/church_admin/roles_spec.rb`

- [ ] **Step 1: Request spec que falla** — agregar a `roles_spec.rb`:

```ruby
    it "guarda un permiso con alcance assigned_ministry desde la matriz" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      role = create(:role, church:)
      perm = Permission.find_by(module_key: "members", action_key: "read") ||
             create(:permission, module_key: "members", action_key: "read", name: "Miembros leer")
      sign_in membership.user

      patch permissions_church_admin_role_path(church, role), params: {
        role: { permission_public_ids: [ perm.public_id ], module_scopes: { "members" => "assigned_ministry" } }
      }

      expect(role.role_permissions.find_by(permission: perm).scope).to eq("assigned_ministry")
    end
```

(Revisar el patrón de sign-in/owner en `roles_spec.rb`; si no existe el describe de permissions, agregarlo.)

- [ ] **Step 2: Verificar que falla** — FAIL.

- [ ] **Step 3: Controller** — en `update_permissions`, pasar el scope:

```ruby
      assignment = Permissions::RoleMatrixAssignment.new(
        role: @role,
        permission_public_ids: role_permission_params,
        module_scopes: params.dig(:role, :module_scopes)
      )
```

- [ ] **Step 4: Vista** — en `_permission_matrix.html.erb`, dentro de cada `<section>` de módulo, para los módulos configurables (`%w[members events ministries]`), agregar un selector de alcance:

```erb
        <% if Permissions::RoleMatrixAssignment::SCOPE_CONFIGURABLE_MODULES.include?(module_key) %>
          <% current_scope = role.role_permissions.joins(:permission).where(permissions: { module_key: }).first&.scope || "church" %>
          <div class="mt-3">
            <label class="text-xs font-medium uppercase tracking-wide text-slate-500">Alcance</label>
            <select name="role[module_scopes][<%= module_key %>]"
                    class="mt-1 block rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-500/20">
              <% { "church" => "Toda la iglesia", "assigned_ministry" => "Ministerio asignado", "own" => "Propio" }.each do |value, label| %>
                <option value="<%= value %>" <%= "selected" if current_scope == value %>><%= label %></option>
              <% end %>
            </select>
          </div>
        <% end %>
```

(Insertarlo después del bloque de botones de atajo y antes del grid de checkboxes, o donde calce visualmente.)

- [ ] **Step 5: Verificar** — `bundle exec rspec spec/requests/church_admin/roles_spec.rb` → PASS.

- [ ] **Step 6: Rubocop + commit**

```bash
bundle exec rubocop app/controllers/church_admin/roles_controller.rb spec/requests/church_admin/roles_spec.rb
git add app/controllers/church_admin/roles_controller.rb app/views/church_admin/roles/_permission_matrix.html.erb spec/requests/church_admin/roles_spec.rb
git commit -m "feat: selector de alcance por módulo en la matriz de permisos"
```

---

### Task 7: Verificación final

- [ ] `bundle exec rspec` → 0 failures
- [ ] `bundle exec rubocop` → no offenses
- [ ] `bundle exec brakeman --no-pager` → 0 warnings
- [ ] Reglas: la lógica de alcance vive solo en `PermissionChecker`; owner sigue con church; pastoral_notes intacto; aislamiento con dos iglesias cubierto.
- [ ] Manual (`bin/dev`): crear un rol con `members:read` scope `assigned_ministry`, asignarlo a un usuario líder, verificar que en el panel solo ve miembros de su ministerio.

## Follow-ups
- `effective_permissions` para uso futuro / vista de "permisos efectivos".
- `PermissionEffectiveCache` (caché por request).
- Extender alcance a más módulos cuando haya casos reales.
