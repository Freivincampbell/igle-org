class AddConfigurationToChurches < ActiveRecord::Migration[8.1]
  def change
    change_table :churches, bulk: true do |t|
      t.text :description
      t.string :legal_name
      t.string :slug
      t.string :whatsapp
      t.string :primary_color
      t.string :secondary_color
      t.string :facebook_url
      t.string :instagram_url
      t.string :youtube_url
      t.boolean :public_page_enabled, default: false, null: false
      t.boolean :service_directory_enabled, default: false, null: false
      t.boolean :member_work_contact_enabled, default: false, null: false
    end

    add_index :churches, :slug, unique: true, where: "slug IS NOT NULL"
  end
end
