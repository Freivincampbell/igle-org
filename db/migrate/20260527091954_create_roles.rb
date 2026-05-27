class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.references :church, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :roles, [ :church_id, :name ], unique: true
    add_index :roles, :status
  end
end
