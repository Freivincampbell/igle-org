class CreateChurches < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :churches do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :website
      t.string :status, null: false, default: "active"
      t.string :locale, null: false, default: "es"
      t.string :time_zone, null: false, default: "America/Costa_Rica"
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.text :service_times

      t.timestamps
    end

    add_index :churches, :public_id, unique: true
    add_index :churches, :name
    add_index :churches, :status
  end
end
