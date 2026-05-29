class CreateOccupations < ActiveRecord::Migration[8.1]
  def change
    create_table :occupations do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :occupations, :public_id, unique: true
    add_index :occupations, [ :church_id, :name ], unique: true
  end
end
