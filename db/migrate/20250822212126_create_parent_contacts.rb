class CreateParentContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :parent_contacts do |t|
      t.references :student, null: false, foreign_key: true

      t.string :parent_first_name, null: false
      t.string :parent_last_name,  null: false
      t.string :email
      t.string :phone_number
      t.string :home_address
      t.string :city
      t.string :state
      t.string :postal_code

      t.timestamps
    end

    add_index :parent_contacts, [:student_id, :parent_last_name]
  end
end
