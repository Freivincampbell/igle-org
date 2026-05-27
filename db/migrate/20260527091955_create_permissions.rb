class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions do |t|
      t.string :module_key, null: false
      t.string :action_key, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :permissions, [ :module_key, :action_key ], unique: true
    add_index :permissions, :position
  end
end
