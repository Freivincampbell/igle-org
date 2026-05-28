class CreateEventRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :event_rsvps do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true

      t.string :status, null: false, default: "attending"
      t.integer :guests_count, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :event_rsvps, :public_id, unique: true
    add_index :event_rsvps, [ :event_id, :member_id ], unique: true
    add_index :event_rsvps, [ :church_id, :status ]
  end
end
