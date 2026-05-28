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

    def self.allow?(...)
      new.allow?(...)
    end

    def self.permission_action_keys_for(action)
      ACTION_PERMISSION_KEYS.fetch(action.to_s, [ action.to_s ])
    end

    def allow?(user_context:, module_key:, action:)
      return false unless user_context&.user
      return false unless user_context.current_church

      membership = user_context.church_membership
      return false unless membership&.active?
      return owner_allowed?(module_key) if membership.owner?

      membership.roles.active
        .joins(role_permissions: :permission)
        .where(permissions: permission_filter(module_key, action))
        .exists?
    end

    private

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
