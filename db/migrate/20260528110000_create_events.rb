class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :ministry, foreign_key: true
      t.references :responsible_member, foreign_key: { to_table: :members }
      t.references :created_by, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.text :description
      t.string :event_type, null: false, default: "service"
      t.string :location
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :visibility, null: false, default: "members_only"
      t.string :status, null: false, default: "scheduled"
      t.boolean :recurring, null: false, default: false
      t.string :recurrence_frequency, null: false, default: "none"
      t.date :recurrence_until
      t.integer :capacity
      t.boolean :food_expected, null: false, default: false

      t.timestamps
    end

    add_index :events, :public_id, unique: true
    add_index :events, [ :church_id, :starts_at ]
    add_index :events, [ :church_id, :status ]
    add_index :events, [ :church_id, :event_type ]
  end
end
