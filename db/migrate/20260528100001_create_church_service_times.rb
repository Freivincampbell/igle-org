class CreateChurchServiceTimes < ActiveRecord::Migration[8.1]
  def change
    create_table :church_service_times do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :day_of_week, null: false
      t.time :starts_at, null: false
      t.time :ends_at
      t.string :location
      t.string :status, null: false, default: "active"
      t.integer :position, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :church_service_times, :public_id, unique: true
    add_index :church_service_times, [ :church_id, :day_of_week, :starts_at ], name: "index_service_times_on_church_and_time"
    add_index :church_service_times, [ :church_id, :status ]
  end
end
