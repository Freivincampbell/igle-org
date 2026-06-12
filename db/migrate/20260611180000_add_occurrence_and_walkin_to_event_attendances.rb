class AddOccurrenceAndWalkinToEventAttendances < ActiveRecord::Migration[8.1]
  def up
    add_column :event_attendances, :occurrence_date, :date
    add_column :event_attendances, :guest_name, :string
    change_column_null :event_attendances, :member_id, true

    # Backfill: la fecha de la (única) ocurrencia de cada evento existente.
    execute <<~SQL
      UPDATE event_attendances ea
      SET occurrence_date = (e.starts_at AT TIME ZONE 'UTC')::date
      FROM events e
      WHERE ea.event_id = e.id AND ea.occurrence_date IS NULL
    SQL

    change_column_null :event_attendances, :occurrence_date, false

    remove_index :event_attendances, column: [ :event_id, :member_id ],
      name: "index_event_attendances_on_event_id_and_member_id"
    add_index :event_attendances, [ :event_id, :member_id, :occurrence_date ], unique: true,
      where: "member_id IS NOT NULL",
      name: "index_event_attendances_on_event_member_occurrence"
  end

  def down
    remove_index :event_attendances, name: "index_event_attendances_on_event_member_occurrence"
    add_index :event_attendances, [ :event_id, :member_id ], unique: true,
      name: "index_event_attendances_on_event_id_and_member_id"
    change_column_null :event_attendances, :member_id, false
    remove_column :event_attendances, :occurrence_date
    remove_column :event_attendances, :guest_name
  end
end
