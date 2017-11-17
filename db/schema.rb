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

ActiveRecord::Schema.define(version: 20171117113736) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pgcrypto"

  create_table "allocations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "portfolio_id"
    t.string "organization_ein"
    t.integer "percentage"
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_ein"], name: "index_allocations_on_organization_ein"
    t.index ["portfolio_id"], name: "index_active_allocations_on_subscription_id", where: "(deactivated_at IS NULL)"
    t.index ["portfolio_id"], name: "index_allocations_on_portfolio_id"
  end

  create_table "contributions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "portfolio_id"
    t.integer "amount_cents"
    t.json "receipt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "scheduled_at"
    t.datetime "processed_at"
    t.index ["portfolio_id"], name: "index_contributions_on_portfolio_id"
  end

  create_table "donations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "portfolio_id", null: false
    t.string "organization_ein", null: false
    t.uuid "allocation_id", null: false
    t.uuid "contribution_id", null: false
    t.uuid "grant_id"
    t.integer "amount_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allocation_id"], name: "index_donations_on_allocation_id"
    t.index ["contribution_id"], name: "index_donations_on_contribution_id"
    t.index ["grant_id"], name: "index_donations_on_grant_id"
    t.index ["organization_ein"], name: "index_donations_on_organization_ein"
    t.index ["portfolio_id"], name: "index_donations_on_portfolio_id"
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
    t.string "payment_processor_customer_id"
    t.index ["username"], name: "index_donors_on_username", unique: true
  end

  create_table "grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "organization_ein"
    t.integer "amount_cents"
    t.json "receipt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "scheduled_at"
    t.datetime "processed_at"
    t.index ["organization_ein"], name: "index_grants_on_organization_ein"
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

  create_table "portfolios", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "donor_id"
    t.integer "annual_income_cents"
    t.decimal "donation_rate"
    t.string "contribution_frequency"
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["donor_id"], name: "index_active_subscriptions_on_donor_id", where: "(deactivated_at IS NULL)"
    t.index ["donor_id"], name: "index_portfolios_on_donor_id"
  end

  add_foreign_key "allocations", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "allocations", "portfolios"
  add_foreign_key "contributions", "portfolios"
  add_foreign_key "donations", "allocations"
  add_foreign_key "donations", "contributions"
  add_foreign_key "donations", "grants"
  add_foreign_key "donations", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "donations", "portfolios"
  add_foreign_key "grants", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "portfolios", "donors"
end
