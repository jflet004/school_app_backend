class CreateStudents < ActiveRecord::Migration[7.1]
  def change
    create_table :students do |t|
      t.integer :student_type, null: false # enum: :adult, :child

      t.string  :first_name, null: false
      t.string  :last_name,  null: false
      t.date    :birthday

      t.string  :instrument_preference
      t.integer :gender, null: false, default: 3 # prefer_not_to_say default
      t.integer :experience_years, null: false, default: 0

      # child-only school fields (nullable but validated in model if child)
      t.string  :current_school_name
      t.boolean :current_school_offers_arts

      t.integer :ethnicity, null: false, default: 6 # "Other" default

      t.string  :email
      t.string  :phone_number
      t.string  :home_address
      t.string  :city
      t.string  :state
      t.string  :postal_code

      t.integer :household_size
      t.integer :household_income
      t.integer :heard_about

      t.timestamps
    end

    add_index :students, [:last_name, :first_name]
    add_index :students, :student_type
    add_index :students, :email
  end
end
