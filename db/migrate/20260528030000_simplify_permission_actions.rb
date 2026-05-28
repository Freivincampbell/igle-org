class SimplifyPermissionActions < ActiveRecord::Migration[8.1]
  PERMISSION_MODULES = %w[
    church_memberships
    roles
    members
    ministries
  ].freeze
  ACTION_LABELS = {
    "read" => "Leer",
    "create" => "Crear/editar",
    "manage" => "Administrar"
  }.freeze
  MODULE_LABELS = {
    "church_memberships" => "Usuarios de iglesia",
    "roles" => "Roles",
    "members" => "Miembros",
    "ministries" => "Ministerios"
  }.freeze
  ACTION_MAP = {
    "read" => "read",
    "create" => "create",
    "update" => "create",
    "activate" => "manage",
    "deactivate" => "manage",
    "export" => "manage",
    "manage" => "manage"
  }.freeze

  def up
    permission_record = Class.new(ActiveRecord::Base) { self.table_name = "permissions" }
    role_permission_record = Class.new(ActiveRecord::Base) { self.table_name = "role_permissions" }

    permission_record.transaction do
      PERMISSION_MODULES.each_with_index do |module_key, module_index|
        ACTION_LABELS.keys.each_with_index do |action_key, action_index|
          permission = permission_record.find_or_initialize_by(module_key:, action_key:)
          permission.name = "#{MODULE_LABELS.fetch(module_key)} - #{ACTION_LABELS.fetch(action_key)}"
          permission.position = (module_index * 100) + action_index
          permission.save!
        end
      end

      permission_record.where(module_key: PERMISSION_MODULES).find_each do |permission|
        target_action = ACTION_MAP[permission.action_key]
        next if target_action.blank? || target_action == permission.action_key

        target_permission = permission_record.find_by!(module_key: permission.module_key, action_key: target_action)

        role_permission_record.where(permission_id: permission.id).find_each do |role_permission|
          duplicate = role_permission_record.exists?(
            role_id: role_permission.role_id,
            permission_id: target_permission.id
          )

          if duplicate
            role_permission.destroy!
          else
            role_permission.update!(permission_id: target_permission.id)
          end
        end
      end

      permissions_to_delete = permission_record
        .where.not(module_key: PERMISSION_MODULES)
        .or(permission_record.where.not(action_key: ACTION_LABELS.keys))

      role_permission_record.where(permission_id: permissions_to_delete.select(:id)).delete_all
      permissions_to_delete.delete_all

      permission_record.where(module_key: PERMISSION_MODULES).find_each do |permission|
        module_index = PERMISSION_MODULES.index(permission.module_key)
        action_index = ACTION_LABELS.keys.index(permission.action_key)
        permission.update!(
          name: "#{MODULE_LABELS.fetch(permission.module_key)} - #{ACTION_LABELS.fetch(permission.action_key)}",
          position: (module_index * 100) + action_index
        )
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
