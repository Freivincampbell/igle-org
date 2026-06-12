class AddScopeToRolePermissions < ActiveRecord::Migration[8.1]
  def change
    add_column :role_permissions, :scope, :string, null: false, default: "church"
  end
end
