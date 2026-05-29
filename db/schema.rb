# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_28_140003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "church_memberships", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.boolean "owner", default: false, null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["church_id", "owner"], name: "index_church_memberships_on_church_id_and_owner"
    t.index ["church_id", "user_id"], name: "index_church_memberships_on_church_id_and_user_id", unique: true
    t.index ["church_id"], name: "index_church_memberships_on_church_id"
    t.index ["public_id"], name: "index_church_memberships_on_public_id", unique: true
    t.index ["status"], name: "index_church_memberships_on_status"
    t.index ["user_id"], name: "index_church_memberships_on_user_id"
  end

  create_table "church_service_times", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "ends_at"
    t.string "location"
    t.string "name", null: false
    t.text "notes"
    t.integer "position", default: 0, null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.time "starts_at", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "day_of_week", "starts_at"], name: "index_service_times_on_church_and_time"
    t.index ["church_id", "status"], name: "index_church_service_times_on_church_id_and_status"
    t.index ["church_id"], name: "index_church_service_times_on_church_id"
    t.index ["public_id"], name: "index_church_service_times_on_public_id", unique: true
  end

  create_table "churches", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "facebook_url"
    t.string "instagram_url"
    t.string "legal_name"
    t.string "locale", default: "es", null: false
    t.boolean "member_work_contact_enabled", default: false, null: false
    t.string "name", null: false
    t.string "phone"
    t.string "postal_code"
    t.string "primary_color"
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "public_page_enabled", default: false, null: false
    t.string "secondary_color"
    t.boolean "service_directory_enabled", default: false, null: false
    t.text "service_times"
    t.string "slug"
    t.string "state"
    t.string "status", default: "active", null: false
    t.string "time_zone", default: "America/Costa_Rica", null: false
    t.datetime "updated_at", null: false
    t.string "website"
    t.string "whatsapp"
    t.string "youtube_url"
    t.index ["name"], name: "index_churches_on_name"
    t.index ["public_id"], name: "index_churches_on_public_id", unique: true
    t.index ["slug"], name: "index_churches_on_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["status"], name: "index_churches_on_status"
  end

  create_table "event_attendances", force: :cascade do |t|
    t.boolean "attended", default: true, null: false
    t.datetime "checked_in_at"
    t.bigint "checked_in_by_id"
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "member_id", null: false
    t.text "notes"
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "updated_at", null: false
    t.index ["checked_in_by_id"], name: "index_event_attendances_on_checked_in_by_id"
    t.index ["church_id", "event_id"], name: "index_event_attendances_on_church_id_and_event_id"
    t.index ["church_id"], name: "index_event_attendances_on_church_id"
    t.index ["event_id", "member_id"], name: "index_event_attendances_on_event_id_and_member_id", unique: true
    t.index ["event_id"], name: "index_event_attendances_on_event_id"
    t.index ["member_id"], name: "index_event_attendances_on_member_id"
    t.index ["public_id"], name: "index_event_attendances_on_public_id", unique: true
  end

  create_table "event_rsvps", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.integer "guests_count", default: 0, null: false
    t.bigint "member_id", null: false
    t.text "notes"
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "status", default: "attending", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "status"], name: "index_event_rsvps_on_church_id_and_status"
    t.index ["church_id"], name: "index_event_rsvps_on_church_id"
    t.index ["event_id", "member_id"], name: "index_event_rsvps_on_event_id_and_member_id", unique: true
    t.index ["event_id"], name: "index_event_rsvps_on_event_id"
    t.index ["member_id"], name: "index_event_rsvps_on_member_id"
    t.index ["public_id"], name: "index_event_rsvps_on_public_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.integer "capacity"
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.datetime "ends_at"
    t.string "event_type", default: "service", null: false
    t.boolean "food_expected", default: false, null: false
    t.string "location"
    t.bigint "ministry_id"
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "recurrence_frequency", default: "none", null: false
    t.date "recurrence_until"
    t.boolean "recurring", default: false, null: false
    t.bigint "responsible_member_id"
    t.datetime "starts_at", null: false
    t.string "status", default: "scheduled", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "members_only", null: false
    t.index ["church_id", "event_type"], name: "index_events_on_church_id_and_event_type"
    t.index ["church_id", "starts_at"], name: "index_events_on_church_id_and_starts_at"
    t.index ["church_id", "status"], name: "index_events_on_church_id_and_status"
    t.index ["church_id"], name: "index_events_on_church_id"
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["ministry_id"], name: "index_events_on_ministry_id"
    t.index ["public_id"], name: "index_events_on_public_id", unique: true
    t.index ["responsible_member_id"], name: "index_events_on_responsible_member_id"
  end

  create_table "member_occupations", force: :cascade do |t|
    t.boolean "available_for_projects", default: false, null: false
    t.bigint "church_id", null: false
    t.string "company_name"
    t.datetime "created_at", null: false
    t.boolean "current", default: true, null: false
    t.text "description"
    t.string "employment_status", default: "employed", null: false
    t.string "job_title"
    t.boolean "looking_for_work", default: false, null: false
    t.bigint "member_id", null: false
    t.bigint "occupation_id"
    t.boolean "offers_services", default: false, null: false
    t.string "professional_contact"
    t.string "profile_url"
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "public_in_directory", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "work_type"
    t.integer "years_of_experience"
    t.index ["church_id", "looking_for_work"], name: "index_member_occupations_on_church_id_and_looking_for_work"
    t.index ["church_id", "offers_services"], name: "index_member_occupations_on_church_id_and_offers_services"
    t.index ["church_id"], name: "index_member_occupations_on_church_id"
    t.index ["member_id"], name: "index_member_occupations_on_member_id"
    t.index ["occupation_id"], name: "index_member_occupations_on_occupation_id"
    t.index ["public_id"], name: "index_member_occupations_on_public_id", unique: true
  end

  create_table "member_skills", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.string "level", default: "basic", null: false
    t.bigint "member_id", null: false
    t.text "notes"
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "skill_id", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id"], name: "index_member_skills_on_church_id"
    t.index ["member_id", "skill_id"], name: "index_member_skills_on_member_id_and_skill_id", unique: true
    t.index ["member_id"], name: "index_member_skills_on_member_id"
    t.index ["public_id"], name: "index_member_skills_on_public_id", unique: true
    t.index ["skill_id"], name: "index_member_skills_on_skill_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.date "baptized_on"
    t.date "birth_date", null: false
    t.integer "children_count", default: 0, null: false
    t.bigint "church_id", null: false
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "first_name", null: false
    t.string "gender", null: false
    t.string "last_name", null: false
    t.string "marital_status", null: false
    t.string "member_status", default: "active", null: false
    t.string "middle_name"
    t.text "notes"
    t.date "official_membership_on"
    t.string "phone", null: false
    t.string "postal_code"
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "second_last_name", null: false
    t.string "secondary_phone"
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["church_id", "email"], name: "index_members_on_church_id_and_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["church_id", "last_name", "second_last_name", "first_name"], name: "index_members_on_church_and_name"
    t.index ["church_id", "member_status"], name: "index_members_on_church_id_and_member_status"
    t.index ["church_id"], name: "index_members_on_church_id"
    t.index ["public_id"], name: "index_members_on_public_id", unique: true
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "membership_roles", force: :cascade do |t|
    t.bigint "church_membership_id", null: false
    t.datetime "created_at", null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["church_membership_id", "role_id"], name: "index_membership_roles_on_church_membership_id_and_role_id", unique: true
    t.index ["church_membership_id"], name: "index_membership_roles_on_church_membership_id"
    t.index ["public_id"], name: "index_membership_roles_on_public_id", unique: true
    t.index ["role_id"], name: "index_membership_roles_on_role_id"
  end

  create_table "ministries", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "name"], name: "index_ministries_on_church_id_and_name", unique: true
    t.index ["church_id", "status"], name: "index_ministries_on_church_id_and_status"
    t.index ["church_id"], name: "index_ministries_on_church_id"
    t.index ["public_id"], name: "index_ministries_on_public_id", unique: true
  end

  create_table "ministry_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.bigint "ministry_id", null: false
    t.string "ministry_role", default: "member", null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id", "status"], name: "index_ministry_memberships_on_member_id_and_status"
    t.index ["member_id"], name: "index_ministry_memberships_on_member_id"
    t.index ["ministry_id", "member_id"], name: "index_ministry_memberships_on_ministry_id_and_member_id", unique: true
    t.index ["ministry_id", "ministry_role"], name: "index_ministry_memberships_on_ministry_id_and_ministry_role"
    t.index ["ministry_id"], name: "index_ministry_memberships_on_ministry_id"
    t.index ["public_id"], name: "index_ministry_memberships_on_public_id", unique: true
  end

  create_table "occupations", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "name"], name: "index_occupations_on_church_id_and_name", unique: true
    t.index ["church_id"], name: "index_occupations_on_church_id"
    t.index ["public_id"], name: "index_occupations_on_public_id", unique: true
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action_key", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "module_key", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "updated_at", null: false
    t.index ["module_key", "action_key"], name: "index_permissions_on_module_key_and_action_key", unique: true
    t.index ["position"], name: "index_permissions_on_position"
    t.index ["public_id"], name: "index_permissions_on_public_id", unique: true
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["public_id"], name: "index_role_permissions_on_public_id", unique: true
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.boolean "pastoral", default: false, null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "name"], name: "index_roles_on_church_id_and_name", unique: true
    t.index ["church_id", "pastoral"], name: "index_roles_on_church_id_and_pastoral"
    t.index ["church_id"], name: "index_roles_on_church_id"
    t.index ["public_id"], name: "index_roles_on_public_id", unique: true
    t.index ["status"], name: "index_roles_on_status"
  end

  create_table "skills", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "name"], name: "index_skills_on_church_id_and_name", unique: true
    t.index ["church_id"], name: "index_skills_on_church_id"
    t.index ["public_id"], name: "index_skills_on_public_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "platform_role", default: "user", null: false
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["platform_role"], name: "index_users_on_platform_role"
    t.index ["public_id"], name: "index_users_on_public_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.uuid "public_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["public_id"], name: "index_versions_on_public_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "church_memberships", "churches"
  add_foreign_key "church_memberships", "users"
  add_foreign_key "church_service_times", "churches"
  add_foreign_key "event_attendances", "churches"
  add_foreign_key "event_attendances", "events"
  add_foreign_key "event_attendances", "members"
  add_foreign_key "event_attendances", "users", column: "checked_in_by_id"
  add_foreign_key "event_rsvps", "churches"
  add_foreign_key "event_rsvps", "events"
  add_foreign_key "event_rsvps", "members"
  add_foreign_key "events", "churches"
  add_foreign_key "events", "members", column: "responsible_member_id"
  add_foreign_key "events", "ministries"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "member_occupations", "churches"
  add_foreign_key "member_occupations", "members"
  add_foreign_key "member_occupations", "occupations"
  add_foreign_key "member_skills", "churches"
  add_foreign_key "member_skills", "members"
  add_foreign_key "member_skills", "skills"
  add_foreign_key "members", "churches"
  add_foreign_key "members", "users"
  add_foreign_key "membership_roles", "church_memberships"
  add_foreign_key "membership_roles", "roles"
  add_foreign_key "ministries", "churches"
  add_foreign_key "ministry_memberships", "members"
  add_foreign_key "ministry_memberships", "ministries"
  add_foreign_key "occupations", "churches"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "roles", "churches"
  add_foreign_key "skills", "churches"
end
