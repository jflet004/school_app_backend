# db/migrate/XXXXXXXXXXXXXX_normalize_courses_and_offerings.rb
class NormalizeCoursesAndOfferings < ActiveRecord::Migration[7.1]
  # Minimal inline models for data moves (avoid app/model code during migration)
  class Course < ApplicationRecord
    self.table_name = "courses"
  end

  class CourseOffering < ApplicationRecord
    self.table_name = "course_offerings"
  end

  def up
    # 1) Rename existing courses -> course_offerings (if not already renamed)
    if table_exists?(:courses) && !column_exists?(:courses, :course_type) # heuristic: old "courses"
      rename_table :courses, :course_offerings
    end

    # 2) Create the canonical courses table (if it doesn't exist)
    unless table_exists?(:courses)
      create_table :courses do |t|
        t.string  :name, null: false
        t.integer :course_type, null: false, default: 0  # enum: 0=group, 1=individual
        t.integer :price_cents, null: false, default: 0  # price per class, in cents
        t.boolean :active, null: false, default: true
        t.timestamps
      end
      add_index :courses, :name, unique: true
    end

    # 3) Ensure course_offerings has a course_id
    unless column_exists?(:course_offerings, :course_id)
      add_reference :course_offerings, :course, foreign_key: true
    end

    # 4) Backfill course_id from old name column (if present)
    if column_exists?(:course_offerings, :name)
      say_with_time "Backfilling course_id from course_offerings.name" do
        # Build Course rows for each distinct name
        names = execute("SELECT DISTINCT name FROM course_offerings WHERE name IS NOT NULL AND name != ''").to_a.map { |r| r["name"] }
        names.each do |n|
          Course.find_or_create_by!(name: n) # default course_type=group, price_cents=0
        end

        # Attach offerings to matching Course
        CourseOffering.reset_column_information
        Course.reset_column_information

        # Use SQL update for speed
        execute <<-SQL.squish
          UPDATE course_offerings
          SET course_id = courses.id
          FROM courses
          WHERE course_offerings.name = courses.name
            AND course_offerings.course_id IS NULL
        SQL
      end

      # Drop the old denormalized name column on offerings
      remove_column :course_offerings, :name, :string
    end

    # 5) Enforce NOT NULL on course_id now that it's backfilled (if there is data)
    change_column_null :course_offerings, :course_id, false
    add_index :course_offerings, :course_id unless index_exists?(:course_offerings, :course_id)
  end

  def down
    # Reverse is best-effort and may lose normalization:
    # 1) Add name back to offerings
    add_column :course_offerings, :name, :string unless column_exists?(:course_offerings, :name)

    # 2) Copy name from courses to offerings
    execute <<-SQL.squish
      UPDATE course_offerings
      SET name = courses.name
      FROM courses
      WHERE course_offerings.course_id = courses.id
    SQL

    # 3) Remove course_id
    remove_reference :course_offerings, :course, foreign_key: true if column_exists?(:course_offerings, :course_id)

    # 4) Rename offerings back to courses (dangerous if courses already exists)
    rename_table :course_offerings, :courses if table_exists?(:course_offerings) && !table_exists?(:courses)
    # (We won't drop canonical courses in down)
  end
end
