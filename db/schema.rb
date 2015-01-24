# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150124044334) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "avatars", force: :cascade do |t|
    t.string   "photo"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "booking_services", force: :cascade do |t|
    t.integer  "booking_id"
    t.integer  "service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "booking_services", ["booking_id"], name: "index_booking_services_on_booking_id", using: :btree
  add_index "booking_services", ["service_id"], name: "index_booking_services_on_service_id", using: :btree

  create_table "bookings", force: :cascade do |t|
    t.integer  "property_id"
    t.integer  "payment_id"
    t.datetime "date"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "status_cd"
  end

  add_index "bookings", ["payment_id"], name: "index_bookings_on_payment_id", using: :btree
  add_index "bookings", ["property_id"], name: "index_bookings_on_property_id", using: :btree

  create_table "cities", force: :cascade do |t|
    t.integer  "county_id"
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cities", ["county_id"], name: "index_cities_on_county_id", using: :btree

  create_table "contractor_jobs", force: :cascade do |t|
    t.integer  "booking_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "contractor_jobs", ["booking_id"], name: "index_contractor_jobs_on_booking_id", using: :btree
  add_index "contractor_jobs", ["user_id"], name: "index_contractor_jobs_on_user_id", using: :btree

  create_table "contractor_profiles", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "position_cd"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.string   "emergency_contact_phone"
    t.string   "emergency_contact_first_name"
    t.string   "emergency_contact_last_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "counties", force: :cascade do |t|
    t.integer  "state_id"
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "counties", ["state_id"], name: "index_counties_on_state_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "stripe_id"
    t.string   "last4"
    t.string   "card_type"
    t.string   "fingerprint"
    t.string   "balanced_id"
    t.integer  "status_cd"
  end

  add_index "payments", ["user_id"], name: "index_payments_on_user_id", using: :btree

  create_table "properties", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "title",                  limit: 255
    t.string   "address1",               limit: 255
    t.string   "address2",               limit: 255
    t.string   "city",                   limit: 255
    t.string   "state",                  limit: 255
    t.string   "zip",                    limit: 255
    t.string   "country",                limit: 255
    t.string   "property_type",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "delivery_point_barcode"
    t.integer  "bedrooms"
    t.integer  "bathrooms"
    t.integer  "twin_beds"
    t.string   "slug"
    t.string   "access_info"
    t.string   "parking_info"
    t.string   "additional_info"
    t.string   "trash_disposal"
    t.integer  "full_beds"
    t.integer  "queen_beds"
    t.integer  "king_beds"
    t.boolean  "active",                             default: false
  end

  create_table "property_photos", force: :cascade do |t|
    t.string   "photo"
    t.integer  "property_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "services", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "states", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "abbr",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                           limit: 255,                 null: false
    t.string   "crypted_password",                limit: 255,                 null: false
    t.string   "salt",                            limit: 255,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_me_token",               limit: 255
    t.datetime "remember_me_token_expires_at"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.datetime "last_activity_at"
    t.string   "last_login_from_ip_address",      limit: 255
    t.string   "first_name",                      limit: 255
    t.string   "last_name",                       limit: 255
    t.string   "phone_number",                    limit: 255
    t.boolean  "phone_confirmed",                             default: false
    t.string   "company",                         limit: 255
    t.string   "phone_confirmation",              limit: 255
    t.string   "stripe_customer_id"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "balanced_customer_id"
    t.integer  "role_cd"
    t.string   "secondary_phone"
    t.integer  "status_cd",                                   default: 1
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["last_logout_at", "last_activity_at"], name: "index_users_on_last_logout_at_and_last_activity_at", using: :btree
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", using: :btree

  create_table "zips", force: :cascade do |t|
    t.integer  "city_id"
    t.string   "code",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "zips", ["city_id"], name: "index_zips_on_city_id", using: :btree

  add_foreign_key "booking_services", "bookings"
  add_foreign_key "booking_services", "services"
  add_foreign_key "bookings", "payments"
  add_foreign_key "bookings", "properties"
  add_foreign_key "contractor_jobs", "bookings"
  add_foreign_key "contractor_jobs", "users"
  add_foreign_key "payments", "users"
end
