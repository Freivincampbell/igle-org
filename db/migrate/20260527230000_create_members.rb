class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.references :church, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.string :second_last_name, null: false
      t.string :email
      t.string :phone, null: false
      t.string :secondary_phone
      t.date :birth_date, null: false
      t.string :gender, null: false
      t.string :marital_status, null: false
      t.integer :children_count, null: false, default: 0
      t.date :baptized_on
      t.date :official_membership_on
      t.string :member_status, null: false, default: "active"
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.text :notes

      t.timestamps
    end

    add_index :members, :public_id, unique: true
    add_index :members, [ :church_id, :member_status ]
    add_index :members, [ :church_id, :last_name, :second_last_name, :first_name ], name: "index_members_on_church_and_name"
    add_index :members, [ :church_id, :email ], unique: true, where: "email IS NOT NULL"
  end
end
