class CreateMinistryMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :ministry_memberships do |t|
      t.references :ministry, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.string :ministry_role, null: false, default: "member"
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :ministry_memberships, :public_id, unique: true
    add_index :ministry_memberships, [ :ministry_id, :member_id ], unique: true
    add_index :ministry_memberships, [ :ministry_id, :ministry_role ]
    add_index :ministry_memberships, [ :member_id, :status ]
  end
end
