class CreateFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :family_members do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :family, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true

      t.string :relationship, null: false, default: "other"
      t.boolean :primary_contact, null: false, default: false

      t.timestamps
    end

    add_index :family_members, :public_id, unique: true
    add_index :family_members, [ :family_id, :member_id ], unique: true
  end
end
