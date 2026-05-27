class CreateChurchMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :church_memberships do |t|
      t.references :church, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :owner, null: false, default: false
      t.string :status, null: false, default: "active"
      t.datetime :joined_at

      t.timestamps
    end

    add_index :church_memberships, [ :church_id, :user_id ], unique: true
    add_index :church_memberships, [ :church_id, :owner ]
    add_index :church_memberships, :status
  end
end
