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

ActiveRecord::Schema[8.1].define(version: 2026_05_28_202336) do
  create_table "accounts", force: :cascade do |t|
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "executions", force: :cascade do |t|
    t.integer "buyer_id", null: false
    t.datetime "created_at", null: false
    t.text "result"
    t.integer "skill_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "timestamp", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_executions_on_buyer_id"
    t.index ["skill_id"], name: "index_executions_on_skill_id"
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

  create_table "skills", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.decimal "price_per_call", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "stake_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_skills_on_author_id"
  end

  add_foreign_key "executions", "accounts", column: "buyer_id"
  add_foreign_key "executions", "skills"
  add_foreign_key "ledger_entries", "accounts", column: "from_account_id"
  add_foreign_key "ledger_entries", "accounts", column: "to_account_id"
  add_foreign_key "skills", "accounts", column: "author_id"
end
