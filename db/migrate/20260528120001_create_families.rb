class CreateFamilies < ActiveRecord::Migration[8.1]
  def change
    create_table :families do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true

      t.string :name, null: false
      t.text :notes
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :families, :public_id, unique: true
    add_index :families, [ :church_id, :name ]
    add_index :families, [ :church_id, :status ]
  end
end
