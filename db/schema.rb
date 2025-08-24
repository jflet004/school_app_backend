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

ActiveRecord::Schema[7.1].define(version: 2025_08_24_000713) do
  create_table "courses", force: :cascade do |t|
    t.string "name"
    t.integer "teacher_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teacher_id"], name: "index_courses_on_teacher_id"
  end

  create_table "parent_contacts", force: :cascade do |t|
    t.integer "student_id", null: false
    t.string "parent_first_name", null: false
    t.string "parent_last_name", null: false
    t.string "email"
    t.string "phone_number"
    t.string "home_address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id", "parent_last_name"], name: "index_parent_contacts_on_student_id_and_parent_last_name"
    t.index ["student_id"], name: "index_parent_contacts_on_student_id"
  end

  create_table "students", force: :cascade do |t|
    t.integer "student_type", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "birthday"
    t.string "instrument_preference"
    t.integer "gender", default: 3, null: false
    t.integer "experience_years", default: 0, null: false
    t.string "current_school_name"
    t.boolean "current_school_offers_arts"
    t.integer "ethnicity", default: 6, null: false
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
    t.index ["email"], name: "index_students_on_email"
    t.index ["last_name", "first_name"], name: "index_students_on_last_name_and_first_name"
    t.index ["student_type"], name: "index_students_on_student_type"
  end

  create_table "teachers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone_number"
    t.date "hire_date"
    t.decimal "base_rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "courses", "teachers"
  add_foreign_key "parent_contacts", "students"
end
