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

ActiveRecord::Schema[8.1].define(version: 2026_06_28_214404) do
  create_table "accounts", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "api_key_digest", null: false
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_digest"], name: "index_accounts_on_api_key_digest"
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "skill_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "skill_id"], name: "index_favorites_on_account_id_and_skill_id", unique: true
    t.index ["account_id"], name: "index_favorites_on_account_id"
    t.index ["skill_id"], name: "index_favorites_on_skill_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "entry_type", null: false
    t.integer "from_account_id", null: false
    t.datetime "timestamp", null: false
    t.integer "to_account_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_account_id"], name: "index_ledger_entries_on_from_account_id"
    t.index ["to_account_id"], name: "index_ledger_entries_on_to_account_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.datetime "acquired_at"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "buyer_id", null: false
    t.datetime "created_at", null: false
    t.string "entitlement_token", null: false
    t.integer "skill_version_id", null: false
    t.string "status", default: "paid", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id", "skill_version_id"], name: "index_purchases_on_buyer_and_version_paid", unique: true, where: "status = 'paid'"
    t.index ["buyer_id"], name: "index_purchases_on_buyer_id"
    t.index ["entitlement_token"], name: "index_purchases_on_entitlement_token", unique: true
    t.index ["skill_version_id"], name: "index_purchases_on_skill_version_id"
    t.index ["status"], name: "index_purchases_on_status"
  end

  create_table "skill_artifacts", force: :cascade do |t|
    t.string "artifact_type", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.json "manifest", default: {}, null: false
    t.integer "skill_version_id", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_type"], name: "index_skill_artifacts_on_artifact_type"
    t.index ["skill_version_id"], name: "index_skill_artifacts_on_skill_version_id", unique: true
  end

  create_table "skill_reviews", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.text "decision_reason"
    t.json "policy_checks", default: {}, null: false
    t.string "review_type", null: false
    t.integer "reviewer_account_id"
    t.integer "skill_version_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["reviewer_account_id"], name: "index_skill_reviews_on_reviewer_account_id"
    t.index ["skill_version_id"], name: "index_skill_reviews_on_skill_version_id", unique: true
    t.index ["status"], name: "index_skill_reviews_on_status"
  end

  create_table "skill_verifications", force: :cascade do |t|
    t.json "checks", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "failure_reason"
    t.integer "skill_version_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["skill_version_id"], name: "index_skill_verifications_on_skill_version_id", unique: true
    t.index ["status"], name: "index_skill_verifications_on_status"
  end

  create_table "skill_versions", force: :cascade do |t|
    t.text "changelog"
    t.datetime "created_at", null: false
    t.integer "skill_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["skill_id", "version"], name: "index_skill_versions_on_skill_id_and_version", unique: true
    t.index ["skill_id"], name: "index_skill_versions_on_skill_id"
    t.index ["status"], name: "index_skill_versions_on_status"
  end

  create_table "skills", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "listing_status", default: "draft", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_skills_on_author_id"
    t.index ["listing_status"], name: "index_skills_on_listing_status"
    t.index ["slug"], name: "index_skills_on_slug", unique: true
  end

  add_foreign_key "favorites", "accounts", on_delete: :cascade
  add_foreign_key "favorites", "skills", on_delete: :cascade
  add_foreign_key "ledger_entries", "accounts", column: "from_account_id"
  add_foreign_key "ledger_entries", "accounts", column: "to_account_id"
  add_foreign_key "purchases", "accounts", column: "buyer_id"
  add_foreign_key "purchases", "skill_versions"
  add_foreign_key "skill_artifacts", "skill_versions"
  add_foreign_key "skill_reviews", "accounts", column: "reviewer_account_id"
  add_foreign_key "skill_reviews", "skill_versions"
  add_foreign_key "skill_verifications", "skill_versions"
  add_foreign_key "skill_versions", "skills"
  add_foreign_key "skills", "accounts", column: "author_id"
end
