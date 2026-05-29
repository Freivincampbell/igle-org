class CreateMemberSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :member_skills do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true

      t.string :level, null: false, default: "basic"
      t.text :notes

      t.timestamps
    end

    add_index :member_skills, :public_id, unique: true
    add_index :member_skills, [ :member_id, :skill_id ], unique: true
  end
end
