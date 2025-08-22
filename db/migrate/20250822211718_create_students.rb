class CreateStudents < ActiveRecord::Migration[7.1]
  def change
    create_table :students do |t|
      t.integer :student_type
      t.string :first_name
      t.string :last_name
      t.date :birthday
      t.string :instrument_preference
      t.integer :gender
      t.integer :experience_years
      t.string :current_school_name
      t.boolean :current_school_offers_arts
      t.integer :ethnicity
      t.string :email
      t.string :phone_number
      t.string :home_address
      t.string :city
      t.string :state
      t.string :postal_code
      t.integer :household_size
      t.integer :household_income
      t.integer :heard_about

      t.timestamps
    end
  end
end
