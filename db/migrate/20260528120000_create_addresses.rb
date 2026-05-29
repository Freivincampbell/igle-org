class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.uuid :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.references :church, null: false, foreign_key: true
      t.references :addressable, polymorphic: true, null: false

      t.string :line_1
      t.string :line_2
      t.string :city
      t.string :state
      t.string :country
      t.string :postal_code
      t.text :reference

      t.timestamps
    end

    add_index :addresses, :public_id, unique: true
    add_index :addresses, [ :addressable_type, :addressable_id ], name: "index_addresses_on_addressable_compound"
  end
end
