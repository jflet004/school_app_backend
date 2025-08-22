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

ActiveRecord::Schema[7.1].define(version: 2025_08_22_211718) do
  create_table "students", force: :cascade do |t|
    t.integer "student_type"
    t.string "first_name"
    t.string "last_name"
    t.date "birthday"
    t.string "instrument_preference"
    t.integer "gender"
    t.integer "experience_years"
    t.string "current_school_name"
    t.boolean "current_school_offers_arts"
    t.integer "ethnicity"
    t.string "email"
    t.string "phone_number"
    t.string "home_address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.integer "household_size"
    t.integer "household_income"
    t.integer "heard_about"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
