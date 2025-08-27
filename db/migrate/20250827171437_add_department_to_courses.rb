class AddDepartmentToCourses < ActiveRecord::Migration[7.1]
  def change
    add_column :courses, :department, :integer, null: true unless column_exists?(:courses, :department)
    add_index  :courses, :department unless index_exists?(:courses, :department)
  end
end
