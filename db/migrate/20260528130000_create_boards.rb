class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true

      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on
      t.string :status, null: false, default: "active"
      t.text :notes

      t.timestamps
    end

    add_index :boards, :public_id, unique: true
    add_index :boards, [ :church_id, :starts_on ]
    add_index :boards, [ :church_id, :status ]
  end
end
