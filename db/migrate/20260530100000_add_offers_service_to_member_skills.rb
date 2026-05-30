class AddOffersServiceToMemberSkills < ActiveRecord::Migration[8.1]
  def change
    add_column :member_skills, :offers_service, :boolean, default: false, null: false
  end
end
