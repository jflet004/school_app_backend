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

ActiveRecord::Schema[7.1].define(version: 2025_08_26_024940) do
  create_table "course_offerings", force: :cascade do |t|
    t.integer "teacher_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "course_id", null: false
    t.integer "day_of_week"
    t.time "start_time"
    t.time "end_time"
    t.string "room"
    t.index ["course_id"], name: "index_course_offerings_on_course_id"
    t.index ["day_of_week", "start_time"], name: "index_course_offerings_on_day_of_week_and_start_time"
    t.index ["teacher_id"], name: "index_course_offerings_on_teacher_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "name", null: false
    t.integer "course_type", default: 0, null: false
    t.integer "price_cents", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_courses_on_name", unique: true
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "course_offering_id", null: false
    t.integer "student_id", null: false
    t.integer "status", default: 0, null: false
    t.date "started_on"
    t.date "ended_on"
    t.integer "monthly_rate_cents"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_offering_id", "student_id"], name: "index_enrollments_on_course_offering_id_and_student_id", unique: true
    t.index ["course_offering_id"], name: "index_enrollments_on_course_offering_id"
    t.index ["student_id"], name: "index_enrollments_on_student_id"
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

  add_foreign_key "course_offerings", "courses"
  add_foreign_key "course_offerings", "teachers"
  add_foreign_key "enrollments", "course_offerings"
  add_foreign_key "enrollments", "students"
  add_foreign_key "parent_contacts", "students"
end
