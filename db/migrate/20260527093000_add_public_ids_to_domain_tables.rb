class AddPublicIdsToDomainTables < ActiveRecord::Migration[8.1]
  DOMAIN_TABLES = %i[
    users
    church_memberships
    roles
    permissions
    role_permissions
    membership_roles
    versions
  ].freeze

  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    DOMAIN_TABLES.each do |table_name|
      next if column_exists?(table_name, :public_id)

      add_column table_name, :public_id, :uuid, default: -> { "gen_random_uuid()" }
      execute <<~SQL.squish
        UPDATE #{quote_table_name(table_name)}
        SET public_id = gen_random_uuid()
        WHERE public_id IS NULL
      SQL
      change_column_null table_name, :public_id, false
      add_index table_name, :public_id, unique: true
    end
  end

  def down
    DOMAIN_TABLES.reverse_each do |table_name|
      remove_index table_name, :public_id if index_exists?(table_name, :public_id)
      remove_column table_name, :public_id if column_exists?(table_name, :public_id)
    end
  end
end
