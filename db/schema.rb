# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171030021858) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pgcrypto"

  create_table "allocations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id"
    t.string "organization_ein"
    t.integer "percentage"
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_ein"], name: "index_allocations_on_organization_ein"
    t.index ["subscription_id"], name: "index_active_allocations_on_subscription_id", where: "(deactivated_at IS NULL)"
    t.index ["subscription_id"], name: "index_allocations_on_subscription_id"
  end

  create_table "donations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id", null: false
    t.string "organization_ein", null: false
    t.uuid "allocation_id", null: false
    t.uuid "pay_in_id", null: false
    t.uuid "pay_out_id"
    t.integer "amount_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allocation_id"], name: "index_donations_on_allocation_id"
    t.index ["organization_ein"], name: "index_donations_on_organization_ein"
    t.index ["pay_in_id"], name: "index_donations_on_pay_in_id"
    t.index ["pay_out_id"], name: "index_donations_on_pay_out_id"
    t.index ["subscription_id"], name: "index_donations_on_subscription_id"
  end

  create_table "donors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "donation_rate"
    t.integer "annual_income_cents"
    t.boolean "donated_prior_year"
    t.string "satisfaction_with_prior_donation"
    t.decimal "donation_rate_expected_from_individuals"
    t.string "surprised_by_average_american_donation_rate"
    t.boolean "include_immediate_impact_organizations", default: true
    t.boolean "include_long_term_impact_organizations", default: true
    t.boolean "include_local_organizations", default: true
    t.boolean "include_global_organizations", default: true
    t.string "username"
  end

  create_table "organizations", id: false, force: :cascade do |t|
    t.string "ein", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "local_impact"
    t.boolean "global_impact"
    t.boolean "immediate_impact"
    t.boolean "long_term_impact"
    t.text "description"
    t.string "cause_area"
    t.index ["ein"], name: "index_organizations_on_ein", unique: true
  end

  create_table "pay_ins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id"
    t.integer "amount_cents"
    t.json "receipt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "scheduled_at"
    t.datetime "processed_at"
    t.index ["subscription_id"], name: "index_pay_ins_on_subscription_id"
  end

  create_table "pay_outs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "organization_ein"
    t.integer "amount_cents"
    t.json "receipt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "scheduled_at"
    t.datetime "processed_at"
    t.index ["organization_ein"], name: "index_pay_outs_on_organization_ein"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "donor_id"
    t.integer "annual_income_cents"
    t.decimal "donation_rate"
    t.string "pay_in_frequency"
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["donor_id"], name: "index_active_subscriptions_on_donor_id", where: "(deactivated_at IS NULL)"
    t.index ["donor_id"], name: "index_subscriptions_on_donor_id"
  end

  add_foreign_key "allocations", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "allocations", "subscriptions"
  add_foreign_key "donations", "allocations"
  add_foreign_key "donations", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "donations", "pay_ins"
  add_foreign_key "donations", "pay_outs"
  add_foreign_key "donations", "subscriptions"
  add_foreign_key "pay_ins", "subscriptions"
  add_foreign_key "pay_outs", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "subscriptions", "donors"
end
