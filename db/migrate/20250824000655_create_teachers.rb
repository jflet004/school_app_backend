class CreateTeachers < ActiveRecord::Migration[7.1]
  def change
    create_table :teachers do |t|
      t.string :first_name, null: false
      t.string :last_name,  null: false
      t.string :email, null: false
      t.string :phone_number
      t.date   :hire_date, null: false
      t.decimal :base_rate, precision: 8, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :teachers, :email, unique: true
  end
end
