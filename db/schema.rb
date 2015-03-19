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

ActiveRecord::Schema.define(version: 20150318233309) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "availabilities", force: :cascade do |t|
    t.integer  "user_id"
    t.boolean  "mon",        default: true
    t.boolean  "tues",       default: true
    t.boolean  "wed",        default: true
    t.boolean  "thurs",      default: true
    t.boolean  "fri",        default: true
    t.boolean  "sat",        default: true
    t.boolean  "sun",        default: true
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "availabilities", ["user_id"], name: "index_availabilities_on_user_id", using: :btree

  create_table "avatars", force: :cascade do |t|
    t.string   "photo"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "background_checks", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "order_id"
    t.integer  "status_cd"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "background_checks", ["user_id"], name: "index_background_checks_on_user_id", using: :btree

  create_table "booking_services", force: :cascade do |t|
    t.integer  "booking_id"
    t.integer  "service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "booking_services", ["booking_id"], name: "index_booking_services_on_booking_id", using: :btree
  add_index "booking_services", ["service_id"], name: "index_booking_services_on_service_id", using: :btree

  create_table "booking_users", force: :cascade do |t|
    t.integer  "booking_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "booking_users", ["booking_id"], name: "index_booking_users_on_booking_id", using: :btree
  add_index "booking_users", ["user_id"], name: "index_booking_users_on_user_id", using: :btree

  create_table "bookings", force: :cascade do |t|
    t.integer  "property_id"
    t.integer  "payment_id"
    t.date     "date"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "status_cd",              default: 1
    t.integer  "payment_status_cd",      default: 0
    t.boolean  "late_next_day",          default: false
    t.boolean  "late_same_day",          default: false
    t.boolean  "no_access_fee"
    t.boolean  "first_booking_discount", default: false
  end

  add_index "bookings", ["payment_id"], name: "index_bookings_on_payment_id", using: :btree
  add_index "bookings", ["property_id"], name: "index_bookings_on_property_id", using: :btree

  create_table "checklists", force: :cascade do |t|
    t.integer  "contractor_job_id"
    t.string   "kitchen_photo"
    t.string   "bedroom_photo"
    t.string   "bathroom_photo"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "checklists", ["contractor_job_id"], name: "index_checklists_on_contractor_job_id", using: :btree

  create_table "cities", force: :cascade do |t|
    t.integer  "county_id"
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cities", ["county_id"], name: "index_cities_on_county_id", using: :btree

  create_table "contractor_jobs", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "job_id"
    t.integer  "priority",   default: 0
    t.boolean  "primary",    default: false
  end

  add_index "contractor_jobs", ["user_id"], name: "index_contractor_jobs_on_user_id", using: :btree

  create_table "contractor_photos", force: :cascade do |t|
    t.string   "photo"
    t.integer  "checklist_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "contractor_photos", ["checklist_id"], name: "index_contractor_photos_on_checklist_id", using: :btree

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
    t.string   "encrypted_ssn"
    t.string   "dob"
    t.string   "encrypted_driver_license"
    t.string   "delivery_point_barcode"
    t.float    "lat"
    t.float    "lng"
    t.string   "stripe_recipient_id"
  end

  create_table "counties", force: :cascade do |t|
    t.integer  "state_id"
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "counties", ["state_id"], name: "index_counties_on_state_id", using: :btree

  create_table "distribution_centers", force: :cascade do |t|
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.float    "lat"
    t.float    "lng"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "job_distribution_centers", force: :cascade do |t|
    t.integer  "job_id"
    t.integer  "distribution_center_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "job_distribution_centers", ["distribution_center_id"], name: "index_job_distribution_centers_on_distribution_center_id", using: :btree
  add_index "job_distribution_centers", ["job_id"], name: "index_job_distribution_centers_on_job_id", using: :btree

  create_table "jobs", force: :cascade do |t|
    t.integer  "status_cd"
    t.integer  "booking_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "distribution", default: false
    t.integer  "king_beds"
    t.integer  "queen_beds"
    t.integer  "full_beds"
    t.integer  "twin_beds"
    t.integer  "size",         default: 1
    t.integer  "toiletries"
    t.boolean  "training",     default: false
    t.date     "date"
    t.integer  "state_cd",     default: 0
    t.integer  "occasion_cd"
    t.datetime "cant_access"
  end

  create_table "messages", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "neighborhoods", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "stripe_id"
    t.string   "last4"
    t.string   "card_type"
    t.string   "fingerprint"
    t.integer  "status_cd"
    t.boolean  "primary",        default: false
    t.string   "routing_number"
    t.boolean  "payout",         default: false
  end

  add_index "payments", ["user_id"], name: "index_payments_on_user_id", using: :btree

  create_table "payouts", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "job_id"
    t.integer  "status_cd",          default: 0
    t.integer  "amount"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "stripe_transfer_id"
  end

  create_table "photo_previews", force: :cascade do |t|
    t.string   "photo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "title",                  limit: 255
    t.string   "address1",               limit: 255
    t.string   "address2",               limit: 255
    t.string   "city",                   limit: 255
    t.string   "state",                  limit: 255
    t.string   "zip",                    limit: 255
    t.string   "country",                limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "delivery_point_barcode"
    t.integer  "bedrooms"
    t.integer  "bathrooms"
    t.integer  "twin_beds"
    t.string   "slug"
    t.string   "access_info"
    t.string   "parking_info"
    t.string   "additional_info",                    default: ""
    t.string   "trash_disposal"
    t.integer  "full_beds"
    t.integer  "queen_beds"
    t.integer  "king_beds"
    t.boolean  "active",                             default: false
    t.string   "phone_number"
    t.integer  "rental_type_cd"
    t.integer  "property_type_cd"
    t.string   "restocking_info"
    t.float    "lat"
    t.float    "lng"
  end

  create_table "property_photos", force: :cascade do |t|
    t.string   "photo"
    t.integer  "property_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "quiz_stages", force: :cascade do |t|
    t.integer  "contractor_profile_id"
    t.integer  "took_at"
    t.integer  "score"
    t.boolean  "pass"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "service_notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "zip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_notifications", ["user_id"], name: "index_service_notifications_on_user_id", using: :btree

  create_table "services", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "display"
    t.boolean  "extra"
    t.boolean  "hidden",     default: false
  end

  create_table "settings", force: :cascade do |t|
    t.string   "var",         null: false
    t.text     "value"
    t.integer  "target_id",   null: false
    t.string   "target_type", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["target_type", "target_id", "var"], name: "index_settings_on_target_type_and_target_id_and_var", unique: true, using: :btree

  create_table "states", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "abbr",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: :cascade do |t|
    t.string   "stripe_charge_id"
    t.integer  "status_cd"
    t.string   "failure_message"
    t.integer  "booking_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "amount"
  end

  add_index "transactions", ["booking_id"], name: "index_transactions_on_booking_id", using: :btree

  create_table "unserviced_zips", force: :cascade do |t|
    t.string   "email"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.integer  "role_cd"
    t.string   "secondary_phone"
    t.string   "activation_state"
    t.string   "activation_token"
    t.datetime "activation_token_expires_at"
    t.integer  "status_cd",                                   default: 1
    t.boolean  "migrated",                                    default: false
    t.integer  "vip_count",                                   default: 0
  end

  add_index "users", ["activation_token"], name: "index_users_on_activation_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["last_logout_at", "last_activity_at"], name: "index_users_on_last_logout_at_and_last_activity_at", using: :btree
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", using: :btree

  create_table "zips", force: :cascade do |t|
    t.integer  "city_id"
    t.string   "code",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "serviced",                    default: false
    t.integer  "neighborhood_id"
  end

  add_index "zips", ["city_id"], name: "index_zips_on_city_id", using: :btree
  add_index "zips", ["neighborhood_id"], name: "index_zips_on_neighborhood_id", using: :btree

  add_foreign_key "availabilities", "users"
  add_foreign_key "background_checks", "users"
  add_foreign_key "booking_services", "bookings"
  add_foreign_key "booking_services", "services"
  add_foreign_key "booking_users", "bookings"
  add_foreign_key "booking_users", "users"
  add_foreign_key "bookings", "payments"
  add_foreign_key "bookings", "properties"
  add_foreign_key "checklists", "contractor_jobs"
  add_foreign_key "contractor_jobs", "users"
  add_foreign_key "contractor_photos", "checklists"
  add_foreign_key "job_distribution_centers", "distribution_centers"
  add_foreign_key "job_distribution_centers", "jobs"
  add_foreign_key "payments", "users"
  add_foreign_key "service_notifications", "users"
  add_foreign_key "transactions", "bookings"
  add_foreign_key "zips", "neighborhoods"
end
