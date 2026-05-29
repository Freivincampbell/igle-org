class CreateMemberOccupations < ActiveRecord::Migration[8.1]
  def change
    create_table :member_occupations do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :occupation, foreign_key: true

      t.string :company_name
      t.string :job_title
      t.string :employment_status, null: false, default: "employed"
      t.string :work_type
      t.boolean :looking_for_work, null: false, default: false
      t.boolean :offers_services, null: false, default: false
      t.boolean :available_for_projects, null: false, default: false
      t.integer :years_of_experience
      t.string :professional_contact
      t.string :profile_url
      t.text :description
      t.boolean :current, null: false, default: true
      t.boolean :public_in_directory, null: false, default: false

      t.timestamps
    end

    add_index :member_occupations, :public_id, unique: true
    add_index :member_occupations, [ :church_id, :looking_for_work ]
    add_index :member_occupations, [ :church_id, :offers_services ]
  end
end
