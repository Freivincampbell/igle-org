class CreateEventGuestRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :event_guest_rsvps do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true

      t.string :name, null: false
      t.string :email
      t.string :phone
      t.integer :guests_count, null: false, default: 0
      t.string :status, null: false, default: "attending"
      t.string :access_token, null: false

      t.timestamps
    end

    add_index :event_guest_rsvps, :public_id, unique: true
    add_index :event_guest_rsvps, :access_token, unique: true
    add_index :event_guest_rsvps, "event_id, lower(email)", unique: true,
      where: "email IS NOT NULL",
      name: "index_event_guest_rsvps_on_event_and_lower_email"
    add_index :event_guest_rsvps, [ :church_id, :status ]
  end
end
