class CreateBoardMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :board_members do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :board, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true

      t.string :position, null: false
      t.date :starts_on
      t.date :ends_on
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :board_members, :public_id, unique: true
    add_index :board_members, [ :board_id, :position, :status ], unique: true,
      where: "status = 'active'", name: "index_board_members_unique_active_position"
    add_index :board_members, [ :board_id, :member_id ], unique: true
  end
end
