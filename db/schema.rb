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

ActiveRecord::Schema[7.1].define(version: 2025_09_06_082807) do
  create_table "achievements", force: :cascade do |t|
    t.integer "child_id", null: false
    t.integer "milestone_id", null: false
    t.boolean "achieved", default: false, null: false
    t.boolean "working", default: false, null: false
    t.datetime "achieved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id", "milestone_id"], name: "index_achievements_on_child_id_and_milestone_id", unique: true
    t.index ["child_id"], name: "index_achievements_on_child_id"
    t.index ["milestone_id"], name: "index_achievements_on_milestone_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "children", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.date "birthday"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_children_on_user_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.string "title", null: false
    t.string "category", null: false
    t.integer "difficulty", default: 1, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "min_months"
    t.integer "max_months"
    t.index ["category"], name: "index_milestones_on_category"
    t.index ["difficulty"], name: "index_milestones_on_difficulty"
  end

  create_table "reward_unlocks", force: :cascade do |t|
    t.integer "child_id", null: false
    t.integer "reward_id", null: false
    t.datetime "unlocked_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id", "reward_id"], name: "index_reward_unlocks_on_child_and_reward_unique", unique: true
    t.index ["child_id"], name: "index_reward_unlocks_on_child_id"
    t.index ["reward_id"], name: "index_reward_unlocks_on_reward_id"
  end

  create_table "rewards", force: :cascade do |t|
    t.integer "kind", default: 0, null: false
    t.string "tier", null: false
    t.integer "threshold", null: false
    t.string "icon_path", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["kind", "tier"], name: "index_rewards_on_kind_and_tier", unique: true
  end

  create_table "rewards_legacy_1757152516", force: :cascade do |t|
    t.string "kind", null: false
    t.string "tier", null: false
    t.integer "threshold", null: false
    t.string "icon_path", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "tier"], name: "index_rewards_on_kind_and_tier_unique", unique: true
    t.index ["threshold"], name: "index_rewards_on_threshold"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "achievements", "children"
  add_foreign_key "achievements", "milestones"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "children", "users"
  add_foreign_key "reward_unlocks", "children"
  add_foreign_key "reward_unlocks", "rewards_legacy_1757152516", column: "reward_id"
end
