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
          role_permission = role.role_permissions.find_or_initialize_by(permission:)
          role_permission.scope = scope_for(permission)
          role_permission.save!
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
      @normalized_module_scopes ||= if module_scopes.respond_to?(:to_unsafe_h)
        module_scopes.to_unsafe_h
      elsif module_scopes.respond_to?(:to_h)
        module_scopes.to_h
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
