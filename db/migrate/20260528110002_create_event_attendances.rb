class CreateEventAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :event_attendances do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :checked_in_by, foreign_key: { to_table: :users }

      t.boolean :attended, null: false, default: true
      t.datetime :checked_in_at
      t.text :notes

      t.timestamps
    end

    add_index :event_attendances, :public_id, unique: true
    add_index :event_attendances, [ :event_id, :member_id ], unique: true
    add_index :event_attendances, [ :church_id, :event_id ]
  end
end
