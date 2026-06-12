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
    # church se maneja aparte (sin restricción extra). Módulo sin entrada +
    # scope no-church => relación vacía (deny seguro).
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

    # Alcances que un módulo realmente soporta (church + los que tienen filtro).
    # La UI solo debe ofrecer estos para no producir lockouts silenciosos.
    def self.supported_scopes(module_key)
      ([ "church" ] + SCOPE_FILTERS.fetch(module_key.to_s, {}).keys.map(&:to_s)).uniq
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

      fn = SCOPE_FILTERS.fetch(module_key.to_s, {})[scope]
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
      fn = SCOPE_FILTERS.fetch(module_key.to_s, {})[scope]
      return false if fn.nil?

      base = record.class.where(id: record.id)
      base = base.where(church: user_context.current_church) if record.class.column_names.include?("church_id")
      fn.call(base, user_context).exists?
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
