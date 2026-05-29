class CreateProfileChangeRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :profile_change_requests do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :requested_by, foreign_key: { to_table: :users }
      t.references :reviewed_by, foreign_key: { to_table: :users }

      t.string :status, null: false, default: "pending"
      t.jsonb :changes_payload, null: false, default: {}
      t.text :review_notes
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :profile_change_requests, :public_id, unique: true
    add_index :profile_change_requests, [ :church_id, :status ]
    add_index :profile_change_requests, [ :member_id, :status ]
  end
end
