class AddPastoralToRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :roles, :pastoral, :boolean, null: false, default: false
    add_index :roles, [ :church_id, :pastoral ]
  end
end
