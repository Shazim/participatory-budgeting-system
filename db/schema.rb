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

ActiveRecord::Schema[7.2].define(version: 2025_07_10_115957) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "budget_categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "spending_limit_percentage"
    t.bigint "budget_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_budget_categories_on_budget_id"
  end

  create_table "budget_phases", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "phase_type"
    t.date "start_date"
    t.date "end_date"
    t.string "status"
    t.bigint "budget_id", null: false
    t.text "voting_rules"
    t.text "participant_eligibility"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_budget_phases_on_budget_id"
  end

  create_table "budget_projects", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.decimal "amount"
    t.string "status"
    t.bigint "budget_category_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_category_id"], name: "index_budget_projects_on_budget_category_id"
    t.index ["user_id"], name: "index_budget_projects_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.decimal "total_amount"
    t.string "status"
    t.date "start_date"
    t.date "end_date"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "impact_metrics", force: :cascade do |t|
    t.integer "estimated_beneficiaries"
    t.integer "timeline_months"
    t.decimal "sustainability_score"
    t.string "environmental_impact"
    t.string "social_impact"
    t.string "economic_impact"
    t.bigint "budget_project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_project_id"], name: "index_impact_metrics_on_budget_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "budget_project_id", null: false
    t.bigint "budget_phase_id", null: false
    t.decimal "vote_weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_phase_id"], name: "index_votes_on_budget_phase_id"
    t.index ["budget_project_id"], name: "index_votes_on_budget_project_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "budget_categories", "budgets"
  add_foreign_key "budget_phases", "budgets"
  add_foreign_key "budget_projects", "budget_categories"
  add_foreign_key "budget_projects", "users"
  add_foreign_key "budgets", "users"
  add_foreign_key "impact_metrics", "budget_projects"
  add_foreign_key "votes", "budget_phases"
  add_foreign_key "votes", "budget_projects"
  add_foreign_key "votes", "users"
end
