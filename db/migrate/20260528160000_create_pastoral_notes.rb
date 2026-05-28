class CreatePastoralNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :pastoral_notes do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :pastor, null: false, foreign_key: { to_table: :users }

      t.string :title
      t.text :body, null: false
      t.string :note_type, null: false, default: "general"

      t.timestamps
    end

    add_index :pastoral_notes, :public_id, unique: true
    add_index :pastoral_notes, [ :church_id, :member_id ]
    add_index :pastoral_notes, [ :church_id, :note_type ]
  end
end
