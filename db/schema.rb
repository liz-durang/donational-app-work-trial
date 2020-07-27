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

ActiveRecord::Schema.define(version: 2020_07_22_184603) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
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
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_postgresql_files", force: :cascade do |t|
    t.oid "oid"
    t.string "key"
    t.index ["key"], name: "index_active_storage_postgresql_files_on_key", unique: true
  end

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

  create_table "campaigns", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "partner_id"
    t.string "title"
    t.text "description"
    t.string "slug"
    t.integer "target_amount_cents"
    t.string "default_contribution_amounts", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contribution_amount_help_text"
    t.boolean "allow_one_time_contributions", default: true, null: false
    t.index ["partner_id"], name: "index_campaigns_on_partner_id"
  end

  create_table "cause_area_relevances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "donor_id"
    t.integer "global_health"
    t.integer "poverty_and_income_inequality"
    t.integer "climate_and_environment"
    t.integer "animal_welfare"
    t.integer "hunger_nutrition_and_safe_water"
    t.integer "women_and_girls"
    t.integer "immigration_and_refugees"
    t.integer "education"
    t.integer "economic_development"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "criminal_justice"
    t.index ["donor_id"], name: "index_cause_area_relevances_on_donor_id"
  end

  create_table "contributions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "portfolio_id"
    t.integer "amount_cents"
    t.json "receipt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "scheduled_at"
    t.datetime "processed_at"
    t.integer "tips_cents", default: 0
    t.uuid "donor_id"
    t.datetime "failed_at"
    t.integer "payment_processor_fees_cents"
    t.datetime "refunded_at"
    t.string "external_reference_id"
    t.uuid "partner_id"
    t.integer "partner_contribution_percentage", default: 0
    t.string "amount_currency", default: "usd", null: false
    t.string "payment_processor_account_id"
    t.index ["donor_id"], name: "index_contributions_on_donor_id"
    t.index ["partner_id"], name: "index_contributions_on_partner_id"
    t.index ["portfolio_id"], name: "index_contributions_on_portfolio_id"
  end

  create_table "donations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "portfolio_id", null: false
    t.string "organization_ein", null: false
    t.uuid "allocation_id"
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
    t.string "giving_challenges", default: [], array: true
    t.string "reasons_why_i_choose_an_organization", default: [], array: true
    t.string "contribution_frequency"
    t.integer "portfolio_diversity"
    t.string "entity_name"
    t.string "title"
    t.string "house_name_or_number"
    t.string "postcode"
    t.boolean "uk_gift_aid_accepted", default: false, null: false
    t.index ["username"], name: "index_donors_on_username", unique: true
  end

  create_table "donors_partners", id: false, force: :cascade do |t|
    t.uuid "donor_id"
    t.uuid "partner_id"
    t.index ["donor_id"], name: "index_donors_partners_on_donor_id"
    t.index ["partner_id"], name: "index_donors_partners_on_partner_id"
  end

  create_table "grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "organization_ein"
    t.integer "amount_cents"
    t.json "receipt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "scheduled_at"
    t.datetime "processed_at"
    t.datetime "voided_at"
    t.index ["organization_ein"], name: "index_grants_on_organization_ein"
  end

  create_table "managed_portfolios", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "partner_id"
    t.uuid "portfolio_id"
    t.string "name"
    t.text "description"
    t.datetime "hidden_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "display_order"
    t.boolean "featured"
    t.index ["partner_id"], name: "index_managed_portfolios_on_partner_id"
    t.index ["portfolio_id"], name: "index_managed_portfolios_on_portfolio_id"
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
    t.string "cause_area"
    t.datetime "deactivated_at"
    t.text "mission"
    t.text "context"
    t.text "impact"
    t.text "why_you_should_care"
    t.string "website_url"
    t.string "annual_report_url"
    t.string "financials_url"
    t.string "form_990_url"
    t.string "recommended_by", default: [], array: true
    t.uuid "suggested_by_donor_id"
    t.string "program_restriction"
    t.string "routing_organization_name"
    t.index ["ein"], name: "index_organizations_on_ein", unique: true
  end

  create_table "partner_affiliations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "donor_id"
    t.uuid "partner_id"
    t.uuid "campaign_id"
    t.jsonb "custom_donor_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_partner_affiliations_on_campaign_id"
    t.index ["donor_id"], name: "index_partner_affiliations_on_donor_id"
    t.index ["partner_id"], name: "index_partner_affiliations_on_partner_id"
  end

  create_table "partners", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "website_url"
    t.text "description"
    t.decimal "platform_fee_percentage", default: "0.0"
    t.string "primary_branding_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "donor_questions_schema"
    t.string "payment_processor_account_id"
    t.string "api_key"
    t.string "operating_costs_text"
    t.string "operating_costs_organization_ein"
    t.string "currency", default: "usd", null: false
    t.text "email_receipt_preamble"
    t.string "after_donation_thank_you_page_url"
    t.text "receipt_first_paragraph"
    t.text "receipt_second_paragraph"
    t.text "receipt_tax_info"
    t.string "receipt_charity_name"
  end

  create_table "payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "donor_id", null: false
    t.string "payment_processor_customer_id"
    t.string "name_on_card"
    t.string "last4"
    t.datetime "deactivated_at"
    t.string "address_zip_code"
    t.integer "retry_count", default: 0
    t.index ["deactivated_at"], name: "index_payment_methods_on_deactivated_at"
    t.index ["donor_id"], name: "index_payment_methods_on_donor_id"
  end

  create_table "portfolios", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "creator_id"
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_active_subscriptions_on_donor_id", where: "(deactivated_at IS NULL)"
    t.index ["creator_id"], name: "index_portfolios_on_creator_id"
  end

  create_table "recurring_contributions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "donor_id"
    t.uuid "portfolio_id"
    t.datetime "start_at", null: false
    t.datetime "deactivated_at"
    t.string "frequency"
    t.integer "amount_cents"
    t.integer "tips_cents", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_reminded_at"
    t.datetime "last_scheduled_at"
    t.uuid "partner_id"
    t.integer "partner_contribution_percentage", default: 0
    t.string "amount_currency", default: "usd", null: false
    t.index ["deactivated_at"], name: "index_recurring_contributions_on_deactivated_at"
    t.index ["donor_id"], name: "index_recurring_contributions_on_donor_id"
    t.index ["partner_id"], name: "index_recurring_contributions_on_partner_id"
    t.index ["portfolio_id"], name: "index_recurring_contributions_on_portfolio_id"
  end

  create_table "searchable_organizations", id: false, force: :cascade do |t|
    t.string "ein", null: false
    t.string "name", null: false
    t.string "ico"
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "org_group"
    t.string "subsection"
    t.string "affiliation"
    t.string "classification"
    t.string "ruling"
    t.string "deductibility"
    t.string "foundation"
    t.string "activity"
    t.string "organization"
    t.string "status"
    t.string "tax_period"
    t.string "asset_cd"
    t.string "income_cd"
    t.string "filing_req_cd"
    t.string "pf_filing_req_cd"
    t.string "acct_pd"
    t.string "asset_amt"
    t.string "income_amt"
    t.string "revenue_amt"
    t.string "ntee_cd"
    t.string "sort_name"
    t.index ["ein"], name: "index_searchable_organizations_on_ein", unique: true
    t.index ["name"], name: "index_searchable_organizations_on_name"
  end

  create_table "selected_portfolios", force: :cascade do |t|
    t.uuid "donor_id"
    t.uuid "portfolio_id"
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deactivated_at"], name: "index_selected_portfolios_on_deactivated_at"
    t.index ["donor_id"], name: "index_selected_portfolios_on_donor_id"
    t.index ["portfolio_id"], name: "index_selected_portfolios_on_portfolio_id"
  end

  create_table "zapier_webhooks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "hook_url"
    t.string "hook_type"
    t.uuid "partner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["partner_id"], name: "index_zapier_webhooks_on_partner_id"
  end

  add_foreign_key "allocations", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "allocations", "portfolios"
  add_foreign_key "campaigns", "partners"
  add_foreign_key "cause_area_relevances", "donors"
  add_foreign_key "contributions", "donors"
  add_foreign_key "contributions", "partners"
  add_foreign_key "contributions", "portfolios"
  add_foreign_key "donations", "allocations"
  add_foreign_key "donations", "contributions"
  add_foreign_key "donations", "grants"
  add_foreign_key "donations", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "donations", "portfolios"
  add_foreign_key "grants", "organizations", column: "organization_ein", primary_key: "ein"
  add_foreign_key "managed_portfolios", "partners"
  add_foreign_key "managed_portfolios", "portfolios"
  add_foreign_key "organizations", "donors", column: "suggested_by_donor_id"
  add_foreign_key "partner_affiliations", "campaigns"
  add_foreign_key "partner_affiliations", "donors"
  add_foreign_key "partner_affiliations", "partners"
  add_foreign_key "partners", "organizations", column: "operating_costs_organization_ein", primary_key: "ein"
  add_foreign_key "payment_methods", "donors"
  add_foreign_key "portfolios", "donors", column: "creator_id"
  add_foreign_key "recurring_contributions", "donors"
  add_foreign_key "recurring_contributions", "partners"
  add_foreign_key "recurring_contributions", "portfolios"
  add_foreign_key "selected_portfolios", "donors"
  add_foreign_key "selected_portfolios", "portfolios"
  add_foreign_key "zapier_webhooks", "partners"
end
