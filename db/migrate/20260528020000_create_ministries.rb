class CreateMinistries < ActiveRecord::Migration[8.1]
  def change
    create_table :ministries do |t|
      t.references :church, null: false, foreign_key: true
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :ministries, :public_id, unique: true
    add_index :ministries, [ :church_id, :name ], unique: true
    add_index :ministries, [ :church_id, :status ]
  end
end
